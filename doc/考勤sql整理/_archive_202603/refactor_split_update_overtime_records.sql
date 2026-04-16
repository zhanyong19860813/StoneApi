/* =========================================================
  纯重构（不改业务逻辑）- 第五段：更新加班记录（第 5 节）

  目标：
    1) 新增过程：dbo.att_pro_DayResult_UpdateOvertimeRecords
       - 输入：@attStartDate, @attEndDate
       - 行为：完整搬迁主过程中的“5.更新加班记录，加班也要验证刷卡”逻辑
         * 日常加班
         * 假日加班
         * 节日加班（含法定假日排班产生节日加班）
       - 输出：直接更新调用方已有的临时表 #t_att_lst_DayResult

    2) 改造过程：dbo.att_pro_DayResult
       - 将原第 5 节整段替换为 EXEC 调用

  说明：
    - 子过程依赖外层存在 #t_att_lst_DayResult（外层创建，嵌套 EXEC 可见）
    - 本脚本通过 OBJECT_DEFINITION + 定位起止标记 + STUFF 替换，避免整段文本严格匹配
========================================================= */

USE [SJHRsalarySystemDb];
GO

/* =========================================================
  1) 新增：dbo.att_pro_DayResult_UpdateOvertimeRecords
========================================================= */
CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateOvertimeRecords
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  /************************************************************************
    5.更新加班记录，加班也要验证刷卡
  *************************************************************************/

  --日常加班 
  UPDATE a 
  SET 
    a.attovertime15=1,
    a.attStatus=5,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '日常加班%'  
    LEFT JOIN (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE   
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE  
    1=1 AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  --假日加班 （这周六周日加班）
  UPDATE a 
  SET 
    a.attovertime20=1,
    a.attStatus=6,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '假日加班%'  
    LEFT JOIN (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE   
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE  
    1=1 AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  --节日加班 
  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '节日加班%' 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate 
    LEFT JOIN (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE   
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE  1=1 AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    --23B7F46A-63A7-4662-8F6F-D9B6F81902D5 试工班次 2023-04-28 试工班次可以为节日加班
    AND (a.ShiftID IN ('26342F6A-84A8-468F-9942-B7EF0D50CEE7','23B7F46A-63A7-4662-8F6F-D9B6F81902D5') OR (d.sk1 IS NOT NULL AND d.sk2 IS NOT NULL));

  ---法定假日排班产生节日加班（旷工了 就不给了，记得）
  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7
  FROM 
    #t_att_lst_DayResult a 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate
    JOIN [dbo].[att_lst_overtimeRules] r ON a.dpm_id=r.de_id AND a.ps_id=r.ps_id AND r.jieri='统计出勤天'
  WHERE  
    1=1 AND a.attdate BETWEEN @attStartDate AND @attEndDate
    AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000' );

  PRINT '结束更新加班记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
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

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords', @sql) = 0
BEGIN
  DECLARE @startText int = CHARINDEX(N'5.更新加班记录，加班也要验证刷卡', @sql);
  DECLARE @endPrint int = 0;
  DECLARE @endLine int = 0;

  IF @startText > 0
  BEGIN
    SET @endPrint = CHARINDEX(N'PRINT ''结束更新加班记录：''', @sql, @startText);
  END

  IF @startText = 0 OR @endPrint = 0
  BEGIN
    THROW 50001, '改造失败：未定位到第 5 节起止标记（过程版本不一致）。', 1;
  END

  /* 起点必须从注释块开头开始，避免破坏 /* ... */ 配对 */
  DECLARE @commentNeedle nvarchar(50) = N'/************************************************************************';
  DECLARE @commentNeedleLen int = LEN(@commentNeedle);
  DECLARE @revSegment nvarchar(max) = REVERSE(LEFT(@sql, @startText));
  DECLARE @revPos int = CHARINDEX(REVERSE(@commentNeedle), @revSegment);
  DECLARE @start int = 0;

  IF @revPos > 0
    SET @start = @startText - @revPos - @commentNeedleLen + 2;
  ELSE
    SET @start = @startText; --兜底：至少从文字处开始替换

  SET @endLine = CHARINDEX(CHAR(10), @sql, @endPrint);
  IF @endLine = 0 SET @endLine = LEN(@sql);

  DECLARE @replacement nvarchar(max) =
    CHAR(9) + N'/* 更新加班记录（纯重构：下沉到子过程） */' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql = STUFF(@sql, @start, @endLine - @start, @replacement);
END

SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql;

PRINT 'Refactor done: dbo.att_pro_DayResult_UpdateOvertimeRecords created, dbo.att_pro_DayResult updated.';
GO

