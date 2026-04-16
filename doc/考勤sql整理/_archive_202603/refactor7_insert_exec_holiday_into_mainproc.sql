-- =========================================================
-- 第七段接入脚本（最安全版）：只在主过程插入 1 行 EXEC，不替换原第7段代码
--
-- 为什么用插入而不是替换：
--   你现在主过程已被替换脚本破坏（出现 "/" 语法错误）。应先从备份恢复到健康版本。
--   恢复后，这个脚本只做“插入 1 行”，不触碰注释边界，风险最低。
--
-- 插入内容：
--   EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
--
-- 插入位置：
--   放在第7段原代码块开始之前（即 “7.更新请假记录” 标记之前）
--
-- 幂等：
--   如果已经插入过则跳过
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
  PRINT 'Skip: already inserted EXEC dbo.att_pro_DayResult_UpdateHolidayRecords.';
  RETURN;
END

DECLARE @anchor int = CHARINDEX(N'7.更新请假记录', @sql);
IF @anchor = 0
BEGIN
  THROW 50001, '插入失败：未找到“7.更新请假记录”标记（请先确保主过程已恢复到健康版本）。', 1;
END

DECLARE @insert nvarchar(max) =
  CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
  + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10)
  + CHAR(13) + CHAR(10) + CHAR(9);

SET @sql = STUFF(@sql, @anchor, 0, @insert);

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Done: inserted EXEC dbo.att_pro_DayResult_UpdateHolidayRecords into dbo.att_pro_DayResult (no replacement).';
GO

