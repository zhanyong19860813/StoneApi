USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_UpdateCardRecords_v1]    Script Date: 2026/3/18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* =========================================================
  v1 版本快照：
    - 用于重构对刷卡过程的回归对比
    - 逻辑与 dbo.att_pro_DayResult_UpdateCardRecords 保持一致（仅过程名不同）
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_UpdateCardRecords_v1]
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  PRINT '开始更新刷卡记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**1.不夸天刷卡情况 取上班下班卡*/
  UPDATE a 
  SET 
    a.ST1=b.sk1,
    a.ET1=b.sk2
  FROM 
    #t_att_lst_DayResult a ,
    (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )c
      WHERE 
        a.ShiftID=b.pb_code_fid AND b.sec_num=1 AND a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate 
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0 ------------------------------------------
        AND c.SlotCardTime BETWEEN b.valid_begin_time AND b.valid_end_time 
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;  

  PRINT ' 第一段刷卡时间影响行数为：'+CONVERT(NVARCHAR(20),@@ROWCOUNT);

  PRINT '开始更新第二段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  --------------------------------------------------------------------------------------
  ---第二段刷卡时间---------------------------------------------------------------------
  UPDATE a 
  SET 
    a.ST2=b.sk1,
    a.ET2=b.sk2
  FROM 
    #t_att_lst_DayResult a ,
    (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        dbo.att_lst_time_interval b,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )c
      WHERE 
        a.ShiftID=b.pb_code_fid 
        AND b.sec_num=2 -----------------第二段刷卡时间
        AND a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0 ----------------表示取卡范围是当天
        AND c.SlotCardTime BETWEEN b.valid_begin_time AND b.valid_end_time 
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第三段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**2.跨天 上班卡 是前一天 【-1，0】*/
  UPDATE a 
  SET 
    a.ST1=b.sk1 
  FROM 
    #t_att_lst_DayResult a ,
    ( 
      SELECT 
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MIN(c.sc) sk1
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN DATEADD(dd,-1,@attStartDate) AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0)!=0 AND CardReason IS NOT NULL)
        ) c
      WHERE 
        a.ShiftID=b.pb_code_fid 
        AND b.sec_num=1 
        AND a.EMP_ID=c.EMP_ID 
        AND c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate)-1,b.valid_begin_time) 
          AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
        AND b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0 ------------------------------------------上班卡是前一天
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第四段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**2.1 跨天 下班卡 是当天 【-1，0】*/
  UPDATE a 
  SET 
    a.ET1 = b.sk2 
  FROM 
    #t_att_lst_DayResult a ,
    ( 
      SELECT 
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN DATEADD(dd,-1,@attStartDate) AND @attEndDate AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )  c
      WHERE 
        a.ShiftID=b.pb_code_fid 
        AND b.sec_num=1 
        AND a.EMP_ID=c.EMP_ID	
        AND c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate)-1,b.valid_begin_time) 
          AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)	 
        AND b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0 --------------------------下班卡是当天
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
    WHERE 
      a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
      AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第五段段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**3.跨天 上班卡 是当天 【0，1】*/
  UPDATE a 
  SET 
    a.ST1=b.sk2 
  FROM 
    #t_att_lst_DayResult a ,
    ( 
      SELECT 
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MIN(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND DATEADD(dd,1,@attEndDate) AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )  c
      WHERE 
        a.ShiftID=b.pb_code_fid AND b.sec_num=1 AND a.EMP_ID=c.EMP_ID  
        AND DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime) 
          BETWEEN  DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate),b.valid_begin_time) 
            AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attDate)+1,b.valid_end_time)
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1 
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第六段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**3.跨天 下班卡 是明天 【0，1】*/
  UPDATE a 
  SET 
    a.ET1=b.sk2 
  FROM 
    #t_att_lst_DayResult a ,
    (  
      SELECT	
        a.EMP_ID,
        a.attdate,
        b.begin_time,
        b.end_time,  
        MAX(c.sc) sk2
      FROM	
        #t_att_lst_DayResult a,
        [dbo].att_lst_time_interval b ,
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord 
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND DATEADD(dd,1,@attEndDate) AND CardReason IS NULL
            OR ( ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
        )  c
      WHERE 
        a.ShiftID=b.pb_code_fid AND b.sec_num=1 AND a.EMP_ID=c.EMP_ID  
        AND DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime) 
          BETWEEN  DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate),b.valid_begin_time) 
            AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate)+1,b.valid_end_time)
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1 
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第七段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**4.入职当天的上班卡，默认是班次设定的上班卡，因为通常是很难打到卡，容易出现第一天上班是旷工的情况*/ 
  UPDATE a 
  SET 
    a.ST1=DATEADD(dd,DATEDIFF(dd,a.BCST1,frist_join_date),a.BCST1) ,
    a.ST2=a.BCST2
  FROM 
    #t_att_lst_DayResult a,
    dbo.t_base_employee b ,
    dbo.att_lst_time_interval c
  WHERE 
    a.EMP_ID=b.code AND a.attdate=b.frist_join_date 
    AND a.ShiftID=c.pb_code_fid AND c.sec_num=1 AND c.begin_time_slot_card=1
    AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND (a.ST1 IS NULL OR a.ST1>DATEADD(dd,DATEDIFF(dd,a.BCST1,b.frist_join_date),a.BCST1));

  PRINT '开始更新第八段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);
			
  /**5.如果排班休息，并且当天有两次刷卡，也要显示刷记录卡*/
  UPDATE a 
  SET 
    a.ST1=b.sk1,
    a.ET1=b.sk2
  FROM 
    #t_att_lst_DayResult a ,
    (
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
          WHERE SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE  
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND b.sk1 NOT IN (SELECT ISNULL(st1,0) FROM #t_att_lst_DayResult x WHERE a.EMP_ID=x.EMP_ID )
    AND b.sk2 NOT IN (SELECT ISNULL(ET1,0) FROM #t_att_lst_DayResult y WHERE a.EMP_ID=y.EMP_ID)
    AND b.sk1 <> b.sk2
    AND ABS(DATEDIFF(mi,sk1,sk2))>=60*5   --两次刷卡时间需大于等于5小时 20191111 hp 修改
    AND ISNULL(a.ShiftID,'00000000-0000-0000-0000-000000000000') IN ('00000000-0000-0000-0000-000000000000');
 
  PRINT '开始更新第九段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);
 
  --如果排班休息，并且当天有一次刷卡，也要显示刷记录卡
  UPDATE a 
  SET 
    a.ST1=b.sk1
  FROM 
    #t_att_lst_DayResult a ,
    (
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
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND b.sk1 NOT IN (SELECT ISNULL(st1,0) FROM #t_att_lst_DayResult x WHERE a.EMP_ID=x.EMP_ID )
    AND b.sk2 NOT IN (SELECT ISNULL(ET1,0) FROM #t_att_lst_DayResult y WHERE a.EMP_ID=y.EMP_ID)
    AND (b.sk1=b.sk2 OR (b.sk1 <> b.sk2 AND ABS(DATEDIFF(mi,b.sk1,b.sk2))<=60*5))  --原：30分钟内的两道刷卡算一道 2024-10-16 zhanglinfu 改：五小时内都显示第一次打卡
    AND ISNULL(a.ShiftID,'00000000-0000-0000-0000-000000000000') IN ('00000000-0000-0000-0000-000000000000');

  PRINT '结束更新刷卡记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO

