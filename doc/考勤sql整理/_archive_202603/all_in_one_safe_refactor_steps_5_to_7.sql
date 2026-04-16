/* =========================================================
  考勤日结纯重构（安全版）Step5~Step7 收尾脚本

  前置：
    - 已执行 Step1~3（all_in_one_safe_refactor_steps_1_to_7.sql）
    - 已执行 Step4（refactor_split_update_card_records.sql）

  本脚本做什么：
    Step5：执行 refactor_split_update_overtime_records.sql（创建子过程 + 改主过程）
    Step6：创建子过程 + 插入 EXEC + 删除原第6段 UPDATE（避免重复）
    Step7：创建子过程 + 插入 EXEC（不替换原第7段，避免注释边界问题）

  可重复执行（幂等保护）。
========================================================= */

USE [SJHRsalarySystemDb];
GO

/**********************************************************************
 Step5：更新加班记录下沉（内联自 refactor_split_update_overtime_records.sql）
**********************************************************************/

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateOvertimeRecords
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

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
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  --假日加班
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
    a.attdate BETWEEN @attStartDate AND @attEndDate;

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
  WHERE  
    a.attdate BETWEEN @attStartDate AND @attEndDate
    AND (a.ShiftID IN ('26342F6A-84A8-468F-9942-B7EF0D50CEE7','23B7F46A-63A7-4662-8F6F-D9B6F81902D5') OR (d.sk1 IS NOT NULL AND d.sk2 IS NOT NULL));

  --法定假日排班产生节日加班
  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7
  FROM 
    #t_att_lst_DayResult a 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate
    JOIN [dbo].[att_lst_overtimeRules] r ON a.dpm_id=r.de_id AND a.ps_id=r.ps_id AND r.jieri='统计出勤天'
  WHERE  
    a.attdate BETWEEN @attStartDate AND @attEndDate
    AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000' );

  PRINT '结束更新加班记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO

DECLARE @sql5 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql5 IS NULL THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords', @sql5) = 0
BEGIN
  DECLARE @startText5 int = CHARINDEX(N'5.更新加班记录，加班也要验证刷卡', @sql5);
  DECLARE @endPrint5 int = CASE WHEN @startText5 > 0 THEN CHARINDEX(N'PRINT ''结束更新加班记录：''', @sql5, @startText5) ELSE 0 END;
  IF @startText5 = 0 OR @endPrint5 = 0 THROW 50001, 'Step5失败：未定位到第5节起止标记。', 1;

  DECLARE @commentNeedle5 nvarchar(50) = N'/************************************************************************';
  DECLARE @commentNeedleLen5 int = LEN(@commentNeedle5);
  DECLARE @revSegment5 nvarchar(max) = REVERSE(LEFT(@sql5, @startText5));
  DECLARE @revPos5 int = CHARINDEX(REVERSE(@commentNeedle5), @revSegment5);
  DECLARE @start5 int = CASE WHEN @revPos5 > 0 THEN @startText5 - @revPos5 - @commentNeedleLen5 + 2 ELSE @startText5 END;

  DECLARE @endLine5 int = CHARINDEX(CHAR(10), @sql5, @endPrint5);
  IF @endLine5 = 0 SET @endLine5 = LEN(@sql5);

  DECLARE @rep5 nvarchar(max) =
    CHAR(9) + N'/* 更新加班记录（纯重构：下沉到子过程） */' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql5 = STUFF(@sql5, @start5, @endLine5 - @start5, @rep5);
  SET @sql5 = REPLACE(@sql5, N'CREATE PROC', N'ALTER PROC');
  EXEC sp_executesql @sql5;
END
GO


