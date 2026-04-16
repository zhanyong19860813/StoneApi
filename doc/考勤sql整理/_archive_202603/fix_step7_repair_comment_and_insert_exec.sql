-- =========================================================
-- Step7 修复（安全版，只插入不替换）：
--   只把 EXEC dbo.att_pro_DayResult_UpdateHolidayRecords 插入到第7段块注释之前（注释外）
--   不修改任何块注释内容，避免出现缺少 "*/" 的问题。
--
-- 幂等：
--   如果已经存在正确的 EXEC（含参数形式），则跳过。
-- =========================================================

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate', @sql) = 0
BEGIN
  DECLARE @title int = CHARINDEX(N'7.更新请假记录', @sql);
  IF @title = 0
    THROW 50001, '修复失败：未找到“7.更新请假记录”标记。', 1;

  -- 找到该标题之前最近的注释块开头行（以 "/************************************************************************" 开头）
  DECLARE @rev nvarchar(max) = REVERSE(LEFT(@sql, @title));
  DECLARE @revStart int = CHARINDEX(REVERSE(CHAR(10) + CHAR(9) + N'/************************************************************************'), @rev);
  DECLARE @commentLineStart int = CASE WHEN @revStart > 0 THEN @title - @revStart + 2 ELSE @title END; -- +2 指向 TAB

  DECLARE @insert nvarchar(max) =
    CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql = STUFF(@sql, @commentLineStart, 0, @insert);
END
ELSE
BEGIN
  PRINT 'Skip: holiday EXEC already exists.';
END

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: step7 comment repaired and EXEC inserted outside comment.';
GO

