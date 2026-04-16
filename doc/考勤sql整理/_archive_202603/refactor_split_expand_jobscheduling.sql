/* =========================================================
  纯重构（不改业务逻辑）- 第二段：排班 UNPIVOT 展开

  目标：
    1) 新增过程：dbo.att_pro_DayResult_ExpandJobScheduling
       - 输入：@attMonth, @attDays, @attStartDate, @attEndDate
       - 行为：将 att_lst_JobScheduling 按 Day1_ID~Day31_ID UNPIVOT 展开为每天记录
       - 输出：写入调用方预先创建的临时表 #t_jobSchedExpanded
         (EMP_ID char(10), attDate datetime, ShiftID uniqueidentifier)

    2) 改造过程：dbo.att_pro_DayResult
       - 在创建 #t_att_lst_DayResult 后，新增创建 #t_jobSchedExpanded 并 EXEC 子过程填充
       - 将原先 WITH UnpivotedData/FilteredData 逻辑替换为：从 #t_jobSchedExpanded 读取并 JOIN @tempemployee 插入 #t_att_lst_DayResult

  说明：
    - 之所以使用“调用方创建的临时表”，是因为：
      * 子过程内部创建的 #临时表在子过程结束时会被释放，外层无法继续使用
      * 外层创建的 #临时表对嵌套 EXEC 可见，且子过程可向其 INSERT
    - 本脚本使用 OBJECT_DEFINITION + 字符串替换生成 ALTER PROC。
      若你的数据库中过程文本与 doc 版本不一致，可能出现 50001/50002 未命中片段。
========================================================= */

USE [SJHRsalarySystemDb];
GO

/* =========================================================
  1) 新增：dbo.att_pro_DayResult_ExpandJobScheduling
========================================================= */

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

  /* 依赖调用方先创建 #t_jobSchedExpanded */
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
    EMP_ID,
    attDate,
    ShiftID,
    attTime,
    attDay,
    attLate,
    attEarly,
    attAbsenteeism,
    regcard_sum
  )
  SELECT
    EMP_ID,
    attDate,
    ShiftID,
    0 AS attTime,
    0 AS attDay,
    0 AS attLate,
    0 AS attEarly,
    0 AS attAbsenteeism,
    0 AS regcard_sum
  FROM FilteredData;
END
GO


/* =========================================================
  2) 改造：dbo.att_pro_DayResult
========================================================= */

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
BEGIN
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;
END

/* 2.1 在创建 #t_att_lst_DayResult 后插入：创建 #t_jobSchedExpanded 并 EXEC 填充 */
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

IF CHARINDEX(@needleCreateTemp, @sql) = 0
BEGIN
  THROW 50001, '改造失败：未命中 #t_att_lst_DayResult 建表片段（过程版本不一致）。', 1;
END

/* 如果已经注入过，则替换旧注入块；否则按原方式注入 */
IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_ExpandJobScheduling', @sql) > 0
BEGIN
	/* 以注入块的注释为起点，替换到 EXEC 语句结尾分号 */
	DECLARE @injStart int = CHARINDEX(N'/* 纯重构：排班 UNPIVOT 展开下沉到子过程，不改原逻辑 */', @sql);
	DECLARE @execPos int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_ExpandJobScheduling', @sql, @injStart);
	DECLARE @injEnd int = 0;

	IF @injStart = 0 OR @execPos = 0
	BEGIN
		THROW 50003, '改造失败：检测到已改造，但未定位到旧注入块位置。', 1;
	END

	/* 找到 EXEC 行后第一个分号作为注入块结束 */
	SET @injEnd = CHARINDEX(N';', @sql, @execPos);
	IF @injEnd = 0
	BEGIN
		THROW 50004, '改造失败：未定位到旧注入块结束分号。', 1;
	END

	/* 用新的“DROP+CREATE+EXEC”块替换旧块（不重复插入 #t_att_lst_DayResult 建表） */
	DECLARE @newBlock nvarchar(max) = N'

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
			@attEndDate = @attEndDate;';

	SET @sql = STUFF(@sql, @injStart, (@injEnd - @injStart + 1), @newBlock);
END
ELSE
BEGIN
	SET @sql = REPLACE(@sql, @needleCreateTemp, @injectAfterCreateTemp);
END

/* 2.2 替换：原 WITH UnpivotedData/FilteredData + INSERT 的数据源为 #t_jobSchedExpanded */
DECLARE @unpivotBlockStart int = CHARINDEX(N'--排班表 列转行，插入插入日结果表', @sql);
DECLARE @insertTempDayResult int = 0;

IF @unpivotBlockStart > 0
BEGIN
  SET @insertTempDayResult = CHARINDEX(N'INSERT INTO  #t_att_lst_DayResult', @sql, @unpivotBlockStart);
END

IF @unpivotBlockStart = 0 OR @insertTempDayResult = 0
BEGIN
  THROW 50002, '改造失败：未定位到排班 UNPIVOT 块或 INSERT #t_att_lst_DayResult（过程版本不一致）。', 1;
END

/* 删除“--排班表...”到“INSERT INTO  #t_att_lst_DayResult”之间的整段，改为一句注释 */
SET @sql =
  STUFF(
    @sql,
    @unpivotBlockStart,
    @insertTempDayResult - @unpivotBlockStart,
    N'		--排班表 列转行，插入插入日结果表（纯重构：数据来自 #t_jobSchedExpanded）' + CHAR(13) + CHAR(10) + CHAR(9)
  );

/* 将 INSERT 的 SELECT 数据源从 FilteredData x 改为 #t_jobSchedExpanded x（保持原字段逻辑不变） */
SET @sql = REPLACE(@sql, N'FilteredData x', N'#t_jobSchedExpanded x');

/* 转为 ALTER PROC 并执行 */
SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Refactor done: dbo.att_pro_DayResult_ExpandJobScheduling created, dbo.att_pro_DayResult updated.';
GO

