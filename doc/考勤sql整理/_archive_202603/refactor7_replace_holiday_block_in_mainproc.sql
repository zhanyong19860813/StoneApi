-- =========================================================
-- 第七段接入脚本（安全版）：将“7.更新请假记录”整段替换为 1 行 EXEC
--
-- 替换范围：
--   从注释块标题“7.更新请假记录”开始，
--   到 PRINT '结束更新请假记录：' 那一行结束为止
--
-- 替换内容：
--   EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
--
-- 特点：
--   - 幂等：如果已替换过则跳过
--   - 只替换第 7 节，避免误伤
-- =========================================================

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
BEGIN
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;
END

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords', @sql) > 0
BEGIN
  PRINT 'Skip: already replaced holiday block.';
  RETURN;
END

DECLARE @startText int = CHARINDEX(N'7.更新请假记录', @sql);
IF @startText = 0
BEGIN
  THROW 50001, '替换失败：未找到“7.更新请假记录”标记。', 1;
END

-- 起点回溯到最近的“行首块注释”（\n\t/*），确保不会留下孤立的 '/'
DECLARE @rev nvarchar(max) = REVERSE(LEFT(@sql, @startText));
DECLARE @revPos int = CHARINDEX(REVERSE(CHAR(10) + CHAR(9) + N'/*'), @rev);
DECLARE @start int;
IF @revPos > 0
  SET @start = @startText - @revPos + 2;  -- +2：定位到换行后的第一个字符（TAB）
ELSE
BEGIN
  -- 兜底：退回到最近的 "/*"
  DECLARE @revPos2 int = CHARINDEX(REVERSE(N'/*'), @rev);
  SET @start = CASE WHEN @revPos2 > 0 THEN @startText - @revPos2 + 1 ELSE @startText END;
END

DECLARE @endPrint int = CHARINDEX(N'PRINT ''结束更新请假记录：''', @sql, @startText);
IF @endPrint = 0
BEGIN
  THROW 50002, '替换失败：未找到 PRINT ''结束更新请假记录：'' 行。', 1;
END

DECLARE @endLine int = CHARINDEX(CHAR(10), @sql, @endPrint);
IF @endLine = 0 SET @endLine = LEN(@sql);

DECLARE @replacement nvarchar(max) =
  CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
  + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

SET @sql = STUFF(@sql, @start, @endLine - @start, @replacement);

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: replaced holiday block with EXEC dbo.att_pro_DayResult_UpdateHolidayRecords.';
GO

