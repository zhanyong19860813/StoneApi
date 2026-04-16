/*
  UT_att_pro_DayResult_Standard.sql
  用途：测试 att_pro_DayResult_Standard 存储过程正确性
  执行前：请确认 att_lst_DayResult_Standard 表已创建，att_pro_DayResult_Standard 已部署
  使用说明：按顺序执行【一、二、三】，根据【四、判断点】验证结果
*/

USE [SJHRsalarySystemDb]
GO

SET NOCOUNT ON;

-- ============================================================
-- 【配置】请根据实际环境修改
-- ============================================================
DECLARE @TestEmp      NVARCHAR(10)  = 'A8425';     -- 被测员工工号（需有 2026-03 排班）
DECLARE @TestOp       NVARCHAR(50)  = 'A8425';     -- 操作人（需在 t_base_employee 中存在且有权限）
DECLARE @TestStart    DATE          = '2026-03-01';
DECLARE @TestEnd      DATE          = '2026-03-31';

-- ============================================================
-- 【〇、清理旧数据】避免多次执行导致重复插入、PunchCount 累加
-- ============================================================
PRINT '========== 〇、清理旧数据 ==========';
DELETE FROM dbo.att_lst_Cardrecord
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND CAST(SlotCardDate AS DATE) IN ('2026-03-01','2026-03-02','2026-03-03','2026-03-04');
DELETE FROM dbo.att_lst_Holiday
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND CAST(HD_StartDate AS DATE) = '2026-03-05';
DELETE FROM dbo.att_lst_OverTime
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND CAST(fDate AS DATE) = '2026-03-10';
PRINT '  - 已清理测试用刷卡/请假/加班记录（若有）';

-- ============================================================
-- 【一、准备测试数据】
-- ============================================================
PRINT '========== 一、准备测试数据 ==========';

-- 1.1 刷卡记录：正常打卡（03-01、03-02、03-03 各 2 次）
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @TestEmp, '2026-03-01', '2026-03-01 08:15:00', '1'),
  (NEWID(), @TestEmp, '2026-03-01', '2026-03-01 17:45:00', '1'),
  (NEWID(), @TestEmp, '2026-03-02', '2026-03-02 08:20:00', '1'),
  (NEWID(), @TestEmp, '2026-03-02', '2026-03-02 18:00:00', '1'),
  (NEWID(), @TestEmp, '2026-03-03', '2026-03-03 08:10:00', '1'),
  (NEWID(), @TestEmp, '2026-03-03', '2026-03-03 17:50:00', '1');
PRINT '  - 已插入 6 条刷卡记录（03-01~03 正常上下班）';

-- 1.2 03-04 无刷卡（用于验证「是否缺卡」）
-- 不插入任何 03-04 的刷卡记录

-- 1.3 请假记录：03-05 全天请假
INSERT INTO dbo.att_lst_Holiday (FID, EMP_ID, HD_StartDate, HD_StartTime, HD_EndDate, HD_EndTime, HD_Days, HD_Reason)
VALUES (NEWID(), @TestEmp, '2026-03-05 00:00:00', '2026-03-05 08:00:00', '2026-03-05 23:59:59', '2026-03-05 18:00:00', 1, N'测试请假');
PRINT '  - 已插入 1 条请假记录（03-05）';

-- 1.4 加班记录：03-10 加班
INSERT INTO dbo.att_lst_OverTime (FID, EMP_ID, fType, fDate, fStartTime, fEndTime, overtime, fReason)
VALUES (NEWID(), @TestEmp, N'工作日加班', '2026-03-10', '2026-03-10 18:00:00', '2026-03-10 20:00:00', 2.0, N'测试加班');
PRINT '  - 已插入 1 条加班记录（03-10）';

PRINT '';

-- ============================================================
-- 【二、执行存储过程】
-- ============================================================
PRINT '========== 二、执行存储过程 ==========';

EXEC dbo.att_pro_DayResult_Standard
  @emp_list      = @TestEmp,
  @DayResultType = '0',
  @attStartDate  = @TestStart,
  @attEndDate    = @TestEnd,
  @op            = @TestOp;

PRINT '  - 存储过程执行完成';
PRINT '';

-- ============================================================
-- 【三、结果概览】
-- ============================================================
PRINT '========== 三、结果概览 ==========';

SELECT
  AttDate,
  WeekDay,
  IsShouldAttend,
  ShouldStartTime,
  ShouldEndTime,
  PunchInTime,
  PunchOutTime,
  PunchCount,
  IsMissingPunch,
  HasApproval,
  ApprovalType,
  ApprovalStatus
