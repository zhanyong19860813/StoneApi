-- =========================================================
-- Step7 最终修复（按你当前过程文本定向修正）
--
-- 目标：
--   把主过程里“7.更新请假记录”整段（含注释块、两段 UPDATE、结束 PRINT）
--   统一替换为 1 行：
--     EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
--
-- 这样：
--   - 不会再出现 EXEC 插进注释里
--   - 也避免“原UPDATE + 子过程”重复执行
--
-- 幂等：
--   如果已经替换过（且第7段原 UPDATE 不存在），则跳过。
-- =========================================================

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

-- 如果第7段原 UPDATE 已不存在，则认为已修复
IF CHARINDEX(N'INNER JOIN dbo.att_lst_HolidayCategory c ON b.HC_ID = c.HC_ID AND c.HC_Paidleave = 1', @sql) = 0
BEGIN
  PRINT 'Skip: step7 holiday UPDATE block not found (already replaced).';
  RETURN;
END

DECLARE @titlePos int = CHARINDEX(N'7.更新请假记录', @sql);
IF @titlePos = 0
  THROW 50001, '修复失败：未找到“7.更新请假记录”标记。', 1;

-- 找到该标题之前最近的第7段注释块开头 "/************************************************************************"
DECLARE @rev nvarchar(max) = REVERSE(LEFT(@sql, @titlePos));
DECLARE @revStart int = CHARINDEX(REVERSE(N'/************************************************************************'), @rev);
DECLARE @start int = CASE WHEN @revStart > 0 THEN @titlePos - @revStart + 1 ELSE @titlePos END;

-- 找到第7段结束 PRINT 行
DECLARE @endPrint int = CHARINDEX(N'PRINT ''结束更新请假记录：''', @sql, @titlePos);
IF @endPrint = 0
  THROW 50002, '修复失败：未找到 PRINT ''结束更新请假记录：'' 行。', 1;

DECLARE @endLine int = CHARINDEX(CHAR(10), @sql, @endPrint);
IF @endLine = 0 SET @endLine = LEN(@sql);

DECLARE @replacement nvarchar(max) =
  CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
  + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10)
  + CHAR(13) + CHAR(10) + CHAR(9);

SET @sql = STUFF(@sql, @start, @endLine - @start, @replacement);

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: step7 holiday block replaced with EXEC dbo.att_pro_DayResult_UpdateHolidayRecords.';
GO

