USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_GetEmployees]    Script Date: 2026/3/18 17:57:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
  过程名：dbo.att_pro_DayResult_GetEmployees

  用途：
    - 计算日结人员范围（含权限过滤、按工号/按部门两种模式）
    - 排除已审核月结人员

  入参：
    - @emp_list：工号串（逗号分隔）或部门 id
    - @DayResultType：'0' 按工号；其他按部门
    - @attMonth：日结月份（yyyymm）
    - @op_emp_id：操作人工号（用于权限过滤）

  输出：
    - 结果集：emp_id, dpm_id, ps_id
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_GetEmployees]
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


