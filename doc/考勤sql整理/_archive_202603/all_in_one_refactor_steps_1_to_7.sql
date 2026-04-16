/* =========================================================
  考勤日结纯重构 All-in-One（第1~7步）

  使用方式：
    1) 先把数据库里的 dbo.att_pro_DayResult 恢复到“未改动的备份版本”
    2) 直接执行本脚本（可重复执行）

  包含内容（顺序执行）：
    Step1  人员范围下沉：dbo.att_pro_DayResult_GetEmployees + 改主过程
    Step2  排班UNPIVOT下沉：dbo.att_pro_DayResult_ExpandJobScheduling + 改主过程
    Step3  班次时间段下沉：dbo.att_pro_DayResult_UpdateShiftIntervals + 改主过程
    Step4  刷卡匹配下沉：dbo.att_pro_DayResult_UpdateCardRecords + 改主过程
    Step5  加班更新下沉：dbo.att_pro_DayResult_UpdateOvertimeRecords + 改主过程
    Step6  单次刷卡归属重判：dbo.att_pro_DayResult_RejudgeSingleCardPunches + 安全插入 EXEC 到主过程
    Step7  请假更新下沉：dbo.att_pro_DayResult_UpdateHolidayRecords + 安全插入 EXEC 到主过程（不替换原第7段）

  注意：
    - 本脚本不包含“第7段整段替换版”，统一用“插入一行 EXEC”最安全方式接入。
========================================================= */

/**********************************************************************
 Step 1: refactor_split_employee_scope.sql
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_GetEmployees
(
  @emp_list NVARCHAR(4000),
  @DayResultType NVARCHAR(10),
  @attMonth NVARCHAR(6),
  @op_emp_id NVARCHAR(20)
)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @PowerTable TABLE (EMP_ID VARCHAR(10) NULL);

  INSERT INTO @PowerTable
  SELECT DISTINCT EMP_ID
  FROM dbo.att_Func_GetPower(@op_emp_id);

  IF (ISNULL(@DayResultType,'0') = '0')
  BEGIN
    SELECT
      code AS emp_id,
      dpm_id,
      ps_id
    FROM dbo.v_t_base_employee a
    WHERE
      EXISTS (SELECT value FROM dbo.ufn_split_string(@emp_list, ',') emplist WHERE emplist.value = a.emp_id)
      AND EXISTS (SELECT 1 FROM @PowerTable tr WHERE tr.EMP_ID = a.emp_id)
      AND NOT EXISTS
      (
        SELECT 1
        FROM dbo.att_lst_MonthResult mr
        WHERE mr.Fmonth = @attMonth AND mr.approveStatus = 1 AND a.EMP_ID = mr.EMP_ID
      );
  END
  ELSE
  BEGIN
    SELECT
      code AS emp_id,
      dpm_id,
      ps_id
    FROM dbo.v_t_base_employee a
    WHERE
      EXISTS (SELECT id FROM dbo.ufn_get_dept_children(@emp_list) dept WHERE dept.id = a.dept_id)
      AND EXISTS (SELECT 1 FROM @PowerTable tb WHERE tb.EMP_ID = a.emp_id)
      AND NOT EXISTS
      (
        SELECT 1
        FROM dbo.att_lst_MonthResult mr
        WHERE mr.Fmonth = @attMonth AND mr.approveStatus = 1 AND a.EMP_ID = mr.EMP_ID
      );
  END
END
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

DECLARE @needle nvarchar(max) = N'

		DECLARE @tempemployee table( 
			emp_id		CHAR(10)		NULL,
			dpm_id		NVARCHAR(50)	NULL,
			ps_id		NVARCHAR(50)	NULL
		)

		PRINT ''开始时间：''+CONVERT(NVARCHAR(20),GETDATE(),120)

	  
		DECLARE @PowerTable TABLE
		(
			EMP_ID	VARCHAR(10)	NULL
		);

		INSERT INTO @PowerTable
		SELECT 
			DISTINCT EMP_ID 
		FROM 
			dbo.att_Func_GetPower(@op_emp_id);
	  
		PRINT ''2：'' + CONVERT(NVARCHAR(20),GETDATE(),120)
  
		IF(ISNULL(@DayResultType,''0'') = ''0'')
			BEGIN
				INSERT INTO @tempemployee
				(
					emp_id,
					dpm_id,
					ps_id
				)
				SELECT 
					code ,
					dpm_id,
					ps_id  
				FROM 
					dbo.v_t_base_employee a 
				WHERE 
					EXISTS (SELECT value FROM [dbo].[ufn_split_string](@emp_list,'','') emplist WHERE emplist.value = a.emp_id)
					AND EXISTS (SELECT EMP_ID FROM @PowerTable tr WHERE tr.EMP_ID = a.emp_id)
					--排除已审核月结果人员
					AND NOT EXISTS(
						SELECT 1 FROM dbo.att_lst_MonthResult mr 
						WHERE mr.Fmonth = @attMonth AND mr.approveStatus = 1 AND a.EMP_ID = mr.EMP_ID
					);
			END 
		ELSE
			BEGIN
				INSERT INTO @tempemployee
				(
					emp_id,
					dpm_id,
					ps_id
				)
				SELECT 
					code,
					dpm_id,
					ps_id   
				FROM 
					dbo.v_t_base_employee a 
				WHERE 
					EXISTS (SELECT id FROM dbo.ufn_get_dept_children(@emp_list) dept WHERE dept.id = a.dept_id)
					AND EXISTS (SELECT EMP_ID FROM @PowerTable tb WHERE tb.EMP_ID = a.emp_id)
					--排除已审核月结果人员
					AND NOT EXISTS(
						SELECT 1 FROM dbo.att_lst_MonthResult mr 
						WHERE mr.Fmonth = @attMonth AND mr.approveStatus = 1 AND a.EMP_ID = mr.EMP_ID
					);
			END
	  
		PRINT ''3：'' + CONVERT(NVARCHAR(20),GETDATE(),120)
';

DECLARE @replacement nvarchar(max) = N'

		DECLARE @tempemployee table( 
			emp_id		CHAR(10)		NULL,
			dpm_id		NVARCHAR(50)	NULL,
			ps_id		NVARCHAR(50)	NULL
		)

		PRINT ''开始时间：''+CONVERT(NVARCHAR(20),GETDATE(),120)

		/* 纯重构：人员范围计算下沉到子过程，不改原逻辑 */
		INSERT INTO @tempemployee (emp_id, dpm_id, ps_id)
		EXEC dbo.att_pro_DayResult_GetEmployees
			@emp_list = @emp_list,
			@DayResultType = @DayResultType,
			@attMonth = @attMonth,
			@op_emp_id = @op_emp_id;

		PRINT ''3：'' + CONVERT(NVARCHAR(20),GETDATE(),120)
