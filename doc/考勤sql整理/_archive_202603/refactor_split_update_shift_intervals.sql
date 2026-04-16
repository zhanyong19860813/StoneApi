/* =========================================================
  纯重构（不改业务逻辑）- 第三段：更新班次设定时间段（sec_num=1/2）

  目标：
    1) 新增过程：dbo.att_pro_DayResult_UpdateShiftIntervals
       - 行为：根据 dbo.att_lst_time_interval 更新 #t_att_lst_DayResult 的
         BCST1/BCET1/begin_time_tag1/end_time_tag1 与 BCST2/BCET2/begin_time_tag2/end_time_tag2
       - 输入输出：直接操作调用方已有的临时表 #t_att_lst_DayResult

    2) 改造过程：dbo.att_pro_DayResult
       - 将原“班次设定时间段1/2”两段 UPDATE 替换为 EXEC 调用

  说明：
    - 子过程依赖外层存在 #t_att_lst_DayResult（外层创建，嵌套 EXEC 可见）
    - 使用 OBJECT_DEFINITION + 定位片段 + STUFF 替换，尽量避免整段文本严格匹配
========================================================= */

USE [SJHRsalarySystemDb];
GO

/* =========================================================
  1) 新增：dbo.att_pro_DayResult_UpdateShiftIntervals
========================================================= */
CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateShiftIntervals
AS
BEGIN
  SET NOCOUNT ON;

  --班次设定时间段1
  UPDATE a
  SET
    a.attStatus=0,
    a.BCST1=b.begin_time,
    a.BCET1=b.end_time,
    a.begin_time_tag1=ISNULL(b.begin_time_tag,0),
    a.end_time_tag1=ISNULL(b.end_time_tag,0)
  FROM
    #t_att_lst_DayResult a,
    [dbo].att_lst_time_interval b
  WHERE
    a.ShiftID=b.pb_code_fid AND b.sec_num=1;

  --班次设定时间段2
  UPDATE a
  SET
    a.attStatus=0,
    a.BCST2=b.begin_time,
    a.BCET2=b.end_time,
    a.begin_time_tag2=ISNULL(b.begin_time_tag,0),
    a.end_time_tag2=ISNULL(b.end_time_tag,0)
  FROM
    #t_att_lst_DayResult a,
    [dbo].att_lst_time_interval b
  WHERE
    a.ShiftID=b.pb_code_fid AND b.sec_num=2;
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

/* 如果已经改过（存在 EXEC 调用），则不重复替换 */
IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateShiftIntervals', @sql) = 0
BEGIN
  DECLARE @start int = CHARINDEX(N'--班次设定时间段1', @sql);
  DECLARE @after int = 0;

  IF @start > 0
  BEGIN
    /* 以“PRINT 更新出勤状态”作为右边界（保持 PRINT 原样） */
    SET @after = CHARINDEX(N'PRINT ''更新出勤状态：''', @sql, @start);
  END

  IF @start = 0 OR @after = 0
  BEGIN
    THROW 50001, '改造失败：未定位到“班次设定时间段1”或“PRINT 更新出勤状态”位置（过程版本不一致）。', 1;
  END

  /* 用 EXEC 替换掉两段 UPDATE（到 PRINT 之前） */
  DECLARE @replacement nvarchar(max) = N'--班次设定时间段（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateShiftIntervals;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql = STUFF(@sql, @start, @after - @start, @replacement);
END

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Refactor done: dbo.att_pro_DayResult_UpdateShiftIntervals created, dbo.att_pro_DayResult updated.';
GO