/**********************************************************************
 Step6：单次刷卡归属重判（子过程 + 插入 EXEC + 删除旧 UPDATE）
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_RejudgeSingleCardPunches
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE a 
  SET 
    a.ST1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))< ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ST1 ELSE NULL END,
    a.ET1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))>= ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ET1 ELSE NULL END,
    a.ST2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))< ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ST2 ELSE NULL END,
    a.ET2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))>= ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ET2 ELSE NULL END
  FROM #t_att_lst_DayResult a,
  (
    SELECT 
      EMP_ID,attdate,
      DATEADD(dd,DATEDIFF(dd,BCST1,attdate)+ISNULL(begin_time_tag1,0),BCST1) AS BC1,
      DATEADD(dd,DATEDIFF(dd,BCET1,attdate)+ISNULL(end_time_tag1,0),BCeT1) AS BC2,
      DATEADD(dd,DATEDIFF(dd,BCST2,attdate)+ISNULL(begin_time_tag2,0),BCST2) AS BC3,
      DATEADD(dd,DATEDIFF(dd,BCET2,attdate)+ISNULL(end_time_tag2,0),BCET2) AS BC4,
      st1,et1,st2,ET2
    FROM #t_att_lst_DayResult 
    WHERE ABS(DATEDIFF(mi,ST1,ET1))<=3 AND ST1 IS NOT NULL AND ET1 IS NOT NULL  
  ) b
  WHERE a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.ST1 IS NOT NULL AND a.ET1 IS NOT NULL AND a.BCST1 IS NOT NULL;
END
GO

DECLARE @sql6 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql6 IS NULL THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

-- 插入 EXEC（若不存在）
IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches', @sql6) = 0
BEGIN
  DECLARE @anchorPrint6 int = CHARINDEX(N'PRINT ''重新更新入职当天的上班卡：''', @sql6);
  IF @anchorPrint6 = 0 THROW 50001, 'Step6失败：未找到 PRINT 入职当天锚点。', 1;

  DECLARE @overtimeExec6 int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords', @sql6);
  DECLARE @cardExec6 int = CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateCardRecords', @sql6);
  DECLARE @anchorAfter6 int = CASE
    WHEN @overtimeExec6 > 0 AND @overtimeExec6 < @anchorPrint6 THEN @overtimeExec6
    WHEN @cardExec6 > 0 AND @cardExec6 < @anchorPrint6 THEN @cardExec6
    ELSE 0 END;
  IF @anchorAfter6 = 0 THROW 50002, 'Step6失败：未找到刷卡/加班 EXEC 锚点。', 1;

  DECLARE @stmtEnd6 int = CHARINDEX(N';', @sql6, @anchorAfter6);
  IF @stmtEnd6 = 0 OR @stmtEnd6 > @anchorPrint6
  BEGIN
    SET @stmtEnd6 = CHARINDEX(CHAR(10), @sql6, @anchorAfter6);
    IF @stmtEnd6 = 0 SET @stmtEnd6 = @anchorAfter6;
  END

  DECLARE @insert6 nvarchar(max) =
    CHAR(13) + CHAR(10)
    + CHAR(9) + N'-- 单次刷卡归属重判（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;' + CHAR(13) + CHAR(10);

  SET @sql6 = STUFF(@sql6, @stmtEnd6 + 1, 0, @insert6);
END

-- 删除旧第6段 UPDATE（若还存在）
IF CHARINDEX(N'6.如果班次内只打了一次卡', @sql6) > 0
BEGIN
  DECLARE @title6 int = CHARINDEX(N'6.如果班次内只打了一次卡', @sql6);
  DECLARE @startDel6 int = CHARINDEX(N'UPDATE a', @sql6, @title6);
  DECLARE @endDel6 int = CHARINDEX(N'PRINT ''重新更新入职当天的上班卡：''', @sql6, @title6);
  IF @startDel6 > 0 AND @endDel6 > @startDel6
    SET @sql6 = STUFF(@sql6, @startDel6, @endDel6 - @startDel6,
      CHAR(9) + N'-- Step6原始UPDATE已删除：改由 dbo.att_pro_DayResult_RejudgeSingleCardPunches 负责' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(9));
END

SET @sql6 = REPLACE(@sql6, N'CREATE PROC', N'ALTER PROC');
EXEC sp_executesql @sql6;
GO


/**********************************************************************
 Step7：请假更新（子过程 + 插入 EXEC；不替换原第7段）
**********************************************************************/
USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateHolidayRecords
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE	a 
  SET		
    a.attHolidayID=b.FID,
    a.attDay=1,
    a.attTime=8,
    a.attovertime30=0,
    a.attHoliday=1,
    attHolidayCategory=b.HC_ID
  FROM #t_att_lst_DayResult a
    INNER JOIN dbo.att_lst_Holiday b ON a.EMP_ID = b.EMP_ID
    INNER JOIN dbo.att_lst_HolidayCategory c ON b.HC_ID = c.HC_ID AND c.HC_Paidleave = 1
  WHERE a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate
    AND (b.HC_ID <> 'H10' OR DATEPART(WEEKDAY, a.attdate) <> 1);

  UPDATE a 
  SET 
    a.attHolidayID=b.FID,
    a.attDay=0,
    a.attTime=0,
    a.attovertime30=0,
    a.attHoliday=1,
    attHolidayCategory=b.HC_ID
  FROM #t_att_lst_DayResult a,[dbo].[att_lst_Holiday] b
  WHERE a.EMP_ID=b.EMP_ID
    AND (a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate)
    AND b.HC_ID IN (SELECT HC_ID FROM [dbo].[att_lst_HolidayCategory] WHERE HC_Paidleave=0);

  PRINT '结束更新请假记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO

DECLARE @sql7 nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.att_pro_DayResult'));
IF @sql7 IS NULL THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;

IF CHARINDEX(N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords', @sql7) = 0
BEGIN
  DECLARE @anchor7 int = CHARINDEX(N'7.更新请假记录', @sql7);
  IF @anchor7 = 0 THROW 50001, 'Step7失败：未找到“7.更新请假记录”标记。', 1;

  DECLARE @insert7 nvarchar(max) =
    CHAR(9) + N'-- 更新请假记录（纯重构：下沉到子过程）' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;' + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10) + CHAR(9);

  SET @sql7 = STUFF(@sql7, @anchor7, 0, @insert7);
  SET @sql7 = REPLACE(@sql7, N'CREATE PROC', N'ALTER PROC');
  EXEC sp_executesql @sql7;
END
GO

PRINT 'Safe refactor Step5~Step7 done.';
GO