FROM dbo.att_lst_DayResult_Standard
WHERE EMP_ID = @TestEmp
  AND AttDate BETWEEN @TestStart AND @TestEnd
ORDER BY AttDate;

PRINT '';

-- ============================================================
-- 【四、判断点】逐项验证，任一失败则测试不通过
-- ============================================================
PRINT '========== 四、判断点 ==========';

DECLARE @ErrCnt INT = 0;

-- 判断点 1：应有记录
DECLARE @RowCnt INT;
SELECT @RowCnt = COUNT(*) FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND AttDate BETWEEN @TestStart AND @TestEnd;
IF @RowCnt = 0
BEGIN
  PRINT '  [FAIL] 判断点1：无任何日结果记录，检查 @TestOp 是否在 t_base_employee 中存在且 att_Func_GetPower 有权限';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点1：共 ' + CAST(@RowCnt AS VARCHAR) + ' 条日结果记录';

-- 判断点 2：人员信息正确
IF EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND (EmpName IS NULL OR DeptName IS NULL OR DutyName IS NULL))
BEGIN
  PRINT '  [FAIL] 判断点2：员工姓名/部门/岗位 有为空';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点2：人员信息（姓名、部门、岗位）已正确填充';

-- 判断点 3：03-01~03-03 有排班且打卡正常
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND AttDate = '2026-03-01' AND IsShouldAttend = 1 AND PunchCount = 2 AND IsMissingPunch = 0)
BEGIN
  PRINT '  [FAIL] 判断点3：03-01 应有排班、2 次打卡、不缺卡';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点3：03-01 应出勤、打卡2次、不缺卡';

-- 判断点 4：03-04 应出勤但缺卡
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND AttDate = '2026-03-04' AND IsShouldAttend = 1 AND IsMissingPunch = 1)
BEGIN
  PRINT '  [FAIL] 判断点4：03-04 应出勤且无刷卡，应标记为缺卡';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点4：03-04 缺卡标记正确';

-- 判断点 5：03-05 有请假审批
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND AttDate = '2026-03-05' AND HasApproval = 1 AND ApprovalType = N'请假' AND ApprovalStatus = N'已审核')
BEGIN
  PRINT '  [FAIL] 判断点5：03-05 应有请假审批单';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点5：03-05 请假审批正确';

-- 判断点 6：03-10 有加班审批
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND AttDate = '2026-03-10' AND HasApproval = 1 AND ApprovalType LIKE N'%加班%' AND ApprovalStatus = N'已审核')
BEGIN
  PRINT '  [FAIL] 判断点6：03-10 应有加班审批单';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点6：03-10 加班审批正确';

-- 判断点 7：休息日（如 03-07、03-08）IsShouldAttend=0
IF EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND AttDate IN ('2026-03-07','2026-03-08') AND IsShouldAttend = 1)
BEGIN
  PRINT '  [FAIL] 判断点7：03-07/03-08 为休息班，应 IsShouldAttend=0';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点7：休息班 IsShouldAttend=0';

-- 判断点 8：打卡方式默认「人脸」
IF EXISTS (SELECT 1 FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = @TestEmp AND ISNULL(PunchMethod,'') <> N'人脸')
BEGIN
  PRINT '  [FAIL] 判断点8：打卡方式应默认「人脸」';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点8：打卡方式为「人脸」';

PRINT '';
IF @ErrCnt = 0
  PRINT '========== 全部判断点通过 ==========';
ELSE
  PRINT '========== 失败 ' + CAST(@ErrCnt AS VARCHAR) + ' 项，请排查 ==========';

GO

-- ============================================================
-- 【五、清理测试数据】（可选，确认无问题后再执行）
-- 注意：会删除该员工在上述日期的全部相关数据，若该员工有真实业务数据请勿执行
-- ============================================================
/*
DELETE FROM dbo.att_lst_Cardrecord WHERE EMP_ID = 'A8425' AND CAST(SlotCardDate AS DATE) IN ('2026-03-01','2026-03-02','2026-03-03');
DELETE FROM dbo.att_lst_Holiday  WHERE EMP_ID = 'A8425' AND CAST(HD_StartDate AS DATE) = '2026-03-05';
DELETE FROM dbo.att_lst_OverTime  WHERE EMP_ID = 'A8425' AND CAST(fDate AS DATE) = '2026-03-10';
DELETE FROM dbo.att_lst_DayResult_Standard WHERE EMP_ID = 'A8425' AND AttDate BETWEEN '2026-03-01' AND '2026-03-31';
PRINT '测试数据已清理';
*/