';

IF CHARINDEX(@needle, @sql) = 0
  THROW 50001, 'Step1失败：未命中“确定人员范围”片段（过程版本不一致）。', 1;

SET @sql = REPLACE(@sql, @needle, @replacement);
SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;
GO


/**********************************************************************
 Step 2: refactor_split_expand_jobscheduling.sql
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_ExpandJobScheduling
(
  @attMonth NVARCHAR(6),
  @attDays INT,
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH UnpivotedData AS
  (
    SELECT
      up.EMP_ID,
      up.JS_Month,
      REPLACE(REPLACE(up.scoure,'Day',''),'_ID','') AS attDate,
      ShiftID
    FROM dbo.att_lst_JobScheduling
    UNPIVOT
    (
      ShiftID FOR scoure IN
      (
        Day1_ID,Day2_ID,Day3_ID,Day4_ID,Day5_ID,Day6_ID,Day7_ID,Day8_ID,Day9_ID,Day10_ID,
        Day11_ID,Day12_ID,Day13_ID,Day14_ID,Day15_ID,Day16_ID,Day17_ID,Day18_ID,Day19_ID,Day20_ID,
        Day21_ID,Day22_ID,Day23_ID,Day24_ID,Day25_ID,Day26_ID,Day27_ID,Day28_ID,Day29_ID,Day30_ID,Day31_ID
      )
    ) AS up
    WHERE
      JS_Month = @attMonth
      AND REPLACE(REPLACE(up.scoure,'Day',''),'_ID','') <= @attDays
  ),
  FilteredData AS
  (
    SELECT
      EMP_ID,
      CONVERT(DATETIME, RTRIM(JS_Month) + RIGHT('0' + attDate, 2)) AS attDate,
      ShiftID
    FROM UnpivotedData
    WHERE
      attDate BETWEEN DAY(@attStartDate) AND DAY(@attEndDate)
  )
  INSERT INTO #t_jobSchedExpanded
  (
    EMP_ID, attDate, ShiftID,
    attTime, attDay, attLate, attEarly, attAbsenteeism, regcard_sum
  )
  SELECT
    EMP_ID, attDate, ShiftID,
    0, 0, 0, 0, 0, 0
  FROM FilteredData;
END
GO

DECLARE @proc2 sysname = N'dbo.att_pro_DayResult';
DECLARE @sql2 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc2));
IF @sql2 IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

DECLARE @needleCreateTemp nvarchar(max) = N'
		CREATE TABLE #t_att_lst_DayResult 
		(
			FID					UNIQUEIDENTIFIER		PRIMARY KEY,
			EMP_ID				CHAR(10)				NULL,
			dpm_id				NVARCHAR(50)			NULL,
			ps_id				NVARCHAR(50)			NULL,
			attDate				DATE					NULL,
			isHoliday			BIT						NULL,
			ShiftID				UNIQUEIDENTIFIER		NULL,
			attStatus			NVARCHAR(50)			NULL,
			attTime				NUMERIC(18,2)			NULL,
			attDay				NUMERIC(18,1)			NULL,
			attHolidayID		UNIQUEIDENTIFIER		NULL,
			attLate				NUMERIC(18,0)			NULL,
			attEarly			NUMERIC(18,0)			NULL,
			attAbsenteeism		NUMERIC(18,0)			NULL,
			attHoliday			NUMERIC(18,0)			NULL,
			attHolidayCategory	NVARCHAR(200)			NULL,
			attovertime15		NUMERIC(18,1)			NULL,
			attovertime20		NUMERIC(18,1)			NULL,
			attovertime30		NUMERIC(18,1)			NULL,
			BCST1				DATETIME				NULL,
			begin_time_tag1		INT						NULL,
			BCET1				DATETIME				NULL,
			end_time_tag1		INT						NULL,
			ST1					DATETIME				NULL,
			ET1					DATETIME				NULL,
			BCST2				DATETIME				NULL,
			begin_time_tag2		INT						NULL,
			BCET2				DATETIME				NULL,
			end_time_tag2		INT						NULL,
			ST2					DATETIME				NULL,
			ET2					DATETIME				NULL,
			errorMessage		NVARCHAR(200)			NULL,
			approval			INT						NULL,
			approvaler			NVARCHAR(50)			NULL,
			approvalTime		DATETIME				NULL,
			ModifyTime			DATETIME				NULL,
			OperatorName		NVARCHAR(50)			NULL,
			OperationTime		DATETIME				NULL,
			regcard_sum			INT						NULL
		);
';

DECLARE @injectAfterCreateTemp nvarchar(max) = @needleCreateTemp + N'

		/* 纯重构：排班 UNPIVOT 展开下沉到子过程，不改原逻辑 */
		IF OBJECT_ID(''tempdb..#t_jobSchedExpanded'') IS NOT NULL
			DROP TABLE #t_jobSchedExpanded;

		CREATE TABLE #t_jobSchedExpanded
		(
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
			@attMonth = @attMonth,
			@attDays = @attDays,
			@attStartDate = @attStartDate,
			@attEndDate = @attEndDate;
';

IF CHARINDEX(@needleCreateTemp, @sql2) = 0
  THROW 50001, 'Step2失败：未命中 #t_att_lst_DayResult 建表片段。', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_ExpandJobScheduling', @sql2) > 0
BEGIN
  DECLARE @injStart int = CHARINDEX(N'/* 纯重构：排班 UNPIVOT 展开下沉到子过程，不改原逻辑 */', @sql2);
  DECLARE @execPos int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_ExpandJobScheduling', @sql2, @injStart);
  DECLARE @injEnd int = CHARINDEX(N';', @sql2, @execPos);
  IF @injStart = 0 OR @execPos = 0 OR @injEnd = 0
    THROW 50003, 'Step2失败：检测到已改造，但未定位到旧注入块位置。', 1;

  DECLARE @newBlock nvarchar(max) = REPLACE(@injectAfterCreateTemp, @needleCreateTemp, N'');
  SET @sql2 = STUFF(@sql2, @injStart, (@injEnd - @injStart + 1), @newBlock);
END
ELSE
BEGIN
  SET @sql2 = REPLACE(@sql2, @needleCreateTemp, @injectAfterCreateTemp);
END

DECLARE @unpivotBlockStart int = CHARINDEX(N'--排班表 列转行，插入插入日结果表', @sql2);
DECLARE @insertTempDayResult int = CASE WHEN @unpivotBlockStart > 0
  THEN CHARINDEX(N'INSERT INTO  #t_att_lst_DayResult', @sql2, @unpivotBlockStart)
  ELSE 0 END;

IF @unpivotBlockStart = 0 OR @insertTempDayResult = 0
  THROW 50002, 'Step2失败：未定位到排班 UNPIVOT 块或 INSERT #t_att_lst_DayResult。', 1;

SET @sql2 = STUFF(
  @sql2,
  @unpivotBlockStart,
  @insertTempDayResult - @unpivotBlockStart,
  N'		--排班表 列转行，插入插入日结果表（纯重构：数据来自 #t_jobSchedExpanded）' + CHAR(13) + CHAR(10) + CHAR(9)
);

SET @sql2 = REPLACE(@sql2, N'FilteredData x', N'#t_jobSchedExpanded x');
SET @sql2 = REPLACE(@sql2, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql2;
GO


/**********************************************************************
 Step 3: refactor_split_update_shift_intervals.sql
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateShiftIntervals
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE a
  SET
    a.attStatus=0,
    a.BCST1=b.begin_time,
    a.BCET1=b.end_time,
    a.begin_time_tag1=ISNULL(b.begin_time_tag,0),
    a.end_time_tag1=ISNULL(b.end_time_tag,0)
  FROM #t_att_lst_DayResult a,[dbo].att_lst_time_interval b
  WHERE a.ShiftID=b.pb_code_fid AND b.sec_num=1;

  UPDATE a
  SET
    a.attStatus=0,
    a.BCST2=b.begin_time,
    a.BCET2=b.end_time,
    a.begin_time_tag2=ISNULL(b.begin_time_tag,0),
    a.end_time_tag2=ISNULL(b.end_time_tag,0)
  FROM #t_att_lst_DayResult a,[dbo].att_lst_time_interval b
  WHERE a.ShiftID=b.pb_code_fid AND b.sec_num=2;
END
GO

DECLARE @sql3 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql3 IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateShiftIntervals', @sql3) = 0
BEGIN
  DECLARE @start3 int = CHARINDEX(N'--班次设定时间段1', @sql3);
  DECLARE @after3 int = CASE WHEN @start3 > 0 THEN CHARINDEX(N'PRINT ''更新出勤状态：''', @sql3, @start3) ELSE 0 END;
  IF @start3 = 0 OR @after3 = 0
    THROW 50001, 'Step3失败：未定位到“班次设定时间段1”或“PRINT 更新出勤状态”。', 1;

  DECLARE @rep3 nvarchar(max) = N'--班次设定时间段（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateShiftIntervals;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql3 = STUFF(@sql3, @start3, @after3 - @start3, @rep3);
END

SET @sql3 = REPLACE(@sql3, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql3;
GO


/**********************************************************************
 Step 4: refactor_split_update_card_records.sql
**********************************************************************/
/* =========================================================
  纯重构（不改业务逻辑）- 第四段：更新刷卡记录（匹配 ST1/ET1/ST2/ET2）
========================================================= */
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateCardRecords
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  PRINT '开始更新刷卡记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**1.不夸天刷卡情况 取上班下班卡*/
  UPDATE a 
  SET 
    a.ST1=b.sk1,
    a.ET1=b.sk2
  FROM 
    #t_att_lst_DayResult a ,
    (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )c
      WHERE 
        a.ShiftID=b.pb_code_fid AND b.sec_num=1 AND a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate 
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0 ------------------------------------------
        AND c.SlotCardTime BETWEEN b.valid_begin_time AND b.valid_end_time 
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;  

  PRINT ' 第一段刷卡时间影响行数为：'+CONVERT(NVARCHAR(20),@@ROWCOUNT);

  PRINT '开始更新第二段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  --------------------------------------------------------------------------------------
  ---第二段刷卡时间---------------------------------------------------------------------
  UPDATE a 
  SET 
    a.ST2=b.sk1,
    a.ET2=b.sk2
  FROM 
    #t_att_lst_DayResult a ,
    (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        dbo.att_lst_time_interval b,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )c
      WHERE 
        a.ShiftID=b.pb_code_fid 
        AND b.sec_num=2 -----------------第二段刷卡时间
        AND a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0 ----------------表示取卡范围是当天
        AND c.SlotCardTime BETWEEN b.valid_begin_time AND b.valid_end_time 
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第三段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**2.跨天 上班卡 是前一天 【-1，0】*/
  UPDATE a 
  SET 
    a.ST1=b.sk1 
  FROM 
    #t_att_lst_DayResult a ,
    ( 
      SELECT 
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MIN(c.sc) sk1
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN DATEADD(dd,-1,@attStartDate) AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0)!=0 AND CardReason IS NOT NULL)
        ) c
      WHERE 
        a.ShiftID=b.pb_code_fid 
        AND b.sec_num=1 
        AND a.EMP_ID=c.EMP_ID 
        AND c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate)-1,b.valid_begin_time) 
          AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
        AND b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0 ------------------------------------------上班卡是前一天
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第四段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**2.1 跨天 下班卡 是当天 【-1，0】*/
  UPDATE a 
  SET 
    a.ET1 = b.sk2 
  FROM 
    #t_att_lst_DayResult a ,
    ( 
      SELECT 
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN DATEADD(dd,-1,@attStartDate) AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )  c
      WHERE 
        a.ShiftID=b.pb_code_fid 
        AND b.sec_num=1 
        AND a.EMP_ID=c.EMP_ID	
        AND c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate)-1,b.valid_begin_time) 
          AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)	 
        AND b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0 --------------------------下班卡是当天
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
    WHERE 
      a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
      AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第五段段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**3.跨天 上班卡 是当天 【0，1】*/
  UPDATE a 
  SET 
    a.ST1=b.sk2 
  FROM 
    #t_att_lst_DayResult a ,
    ( 
      SELECT 
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MIN(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND DATEADD(dd,1,@attEndDate) AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )  c
      WHERE 
        a.ShiftID=b.pb_code_fid AND b.sec_num=1 AND a.EMP_ID=c.EMP_ID  
        AND DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime) 
          BETWEEN  DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate),b.valid_begin_time) 
            AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attDate)+1,b.valid_end_time)
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1 
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第六段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**3.跨天 下班卡 是明天 【0，1】*/
  UPDATE a 
  SET 
    a.ET1=b.sk2 
  FROM 
    #t_att_lst_DayResult a ,
    (  
      SELECT	
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MAX(c.sc) sk2
      FROM	
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND DATEADD(dd,1,@attEndDate) AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )  c
      WHERE 
        a.ShiftID=b.pb_code_fid AND b.sec_num=1 AND a.EMP_ID=c.EMP_ID  
        AND DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime) 
          BETWEEN  DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate),b.valid_begin_time) 
            AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate)+1,b.valid_end_time)
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1 
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第七段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**4.入职当天的上班卡，默认是班次设定的上班卡，因为通常是很难打到卡，容易出现第一天上班是旷工的情况*/ 
  UPDATE a 
  SET 
    a.ST1=DATEADD(dd,DATEDIFF(dd,a.BCST1,frist_join_date),a.BCST1) ,
    a.ST2=a.BCST2
  FROM 
    #t_att_lst_DayResult a,
    dbo.t_base_employee b ,
    dbo.att_lst_time_interval c
  WHERE 
    a.EMP_ID=b.code AND a.attdate=b.frist_join_date 
    AND a.ShiftID=c.pb_code_fid AND c.sec_num=1 AND c.begin_time_slot_card=1
    AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND (a.ST1 IS NULL OR a.ST1>DATEADD(dd,DATEDIFF(dd,a.BCST1,b.frist_join_date),a.BCST1));

  PRINT '开始更新第八段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**5.如果排班休息，并且当天有两次刷卡，也要显示刷记录卡*/
  UPDATE a 
  SET 
    a.ST1=b.sk1,
    a.ET1=b.sk2
  FROM 
    #t_att_lst_DayResult a ,
    (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE  
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND b.sk1 NOT IN (SELECT ISNULL(st1,0) FROM #t_att_lst_DayResult x WHERE a.EMP_ID=x.EMP_ID )
    AND b.sk2 NOT IN (SELECT ISNULL(ET1,0) FROM #t_att_lst_DayResult y WHERE a.EMP_ID=y.EMP_ID)
    AND b.sk1 <> b.sk2
    AND ABS(DATEDIFF(mi,sk1,sk2))>=60*5
    AND ISNULL(a.ShiftID,'00000000-0000-0000-0000-000000000000') IN ('00000000-0000-0000-0000-000000000000');

  PRINT '开始更新第九段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  --如果排班休息，并且当天有一次刷卡，也要显示刷记录卡
  UPDATE a 
  SET 
    a.ST1=b.sk1
  FROM 
    #t_att_lst_DayResult a ,
    (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE  
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND b.sk1 NOT IN (SELECT ISNULL(st1,0) FROM #t_att_lst_DayResult x WHERE a.EMP_ID=x.EMP_ID )
    AND b.sk2 NOT IN (SELECT ISNULL(ET1,0) FROM #t_att_lst_DayResult y WHERE a.EMP_ID=y.EMP_ID)
    AND (b.sk1=b.sk2 OR (b.sk1 <> b.sk2 AND ABS(DATEDIFF(mi,b.sk1,b.sk2))<=60*5))
    AND ISNULL(a.ShiftID,'00000000-0000-0000-0000-000000000000') IN ('00000000-0000-0000-0000-000000000000');

  PRINT '结束更新刷卡记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO

DECLARE @sql4 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql4 IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateCardRecords', @sql4) = 0
BEGIN
  DECLARE @start4 int = CHARINDEX(N'PRINT ''开始更新刷卡记录：''', @sql4);
  DECLARE @after4 int = CASE WHEN @start4 > 0 THEN CHARINDEX(N'PRINT ''结束更新刷卡记录：''', @sql4, @start4) ELSE 0 END;
  IF @start4 = 0 OR @after4 = 0
    THROW 50001, 'Step4失败：未定位到刷卡记录起止 PRINT。', 1;

  DECLARE @afterLineEnd4 int = CHARINDEX(CHAR(10), @sql4, @after4);
  IF @afterLineEnd4 = 0 SET @afterLineEnd4 = LEN(@sql4);

  DECLARE @rep4 nvarchar(max) =
    N'		--更新刷卡记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateCardRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql4 = STUFF(@sql4, @start4, @afterLineEnd4 - @start4, @rep4);
END

SET @sql4 = REPLACE(@sql4, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql4;
GO


/**********************************************************************
 Step 5: refactor_split_update_overtime_records.sql
**********************************************************************/
/* =========================================================
  纯重构（不改业务逻辑）- 第五段：更新加班记录（第 5 节）
========================================================= */
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateOvertimeRecords
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  --日常加班 
  UPDATE a 
  SET 
    a.attovertime15=1,
    a.attStatus=5,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '日常加班%'  
    LEFT JOIN (
      SELECT a.EMP_ID,a.attdate, MIN(c.sc) sk1, MAX(c.sc) sk2
      FROM #t_att_lst_DayResult a, 
      (
        SELECT EMP_ID,SlotCardDate,SlotCardTime,DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
        FROM dbo.att_lst_Cardrecord  
        WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate 
      )c
      WHERE a.EMP_ID=c.EMP_ID AND a.attdate=c.SlotCardDate AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;

  --假日加班
  UPDATE a 
  SET 
    a.attovertime20=1,
    a.attStatus=6,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '假日加班%'  
    LEFT JOIN (
      SELECT a.EMP_ID,a.attdate, MIN(c.sc) sk1, MAX(c.sc) sk2
      FROM #t_att_lst_DayResult a, 
      (
        SELECT EMP_ID,SlotCardDate,SlotCardTime,DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
        FROM dbo.att_lst_Cardrecord  
        WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate 
      )c
      WHERE a.EMP_ID=c.EMP_ID AND a.attdate=c.SlotCardDate AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;

  --节日加班 
  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '节日加班%' 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate 
    LEFT JOIN (
      SELECT a.EMP_ID,a.attdate, MIN(c.sc) sk1, MAX(c.sc) sk2
      FROM #t_att_lst_DayResult a, 
      (
        SELECT EMP_ID,SlotCardDate,SlotCardTime,DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
        FROM dbo.att_lst_Cardrecord  
        WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate 
      )c
      WHERE a.EMP_ID=c.EMP_ID AND a.attdate=c.SlotCardDate AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE a.attdate BETWEEN @attStartDate AND @attEndDate
    AND (a.ShiftID IN ('26342F6A-84A8-468F-9942-B7EF0D50CEE7','23B7F46A-63A7-4662-8F6F-D9B6F81902D5') OR (d.sk1 IS NOT NULL AND d.sk2 IS NOT NULL));

  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7
  FROM 
    #t_att_lst_DayResult a 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate
    JOIN [dbo].[att_lst_overtimeRules] r ON a.dpm_id=r.de_id AND a.ps_id=r.ps_id AND r.jieri='统计出勤天'
  WHERE a.attdate BETWEEN @attStartDate AND @attEndDate
    AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000' );

  PRINT '结束更新加班记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO

DECLARE @sql5 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql5 IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords', @sql5) = 0
BEGIN
  DECLARE @startText5 int = CHARINDEX(N'5.更新加班记录，加班也要验证刷卡', @sql5);
  DECLARE @endPrint5 int = CASE WHEN @startText5 > 0 THEN CHARINDEX(N'PRINT ''结束更新加班记录：''', @sql5, @startText5) ELSE 0 END;
  IF @startText5 = 0 OR @endPrint5 = 0
    THROW 50001, 'Step5失败：未定位到第5节起止标记。', 1;

  DECLARE @commentNeedle5 nvarchar(50) = N'/************************************************************************';
  DECLARE @commentNeedleLen5 int = LEN(@commentNeedle5);
  DECLARE @revSegment5 nvarchar(max) = REVERSE(LEFT(@sql5, @startText5));
  DECLARE @revPos5 int = CHARINDEX(REVERSE(@commentNeedle5), @revSegment5);
  DECLARE @start5 int = CASE WHEN @revPos5 > 0 THEN @startText5 - @revPos5 - @commentNeedleLen5 + 2 ELSE @startText5 END;

  DECLARE @endLine5 int = CHARINDEX(CHAR(10), @sql5, @endPrint5);
  IF @endLine5 = 0 SET @endLine5 = LEN(@sql5);

  DECLARE @rep5 nvarchar(max) =
    CHAR(9) + N'/* 更新加班记录（纯重构：下沉到子过程） */' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql5 = STUFF(@sql5, @start5, @endLine5 - @start5, @rep5);
END

SET @sql5 = REPLACE(@sql5, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql5;
GO


/**********************************************************************
 Step 6: refactor_split_rejudge_single_card.sql + refactor6_insert_exec_rejudge_into_mainproc.sql
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_RejudgeSingleCardPunches
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE a 
  SET 
    a.ST1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))< ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ST1 ELSE NULL END,
    a.ET1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))>= ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ET1 ELSE NULL END,
    a.ST2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))< ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ST2 ELSE NULL END,
    a.ET2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))>= ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ET2 ELSE NULL END
  FROM #t_att_lst_DayResult a,
  (
    SELECT 
      EMP_ID,attdate,
      DATEADD(dd,DATEDIFF(dd,BCST1,attdate)+ISNULL(begin_time_tag1,0),BCST1) AS BC1,
      DATEADD(dd,DATEDIFF(dd,BCET1,attdate)+ISNULL(end_time_tag1,0),BCeT1) AS BC2,
      DATEADD(dd,DATEDIFF(dd,BCST2,attdate)+ISNULL(begin_time_tag2,0),BCST2) AS BC3,
      DATEADD(dd,DATEDIFF(dd,BCET2,attdate)+ISNULL(end_time_tag2,0),BCET2) AS BC4,
      st1,et1,st2,ET2
    FROM #t_att_lst_DayResult 
    WHERE ABS(DATEDIFF(mi,ST1,ET1))<=3 AND ST1 IS NOT NULL AND ET1 IS NOT NULL  
  ) b
  WHERE a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.ST1 IS NOT NULL AND a.ET1 IS NOT NULL AND a.BCST1 IS NOT NULL;
END
GO

-- 安全插入 EXEC 到主过程
DECLARE @sql6 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql6 IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches', @sql6) = 0
BEGIN
  DECLARE @anchorPrint6 int = CHARINDEX(N'PRINT ''重新更新入职当天的上班卡：''', @sql6);
  IF @anchorPrint6 = 0
    THROW 50001, 'Step6失败：未找到 PRINT 入职当天锚点。', 1;

  DECLARE @overtimeExec6 int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords', @sql6);
  DECLARE @cardExec6 int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateCardRecords', @sql6);
  DECLARE @anchorAfter6 int = CASE
    WHEN @overtimeExec6 > 0 AND @overtimeExec6 < @anchorPrint6 THEN @overtimeExec6
    WHEN @cardExec6 > 0 AND @cardExec6 < @anchorPrint6 THEN @cardExec6
    ELSE 0 END;
  IF @anchorAfter6 = 0
    THROW 50002, 'Step6失败：未找到刷卡/加班 EXEC 锚点。', 1;

  DECLARE @stmtEnd6 int = CHARINDEX(N';', @sql6, @anchorAfter6);
  IF @stmtEnd6 = 0 OR @stmtEnd6 > @anchorPrint6
  BEGIN
    SET @stmtEnd6 = CHARINDEX(CHAR(10), @sql6, @anchorAfter6);
    IF @stmtEnd6 = 0 SET @stmtEnd6 = @anchorAfter6;
  END

  DECLARE @insert6 nvarchar(max) =
    CHAR(13) + CHAR(10)
    + CHAR(9) + N'-- 单次刷卡归属重判（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;' + CHAR(13) + CHAR(10);

  SET @sql6 = STUFF(@sql6, @stmtEnd6 + 1, 0, @insert6);
  SET @sql6 = REPLACE(@sql6, N'CREATE PROC', N'ALTER PROC');
  EXEC sp_executesql @sql6;
END
GO


/**********************************************************************
 Step 7: refactor_split_update_holiday_records.sql + refactor7_insert_exec_holiday_into_mainproc.sql
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateHolidayRecords
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE	a 
  SET		
    a.attHolidayID=b.FID,
    a.attDay=1,
    a.attTime=8,
    a.attovertime30=0,
    a.attHoliday=1,
    attHolidayCategory=b.HC_ID
  FROM #t_att_lst_DayResult a
    INNER JOIN dbo.att_lst_Holiday b ON a.EMP_ID = b.EMP_ID
    INNER JOIN dbo.att_lst_HolidayCategory c ON b.HC_ID = c.HC_ID AND c.HC_Paidleave = 1
  WHERE a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate
    AND (b.HC_ID <> 'H10' OR DATEPART(WEEKDAY, a.attdate) <> 1);

  UPDATE a 
  SET 
    a.attHolidayID=b.FID,
    a.attDay=0,
    a.attTime=0,
    a.attovertime30=0,
    a.attHoliday=1,
    attHolidayCategory=b.HC_ID
  FROM #t_att_lst_DayResult a,[dbo].[att_lst_Holiday] b
  WHERE a.EMP_ID=b.EMP_ID
    AND (a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate)
    AND b.HC_ID IN (SELECT HC_ID FROM [dbo].[att_lst_HolidayCategory] WHERE HC_Paidleave=0);

  PRINT '结束更新请假记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO

DECLARE @sql7 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql7 IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords', @sql7) = 0
BEGIN
  DECLARE @anchor7 int = CHARINDEX(N'7.更新请假记录', @sql7);
  IF @anchor7 = 0
    THROW 50001, 'Step7失败：未找到“7.更新请假记录”标记。', 1;

  DECLARE @insert7 nvarchar(max) =
    CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql7 = STUFF(@sql7, @anchor7, 0, @insert7);
  SET @sql7 = REPLACE(@sql7, N'CREATE PROC', N'ALTER PROC');
  EXEC sp_executesql @sql7;
END
GO

PRINT 'All-in-one refactor steps 1~7 finished.';
GO

