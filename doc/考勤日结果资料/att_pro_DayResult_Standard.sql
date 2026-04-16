USE [SJHRsalarySystemDb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
  过程名：dbo.att_pro_DayResult_Standard
  用途：生成理论考勤日结果（标准化结构），输出到临时表 #t_DayResult_Standard
  参考：att_pro_DayResult、ReadMe.md、待补充信息

  入参：
    @emp_list     - 工号串（逗号分隔）或部门 id
    @DayResultType - '0' 按工号日结，'1' 按部门日结
    @attStartDate  - 日结开始日期
    @attEndDate    - 日结结束日期
    @op            - 操作人

  输出：
    - 临时表 #t_DayResult_Standard，结构与 att_lst_DayResult_Standard 一致
*/
IF OBJECT_ID('dbo.att_pro_DayResult_Standard','P') IS NOT NULL
  DROP PROC [dbo].[att_pro_DayResult_Standard];
GO

CREATE PROC [dbo].[att_pro_DayResult_Standard]
(
  @emp_list     NVARCHAR(4000),
  @DayResultType NVARCHAR(10),
  @attStartDate  DATETIME,
  @attEndDate    DATETIME,
  @op            NVARCHAR(200)
)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @op_emp_id   NVARCHAR(20),
    @op_name     NVARCHAR(30),
    @attMonth    NVARCHAR(6);

  SET @attMonth = CONVERT(NVARCHAR(6), @attStartDate, 112);

  IF MONTH(@attStartDate) <> MONTH(@attEndDate)
    SET @attEndDate = DATEADD(MONTH, 1, @attMonth + '01') - 1;

  SELECT
    @op_emp_id = code,
    @op_name   = CASE WHEN name = '张郁葱' THEN '系统管理员' ELSE name END
  FROM dbo.t_base_employee
  WHERE (code = @op OR name LIKE '%' + @op + '%') AND status = 0;

  /* ========== 1. 人员范围 ========== */
  DECLARE @tempemployee TABLE (emp_id CHAR(10) NULL, dpm_id NVARCHAR(50) NULL, ps_id NVARCHAR(50) NULL);

  INSERT INTO @tempemployee (emp_id, dpm_id, ps_id)
  EXEC dbo.att_pro_DayResult_GetEmployees
    @emp_list     = @emp_list,
    @DayResultType = @DayResultType,
    @attMonth     = @attMonth,
    @op_emp_id    = @op_emp_id;

  /* ========== 2. 创建临时表（与 att_lst_DayResult_Standard 结构一致）========== */
  IF OBJECT_ID('tempdb..#t_DayResult_Standard') IS NOT NULL
    DROP TABLE #t_DayResult_Standard;

  CREATE TABLE #t_DayResult_Standard (
    FID              UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    EMP_ID           NVARCHAR(50)     NULL,
    EmpName          NVARCHAR(50)     NULL,
    DeptID           UNIQUEIDENTIFIER NULL,
    DeptName         NVARCHAR(200)    NULL,
    DutyID           UNIQUEIDENTIFIER NULL,
    DutyName         NVARCHAR(100)    NULL,
    AttDate          DATE             NULL,
    WeekDay          NVARCHAR(10)     NULL,
    ShiftType        NVARCHAR(200)    NULL,
    IsShouldAttend   BIT              NULL,
    ShouldStartTime  DATETIME         NULL,
    ShouldEndTime    DATETIME         NULL,
    ShouldAttHours   NUMERIC(18,2)    NULL,
    IsFlexShift      BIT              NULL,
    PunchInTime      DATETIME         NULL,
    PunchOutTime     DATETIME         NULL,
    PunchCount       INT              NULL,
    PunchMethod      NVARCHAR(50)     NULL,
    IsMissingPunch   BIT              NULL,
    HasApproval      BIT              NULL,
    ApprovalType     NVARCHAR(100)    NULL,
    ApprovalStatus   NVARCHAR(50)     NULL,
    ModifyTime       DATETIME         NULL,
    OperatorName     NVARCHAR(50)     NULL
  );

  /* ========== 3. 生成基础记录：人员 x 日期（每人每天一行）========== */
  ;WITH DateRange AS (
    SELECT @attStartDate AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM DateRange WHERE d < @attEndDate
  )
  INSERT INTO #t_DayResult_Standard (
    FID, EMP_ID, EmpName, DeptID, DeptName, DutyID, DutyName,
    AttDate, WeekDay, ShiftType, IsShouldAttend, ShouldStartTime, ShouldEndTime, ShouldAttHours, IsFlexShift,
    PunchInTime, PunchOutTime, PunchCount, PunchMethod, IsMissingPunch, HasApproval, ApprovalType, ApprovalStatus,
    ModifyTime, OperatorName
  )
  SELECT
    NEWID(),
    e.emp_id,
    v.name,
    v.dept_id,
    v.long_name,
    v.dutyId,
    v.dutyName,
    dr.d,
    CASE DATEPART(WEEKDAY, dr.d)
      WHEN 1 THEN N'周日' WHEN 2 THEN N'周一' WHEN 3 THEN N'周二' WHEN 4 THEN N'周三'
      WHEN 5 THEN N'周四' WHEN 6 THEN N'周五' WHEN 7 THEN N'周六' ELSE '' END,
    NULL,   -- ShiftType 暂忽略
    NULL,   -- IsShouldAttend 后续 UPDATE
    NULL, NULL, NULL, NULL,  -- ShouldStartTime, ShouldEndTime, ShouldAttHours, IsFlexShift
    NULL, NULL, NULL, N'人脸', NULL,  -- PunchInTime, PunchOutTime, PunchCount, PunchMethod, IsMissingPunch
    NULL, NULL, NULL,  -- 审批
    GETDATE(),
    @op_name
  FROM @tempemployee e
  INNER JOIN dbo.v_t_base_employee v ON v.EMP_ID = e.emp_id
  CROSS JOIN DateRange dr
  WHERE dr.d BETWEEN @attStartDate AND @attEndDate
  OPTION (MAXRECURSION 366);

  /* 排除入职前、离职后 */
  DELETE a
  FROM #t_DayResult_Standard a
  INNER JOIN dbo.t_base_employee b ON a.EMP_ID = b.code
  WHERE (a.AttDate > b.leave_time OR a.AttDate < b.frist_join_date)
    AND a.AttDate BETWEEN @attStartDate AND @attEndDate;

  /* ========== 4. 排班展开（#t_jobSchedExpanded）========== */
  DECLARE @attDays INT = DAY(DATEADD(MONTH, 1, @attMonth + '01') - 1);

  IF OBJECT_ID('tempdb..#t_jobSchedExpanded') IS NOT NULL
    DROP TABLE #t_jobSchedExpanded;

  CREATE TABLE #t_jobSchedExpanded (
    EMP_ID CHAR(10) NOT NULL,
    attDate DATETIME NOT NULL,
    ShiftID UNIQUEIDENTIFIER NULL,
    attTime NUMERIC(18,2) NULL,
    attDay NUMERIC(18,1) NULL,
    attLate NUMERIC(18,0) NULL,
    attEarly NUMERIC(18,0) NULL,
    attAbsenteeism NUMERIC(18,0) NULL,
    regcard_sum INT NULL
  );

  EXEC dbo.att_pro_DayResult_ExpandJobScheduling
    @attMonth     = @attMonth,
    @attDays      = @attDays,
    @attStartDate = @attStartDate,
    @attEndDate   = @attEndDate;

  /* ========== 5. 更新班次信息：是否应出勤、应上班/下班时间、应出勤工时 ========== */
  UPDATE a
  SET
    a.IsShouldAttend   = 1,
    a.ShouldStartTime  = DATEADD(dd, DATEDIFF(dd, 0, a.AttDate) + ISNULL(b.begin_time_tag, 0), b.begin_time),
    a.ShouldEndTime    = DATEADD(dd, DATEDIFF(dd, 0, a.AttDate) + ISNULL(b.end_time_tag, 0), b.end_time),
    a.ShouldAttHours   = ISNULL(b.time_length, bc.total_hours)
  FROM #t_DayResult_Standard a
  INNER JOIN #t_jobSchedExpanded j ON a.EMP_ID = j.EMP_ID AND a.AttDate = j.attDate
  INNER JOIN dbo.att_lst_time_interval b ON j.ShiftID = b.pb_code_fid AND b.sec_num = 1
  LEFT JOIN dbo.att_lst_BC_set_code bc ON j.ShiftID = bc.FID
  WHERE j.ShiftID <> '00000000-0000-0000-0000-000000000000'
    AND j.ShiftID IS NOT NULL;

  /* 无排班/休息班：IsShouldAttend = 0 */
  UPDATE a SET a.IsShouldAttend = 0
  FROM #t_DayResult_Standard a
  WHERE a.IsShouldAttend IS NULL;

  /* ========== 6. 更新打卡信息：上班/下班打卡时间、打卡次数 ========== */
  /* 按「员工+日期」聚合：最早=上班卡，最晚=下班卡，条数=打卡次数 */
  ;WITH CardAgg AS (
    SELECT
      EMP_ID,
      CAST(SlotCardDate AS DATE) AS SlotCardDate,
      MIN(SlotCardTime) AS PunchIn,
      MAX(SlotCardTime) AS PunchOut,
      COUNT(*)           AS PunchCount
    FROM dbo.att_lst_Cardrecord
    WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate
    GROUP BY
      EMP_ID,
      CAST(SlotCardDate AS DATE)
  )
  UPDATE a
  SET
    a.PunchInTime  = c.PunchIn,
    a.PunchOutTime = c.PunchOut,
    a.PunchCount   = c.PunchCount
  FROM #t_DayResult_Standard a
  INNER JOIN CardAgg c
    ON a.EMP_ID = c.EMP_ID
   AND a.AttDate = c.SlotCardDate;

  UPDATE a SET a.PunchCount = 0
  FROM #t_DayResult_Standard a
  WHERE a.PunchCount IS NULL;

  /* ========== 7. 是否缺卡 ========== */
  /* 应出勤且（无打卡 或 仅单次打卡 或 缺上班/下班卡） */
  UPDATE a
  SET a.IsMissingPunch = 1
  FROM #t_DayResult_Standard a
  WHERE a.IsShouldAttend = 1
    AND (
      ISNULL(a.PunchCount, 0) = 0
      OR a.PunchInTime IS NULL
      OR a.PunchOutTime IS NULL
    );

  UPDATE a SET a.IsMissingPunch = 0 FROM #t_DayResult_Standard a WHERE a.IsMissingPunch IS NULL;

  /* ========== 8. 审批信息：请假、加班 ========== */
  UPDATE a
  SET a.HasApproval = 1, a.ApprovalType = N'请假', a.ApprovalStatus = N'已审核'
  FROM #t_DayResult_Standard a
  WHERE EXISTS (
    SELECT 1 FROM dbo.att_lst_Holiday h
    WHERE h.EMP_ID = a.EMP_ID AND a.AttDate BETWEEN CAST(h.HD_StartDate AS DATE) AND CAST(h.HD_EndDate AS DATE)
  );

  UPDATE a
  SET
    a.HasApproval    = 1,
    a.ApprovalType   = CASE WHEN a.ApprovalType IS NOT NULL THEN a.ApprovalType + N',加班' ELSE N'加班' END,
    a.ApprovalStatus = N'已审核'
  FROM #t_DayResult_Standard a
  WHERE EXISTS (
    SELECT 1 FROM dbo.att_lst_OverTime o
    WHERE o.EMP_ID = a.EMP_ID AND CAST(o.fDate AS DATE) = a.AttDate
  );

  UPDATE a
  SET a.HasApproval = 0, a.ApprovalType = NULL, a.ApprovalStatus = NULL
  FROM #t_DayResult_Standard a
  WHERE a.HasApproval IS NULL;

  /* ========== 9. 写入永久表 att_lst_DayResult_Standard ========== */
  DELETE d
  FROM dbo.att_lst_DayResult_Standard d
  WHERE EXISTS (SELECT 1 FROM @tempemployee t WHERE t.emp_id = d.EMP_ID)
    AND d.AttDate BETWEEN @attStartDate AND @attEndDate;

  INSERT INTO dbo.att_lst_DayResult_Standard (
    FID, EMP_ID, EmpName, DeptID, DeptName, DutyID, DutyName,
    AttDate, WeekDay, ShiftType, IsShouldAttend, ShouldStartTime, ShouldEndTime, ShouldAttHours, IsFlexShift,
    PunchInTime, PunchOutTime, PunchCount, PunchMethod, IsMissingPunch, HasApproval, ApprovalType, ApprovalStatus,
    ModifyTime, OperatorName
  )
  SELECT
    FID, EMP_ID, EmpName, DeptID, DeptName, DutyID, DutyName,
    AttDate, WeekDay, ShiftType, IsShouldAttend, ShouldStartTime, ShouldEndTime, ShouldAttHours, IsFlexShift,
    PunchInTime, PunchOutTime, PunchCount, PunchMethod, IsMissingPunch, HasApproval, ApprovalType, ApprovalStatus,
    ModifyTime, OperatorName
  FROM #t_DayResult_Standard;

  /* ========== 10. 输出结果 ========== */
  SELECT * FROM #t_DayResult_Standard ORDER BY EMP_ID, AttDate;
END
GO
