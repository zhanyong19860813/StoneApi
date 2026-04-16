USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_UpdateCardRecords]    Script Date: 2026/3/18 18:00:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
  1) 新增：dbo.att_pro_DayResult_UpdateCardRecords
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_UpdateCardRecords]
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  PRINT '开始更新刷卡记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  DECLARE
    @attStartDate_m1 DATETIME = DATEADD(dd,-1,@attStartDate),
    @attEndDate_p1   DATETIME = DATEADD(dd, 1,@attEndDate);

  /* =========================================================
    统一刷卡源数据（纯重构：仅复用取数 + sc 计算）

    注意：原过程里多处 WHERE 写法为：
      SlotCardDate BETWEEN ... AND CardReason IS NULL
      OR (ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL)
    这里 OR 分支本身不带日期限制。为保持行为一致，本临时表也保留该分支的全量取数。
  ========================================================= */
  DROP TABLE IF EXISTS #card_sc_base;
  CREATE TABLE #card_sc_base
  (
    EMP_ID CHAR(50) NULL,
    SlotCardDate DATETIME NULL,
    SlotCardTime DATETIME NULL,
    sc DATETIME NULL,
    CardReason VARCHAR(200) NULL,
    AppState CHAR(50) NULL
  );

  INSERT INTO #card_sc_base
  (
    EMP_ID,
    SlotCardDate,
    SlotCardTime,
    sc,
    CardReason,
    AppState
  )
  SELECT
    EMP_ID,
    SlotCardDate,
    SlotCardTime,
    DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc,
    CardReason,
    AppState
  FROM dbo.att_lst_Cardrecord
  WHERE
    (SlotCardDate BETWEEN @attStartDate_m1 AND @attEndDate_p1)
    OR (ISNULL(AppState,0) <> 0 AND CardReason IS NOT NULL);

  CREATE INDEX IX_card_sc_base_emp_date ON #card_sc_base (EMP_ID, SlotCardDate)
  INCLUDE (SlotCardTime, sc, CardReason, AppState);

  /* =========================================================
    复用聚合结果（纯重构）：
      - sec_num=1/2/3 且 0/0：计算 sk1/sk2 -> 更新 ST1/ET1、ST2/ET2、ST3/ET3
    注：valid_* 存为 1900-01-01 HH:mm，需投影到 attdate 再与 sc 比较
  ========================================================= */
  DROP TABLE IF EXISTS #mm_sec1_00;
  SELECT
    a.EMP_ID,
    a.attdate,
    MIN(c.sc) AS sk1,
    MAX(c.sc) AS sk2
  INTO #mm_sec1_00
  FROM
    #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b
      ON a.ShiftID=b.pb_code_fid AND b.sec_num=1
    JOIN #card_sc_base c
      ON RTRIM(a.EMP_ID)=RTRIM(c.EMP_ID) AND CAST(a.attdate AS DATE)=CAST(c.SlotCardDate AS DATE)
  WHERE
    b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0
    AND c.sc BETWEEN DATEADD(dd, DATEDIFF(dd, b.valid_begin_time, a.attdate), b.valid_begin_time)
                 AND DATEADD(dd, DATEDIFF(dd, b.valid_end_time,   a.attdate), b.valid_end_time)
    AND (
      (c.SlotCardDate BETWEEN @attStartDate AND @attEndDate AND c.CardReason IS NULL)
      OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL)
    )
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY
    a.EMP_ID,a.attdate;

  DROP TABLE IF EXISTS #mm_sec2_00;
  SELECT
    a.EMP_ID,
    a.attdate,
    MIN(c.sc) AS sk1,
    MAX(c.sc) AS sk2
  INTO #mm_sec2_00
  FROM
    #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b
      ON a.ShiftID=b.pb_code_fid AND b.sec_num=2
    JOIN #card_sc_base c
      ON RTRIM(a.EMP_ID)=RTRIM(c.EMP_ID) AND CAST(a.attdate AS DATE)=CAST(c.SlotCardDate AS DATE)
  WHERE
    b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0
    AND c.sc BETWEEN DATEADD(dd, DATEDIFF(dd, b.valid_begin_time, a.attdate), b.valid_begin_time)
                 AND DATEADD(dd, DATEDIFF(dd, b.valid_end_time,   a.attdate), b.valid_end_time)
    AND (
      (c.SlotCardDate BETWEEN @attStartDate AND @attEndDate AND c.CardReason IS NULL)
      OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL)
    )
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY
    a.EMP_ID,a.attdate;

  DROP TABLE IF EXISTS #mm_sec3_00;
  SELECT
    a.EMP_ID,
    a.attdate,
    MIN(c.sc) AS sk1,
    MAX(c.sc) AS sk2
  INTO #mm_sec3_00
  FROM
    #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b
      ON a.ShiftID=b.pb_code_fid AND b.sec_num=3
    JOIN #card_sc_base c
      ON RTRIM(a.EMP_ID)=RTRIM(c.EMP_ID) AND CAST(a.attdate AS DATE)=CAST(c.SlotCardDate AS DATE)
  WHERE
    b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0
    AND c.sc BETWEEN DATEADD(dd, DATEDIFF(dd, b.valid_begin_time, a.attdate), b.valid_begin_time)
                 AND DATEADD(dd, DATEDIFF(dd, b.valid_end_time,   a.attdate), b.valid_end_time)
    AND (
      (c.SlotCardDate BETWEEN @attStartDate AND @attEndDate AND c.CardReason IS NULL)
      OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL)
    )
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY
    a.EMP_ID,a.attdate;

  /**1.不夸天刷卡情况 取上班下班卡*/
  UPDATE a
  SET
    a.ST1=b.sk1,
    a.ET1=b.sk2
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_sec1_00 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT ' 第一段刷卡时间影响行数为：'+CONVERT(NVARCHAR(20),@@ROWCOUNT);

  PRINT '开始更新第二段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  --------------------------------------------------------------------------------------
  ---第二段刷卡时间---------------------------------------------------------------------
  UPDATE a
  SET
    a.ST2=b.sk1,
    a.ET2=b.sk2
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_sec2_00 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT ' 第二段刷卡时间影响行数为：'+CONVERT(NVARCHAR(20),@@ROWCOUNT);

  /** 第三段 [0,0] 刷卡 */
  UPDATE a
  SET
    a.ST3=b.sk1,
    a.ET3=b.sk2
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_sec3_00 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT ' 第三段刷卡时间影响行数为：'+CONVERT(NVARCHAR(20),@@ROWCOUNT);

  PRINT '开始更新跨天刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /* =========================================================
    跨天聚合结果（sec_num=1/2/3 各自支持 [-1,0]、[0,1]）
  ========================================================= */
  DROP TABLE IF EXISTS #mm_m10; -- sec_num=1 [-1,0]
  SELECT
    a.EMP_ID,
    a.attdate,
    MIN(CASE WHEN c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate)-1,b.valid_begin_time)
                   AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
             THEN c.sc END) AS sk1,
    MAX(CASE WHEN c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate)-1,b.valid_begin_time)
                   AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
             THEN c.sc END) AS sk2
  INTO #mm_m10
  FROM
    #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b
      ON a.ShiftID=b.pb_code_fid AND b.sec_num=1
    JOIN #card_sc_base c
      ON a.EMP_ID=c.EMP_ID
  WHERE
    b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0
    AND (
      (c.SlotCardDate BETWEEN @attStartDate_m1 AND @attEndDate AND c.CardReason IS NULL)
      OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL)
    )
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY
    a.EMP_ID,a.attdate;

  DROP TABLE IF EXISTS #mm_p01; -- [0,1]
  SELECT
    a.EMP_ID,
    a.attdate,
    MIN(CASE WHEN DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime)
                  BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate),b.valid_begin_time)
                      AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attDate)+1,b.valid_end_time)
             THEN c.sc END) AS sk_st,
    MAX(CASE WHEN DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime)
                  BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate),b.valid_begin_time)
                      AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate)+1,b.valid_end_time)
             THEN c.sc END) AS sk_et
  INTO #mm_p01
  FROM
    #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b
      ON a.ShiftID=b.pb_code_fid AND b.sec_num=1
    JOIN #card_sc_base c
      ON a.EMP_ID=c.EMP_ID
  WHERE
    b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1
    AND (
      (c.SlotCardDate BETWEEN @attStartDate AND @attEndDate_p1 AND c.CardReason IS NULL)
      OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL)
    )
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY
    a.EMP_ID,a.attdate;

  /**2.跨天 上班卡 是前一天 【-1，0】*/
  UPDATE a
  SET
    a.ST1=b.sk1
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_m10 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第四段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**2.1 跨天 下班卡 是当天 【-1，0】*/
  UPDATE a
  SET
    a.ET1=b.sk2
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_m10 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第五段段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**3.跨天 上班卡 是当天 【0，1】*/
  UPDATE a
  SET
    a.ST1=b.sk_st
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_p01 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新第六段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**3.跨天 下班卡 是明天 【0，1】*/
  UPDATE a
  SET
    a.ET1=b.sk_et
  FROM
    #t_att_lst_DayResult a
    JOIN #mm_p01 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE
    a.attdate BETWEEN @attStartDate AND @attEndDate;

  /* sec_num=2 跨天 [-1,0] */
  DROP TABLE IF EXISTS #mm_sec2_m10;
  SELECT
    a.EMP_ID, a.attdate,
    MIN(CASE WHEN c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate)-1,b.valid_begin_time)
                   AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
             THEN c.sc END) AS sk1,
    MAX(CASE WHEN c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate)-1,b.valid_begin_time)
                   AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
             THEN c.sc END) AS sk2
  INTO #mm_sec2_m10
  FROM #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b ON a.ShiftID=b.pb_code_fid AND b.sec_num=2
    JOIN #card_sc_base c ON a.EMP_ID=c.EMP_ID
  WHERE b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0
    AND ((c.SlotCardDate BETWEEN @attStartDate_m1 AND @attEndDate AND c.CardReason IS NULL) OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL))
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY a.EMP_ID,a.attdate;

  /* sec_num=2 跨天 [0,1] */
  DROP TABLE IF EXISTS #mm_sec2_p01;
  SELECT
    a.EMP_ID, a.attdate,
    MIN(CASE WHEN DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime)
                  BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate),b.valid_begin_time)
                      AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attDate)+1,b.valid_end_time)
             THEN c.sc END) AS sk_st,
    MAX(CASE WHEN DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime)
                  BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate),b.valid_begin_time)
                      AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate)+1,b.valid_end_time)
             THEN c.sc END) AS sk_et
  INTO #mm_sec2_p01
  FROM #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b ON a.ShiftID=b.pb_code_fid AND b.sec_num=2
    JOIN #card_sc_base c ON a.EMP_ID=c.EMP_ID
  WHERE b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1
    AND ((c.SlotCardDate BETWEEN @attStartDate AND @attEndDate_p1 AND c.CardReason IS NULL) OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL))
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY a.EMP_ID,a.attdate;

  UPDATE a SET a.ST2=b.sk1 FROM #t_att_lst_DayResult a JOIN #mm_sec2_m10 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;
  UPDATE a SET a.ET2=b.sk2 FROM #t_att_lst_DayResult a JOIN #mm_sec2_m10 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;
  UPDATE a SET a.ST2=b.sk_st FROM #t_att_lst_DayResult a JOIN #mm_sec2_p01 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;
  UPDATE a SET a.ET2=b.sk_et FROM #t_att_lst_DayResult a JOIN #mm_sec2_p01 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;

  /* sec_num=3 跨天 [-1,0] */
  DROP TABLE IF EXISTS #mm_sec3_m10;
  SELECT
    a.EMP_ID, a.attdate,
    MIN(CASE WHEN c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate)-1,b.valid_begin_time)
                   AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
             THEN c.sc END) AS sk1,
    MAX(CASE WHEN c.sc BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate)-1,b.valid_begin_time)
                   AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate),b.valid_end_time)
             THEN c.sc END) AS sk2
  INTO #mm_sec3_m10
  FROM #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b ON a.ShiftID=b.pb_code_fid AND b.sec_num=3
    JOIN #card_sc_base c ON a.EMP_ID=c.EMP_ID
  WHERE b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0
    AND ((c.SlotCardDate BETWEEN @attStartDate_m1 AND @attEndDate AND c.CardReason IS NULL) OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL))
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY a.EMP_ID,a.attdate;

  /* sec_num=3 跨天 [0,1] */
  DROP TABLE IF EXISTS #mm_sec3_p01;
  SELECT
    a.EMP_ID, a.attdate,
    MIN(CASE WHEN DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime)
                  BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attDate),b.valid_begin_time)
                      AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attDate)+1,b.valid_end_time)
             THEN c.sc END) AS sk_st,
    MAX(CASE WHEN DATEADD(dd,DATEDIFF(dd,c.SlotCardTime,c.SlotCardDate),c.SlotCardTime)
                  BETWEEN DATEADD(dd,DATEDIFF(dd,b.valid_begin_time,a.attdate),b.valid_begin_time)
                      AND DATEADD(dd,DATEDIFF(dd,b.valid_end_time,a.attdate)+1,b.valid_end_time)
             THEN c.sc END) AS sk_et
  INTO #mm_sec3_p01
  FROM #t_att_lst_DayResult a
    JOIN dbo.att_lst_time_interval b ON a.ShiftID=b.pb_code_fid AND b.sec_num=3
    JOIN #card_sc_base c ON a.EMP_ID=c.EMP_ID
  WHERE b.valid_begin_time_tag=0 AND b.valid_end_time_tag=1
    AND ((c.SlotCardDate BETWEEN @attStartDate AND @attEndDate_p1 AND c.CardReason IS NULL) OR (ISNULL(c.AppState,0) <> 0 AND c.CardReason IS NOT NULL))
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY a.EMP_ID,a.attdate;

  UPDATE a SET a.ST3=b.sk1 FROM #t_att_lst_DayResult a JOIN #mm_sec3_m10 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;
  UPDATE a SET a.ET3=b.sk2 FROM #t_att_lst_DayResult a JOIN #mm_sec3_m10 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;
  UPDATE a SET a.ST3=b.sk_st FROM #t_att_lst_DayResult a JOIN #mm_sec3_p01 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;
  UPDATE a SET a.ET3=b.sk_et FROM #t_att_lst_DayResult a JOIN #mm_sec3_p01 b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate WHERE a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT '开始更新入职当天默认上班卡：'+CONVERT(NVARCHAR(20),GETDATE(),120);

  /**4.入职当天的上班卡，默认是班次设定的上班卡，因为通常是很难打到卡，容易出现第一天上班是旷工的情况*/
  UPDATE a
  SET
    a.ST1=DATEADD(dd,DATEDIFF(dd,a.BCST1,b.frist_join_date),a.BCST1),
    a.ST2=CASE WHEN a.BCST2 IS NOT NULL THEN DATEADD(dd,DATEDIFF(dd,a.BCST2,b.frist_join_date),a.BCST2) ELSE a.ST2 END,
    a.ST3=CASE WHEN a.BCST3 IS NOT NULL THEN DATEADD(dd,DATEDIFF(dd,a.BCST3,b.frist_join_date),a.BCST3) ELSE a.ST3 END
  FROM
    #t_att_lst_DayResult a,
    dbo.t_base_employee b,
    dbo.att_lst_time_interval c
  WHERE
    a.EMP_ID=b.code AND a.attdate=b.frist_join_date
    AND a.ShiftID=c.pb_code_fid AND c.sec_num=1 AND c.begin_time_slot_card=1
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
    AND (a.ST1 IS NULL OR a.ST1>DATEADD(dd,DATEDIFF(dd,a.BCST1,b.frist_join_date),a.BCST1));

  PRINT '开始更新第八段刷卡时间：'+CONVERT(NVARCHAR(20),GETDATE(),120);
			
  /* 休息班刷卡聚合（纯重构：供第8/9段复用） */
  DROP TABLE IF EXISTS #mm_rest;
  SELECT
    a.EMP_ID,
    a.attdate,
    MIN(c.sc) AS sk1,
    MAX(c.sc) AS sk2
  INTO #mm_rest
  FROM
    #t_att_lst_DayResult a
    JOIN #card_sc_base c
      ON a.EMP_ID=c.EMP_ID AND a.attdate=c.SlotCardDate
  WHERE
    c.SlotCardDate BETWEEN @attStartDate AND @attEndDate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate
  GROUP BY
    a.EMP_ID,a.attdate;

  /**5.如果排班休息，并且当天有两次刷卡，也要显示刷记录卡*/
  UPDATE a 
  SET 
    a.ST1=b.sk1,
    a.ET1=b.sk2
  FROM 
    #t_att_lst_DayResult a
    JOIN #mm_rest b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE 
    a.attdate BETWEEN @attStartDate AND @attEndDate 
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
    #t_att_lst_DayResult a
    JOIN #mm_rest b ON a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
  WHERE 
    a.attdate BETWEEN @attStartDate AND @attEndDate 
    AND b.sk1 NOT IN (SELECT ISNULL(st1,0) FROM #t_att_lst_DayResult x WHERE a.EMP_ID=x.EMP_ID )
    AND b.sk2 NOT IN (SELECT ISNULL(ET1,0) FROM #t_att_lst_DayResult y WHERE a.EMP_ID=y.EMP_ID)
    AND (b.sk1=b.sk2 OR (b.sk1 <> b.sk2 AND ABS(DATEDIFF(mi,b.sk1,b.sk2))<=60*5))  --原：30分钟内的两道刷卡算一道 2024-10-16 zhanglinfu 改：五小时内都显示第一次打卡
    AND ISNULL(a.ShiftID,'00000000-0000-0000-0000-000000000000') IN ('00000000-0000-0000-0000-000000000000');

  PRINT '结束更新刷卡记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO


