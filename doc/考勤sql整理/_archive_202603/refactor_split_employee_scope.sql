/* =========================================================
  纯重构（不改业务逻辑）
  目标：
    1) 新增过程：dbo.att_pro_DayResult_GetEmployees
       - 输入：@emp_list, @DayResultType, @attMonth, @op_emp_id
       - 输出：人员清单（emp_id, dpm_id, ps_id）作为结果集
    2) 改造过程：dbo.att_pro_DayResult
       - 保留原来“操作人识别/月份计算”等逻辑
       - 将“权限过滤 + 插入 @tempemployee”改为：
           INSERT INTO @tempemployee EXEC dbo.att_pro_DayResult_GetEmployees ...

  说明：
    - 本脚本使用 OBJECT_DEFINITION 读取数据库中的现有过程文本，然后做字符串替换生成 ALTER PROC。
    - 若你的数据库中过程文本与 doc 版本不一致，可能出现“未命中片段”的错误（50001）。
      出现后把报错贴我，我会调整匹配片段。
========================================================= */

USE [SJHRsalarySystemDb];
GO

/* =========================================================
  1) 新增：dbo.att_pro_DayResult_GetEmployees
========================================================= */

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
      -- 排除已审核月结果人员
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
      -- 排除已审核月结果人员
      AND NOT EXISTS
      (
        SELECT 1
        FROM dbo.att_lst_MonthResult mr
        WHERE mr.Fmonth = @attMonth AND mr.approveStatus = 1 AND a.EMP_ID = mr.EMP_ID
      );
  END
END
GO


/* =========================================================
  2) 改造：dbo.att_pro_DayResult（替换“确定人员范围”中插入 @tempemployee 的实现）
========================================================= */

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
BEGIN
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;
END

/* 需要被替换的原始片段（来自 doc 版本，若不一致会未命中） */
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
BEGIN
  THROW 50001, '改造失败：未命中“确定人员范围”片段（过程版本不一致）。把该段原文贴我，我会调整 needle。', 1;
END

SET @sql = REPLACE(@sql, @needle, @replacement);

/* 转为 ALTER PROC 并执行 */
SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Refactor done: dbo.att_pro_DayResult_GetEmployees created, dbo.att_pro_DayResult updated.';
GO

