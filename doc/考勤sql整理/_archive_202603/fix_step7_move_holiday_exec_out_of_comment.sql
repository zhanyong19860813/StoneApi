-- =========================================================
-- 修复 Step7：把“更新请假记录”的 EXEC 放到块注释外
--
-- 你当前的过程文本里出现了这种结构（EXEC 被插进 /************ ... ************/ 里面）：
--   /************************************************************************
--       -- 更新请假记录...
--       EXEC dbo.att_pro_DayResult_UpdateHolidayRecords ...
--   7.更新请假记录
--   *************************************************************************/
--   UPDATE ...（原第7段仍在执行）
--
-- 本脚本做两件事：
--   A) 删除注释块里那两行（-- 更新请假记录... + EXEC ...），避免污染注释区
--   B) 在“/************************************************************************ 7.更新请假记录”注释块开头之前插入正确的两行（在注释外）
--
-- 幂等：
--   - 如果已存在正确的 EXEC（在注释外），则跳过插入
-- =========================================================

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

-- 1) 清理：删除注释块内误插入的两行（如果存在）
-- 用较宽松匹配：找到 "-- 更新请假记录（纯重构：下沉到子过程）" 到紧随其后的 "EXEC dbo.att_pro_DayResult_UpdateHolidayRecords" 行尾
DECLARE @bad1 int = CHARINDEX(N'-- 更新请假记录（纯重构：下沉到子过程）', @sql);
IF @bad1 > 0
BEGIN
  DECLARE @badExec int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords', @sql, @bad1);
  IF @badExec > 0
  BEGIN
    DECLARE @badEnd int = CHARINDEX(CHAR(10), @sql, @badExec);
    IF @badEnd = 0 SET @badEnd = @badExec;
    -- 同时吞掉 bad1 所在行（到 badEnd）
    SET @sql = STUFF(@sql, @bad1, @badEnd - @bad1 + 1, CHAR(13) + CHAR(10) + CHAR(9));
  END
END

-- 2) 插入：在第7段注释块开头之前插入 EXEC（注释外）
IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate', @sql) = 0
BEGIN
  DECLARE @anchorText int = CHARINDEX(N'7.更新请假记录', @sql);
  IF @anchorText = 0
    THROW 50001, '修复失败：未找到“7.更新请假记录”标记。', 1;

  -- 回溯到最近的行首 "/************************************************************************"（用 \n\t/******** 的反向定位，确保定位到注释块开头行）
  DECLARE @rev nvarchar(max) = REVERSE(LEFT(@sql, @anchorText));
  DECLARE @revPos int = CHARINDEX(REVERSE(CHAR(10) + CHAR(9) + N'/************************************************************************'), @rev);
  DECLARE @insertPos int;
  IF @revPos > 0
    SET @insertPos = @anchorText - @revPos + 2; -- 指向 TAB 位置
  ELSE
    SET @insertPos = @anchorText;

  DECLARE @insert nvarchar(max) =
    CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql = STUFF(@sql, @insertPos, 0, @insert);
END
ELSE
BEGIN
  PRINT 'Skip: correct holiday EXEC already present.';
END

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: step7 holiday EXEC moved outside comment.';
GO

