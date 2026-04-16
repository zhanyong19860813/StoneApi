-- =========================================================
-- 修复 Step6：删除主过程中“第6段原始 UPDATE 块”，避免与子过程重复执行
--
-- 前置条件：
--   你已经执行了 Step6 的子过程 + 插入 EXEC：
--     EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;
--
-- 本脚本做什么：
--   在 dbo.att_pro_DayResult 中删除从 “6.如果班次内只打了一次卡” 注释块开始，
--   到 “PRINT '重新更新入职当天的上班卡：'” 之前的原始 UPDATE 段落。
--
-- 幂等：
--   如果找不到该段落（可能已删），则跳过。
-- =========================================================

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

-- 先定位第6段标题，再从标题之后找该段的第一个 UPDATE a（避免误删其它 UPDATE）
DECLARE @titlePos int = CHARINDEX(N'6.如果班次内只打了一次卡', @sql);
DECLARE @endAnchor int = 0;
DECLARE @start int = 0;

IF @titlePos > 0
BEGIN
  SET @start = CHARINDEX(N'UPDATE a', @sql, @titlePos);
  SET @endAnchor = CHARINDEX(N'PRINT ''重新更新入职当天的上班卡：''', @sql, @titlePos);
END

IF @titlePos = 0 OR @start = 0 OR @endAnchor = 0 OR @endAnchor <= @start
BEGIN
  PRINT 'Skip: step6 old block not found or already removed.';
  RETURN;
END

SET @sql = STUFF(@sql, @start, @endAnchor - @start, CHAR(9) + N'-- Step6原始UPDATE已删除：改由 dbo.att_pro_DayResult_RejudgeSingleCardPunches 负责' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9));

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: removed step6 old rejudge block.';
GO

