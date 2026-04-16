-- =========================================================
-- 第六段接入脚本（安全版）：只在主过程插入 1 行 EXEC
--
-- 作用：
--   在 dbo.att_pro_DayResult 中，把下面这一行插入到正确位置：
--     EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;
--
-- 插入位置（优先）：
--   放在 “EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords ...” 之后
--   且在 “PRINT '重新更新入职当天的上班卡：' ...” 之前
--
-- 特点：
--   - 幂等：如果已经插过则跳过
--   - 不做大段替换，只做小范围插入，降低误伤风险
-- =========================================================

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
BEGIN
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;
END

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches', @sql) > 0
BEGIN
  PRINT 'Skip: already inserted EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches.';
  RETURN;
END

DECLARE @anchorPrint int = CHARINDEX(N'PRINT ''重新更新入职当天的上班卡：''', @sql);
IF @anchorPrint = 0
BEGIN
  THROW 50001, '插入失败：未找到 PRINT ''重新更新入职当天的上班卡：'' 锚点。', 1;
END

DECLARE @anchorAfter int = 0;
DECLARE @overtimeExec int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords', @sql);
DECLARE @cardExec int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateCardRecords', @sql);

IF @overtimeExec > 0 AND @overtimeExec < @anchorPrint
BEGIN
  SET @anchorAfter = @overtimeExec;
END
ELSE IF @cardExec > 0 AND @cardExec < @anchorPrint
BEGIN
  SET @anchorAfter = @cardExec;
END
ELSE
BEGIN
  THROW 50002, '插入失败：未找到 UpdateOvertimeRecords/UpdateCardRecords 的 EXEC 锚点（或锚点在 PRINT 之后）。', 1;
END

-- 从锚点开始，找到该 EXEC 语句结束分号；如果没有分号，则找到行尾
DECLARE @stmtEnd int = CHARINDEX(N';', @sql, @anchorAfter);
IF @stmtEnd = 0 OR @stmtEnd > @anchorPrint
BEGIN
  SET @stmtEnd = CHARINDEX(CHAR(10), @sql, @anchorAfter);
  IF @stmtEnd = 0 SET @stmtEnd = @anchorAfter;
END

-- 插入内容（带换行与缩进）
DECLARE @insert nvarchar(max) =
  CHAR(13) + CHAR(10)
  + CHAR(9) + N'-- 单次刷卡归属重判（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
  + CHAR(9) + N'EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;' + CHAR(13) + CHAR(10);

SET @sql = STUFF(@sql, @stmtEnd + 1, 0, @insert);

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: inserted EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches into dbo.att_pro_DayResult.';
GO

