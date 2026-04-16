USE [SJHRsalarySystemDb];
GO

/* =========================================================
  单测脚本：对比刷卡过程 v1 与当前版本输出是否一致

  说明：
    - 本脚本会在一个事务内插入测试数据（班次时间段 + 刷卡记录）
    - 创建临时表 #t_att_lst_DayResult 并插入测试行
    - 运行 v1 与当前 dbo.att_pro_DayResult_UpdateCardRecords
    - 对比 #t_att_lst_DayResult 的关键输出列是否完全一致
    - 最后 ROLLBACK，不污染正式表

  用法：
    1) 先确保库里已有当前版本：dbo.att_pro_DayResult_UpdateCardRecords
    2) 执行本脚本
    3) 若输出差异行数为 0，则可认为逻辑一致
========================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* 清理：避免同会话重复执行导致临时表已存在 */
DROP TABLE IF EXISTS #t_att_lst_DayResult;
DROP TABLE IF EXISTS #out_v1;
DROP TABLE IF EXISTS #out_curr;
DROP TABLE IF EXISTS #base_dayresult;
GO

/* =========================================================
  0) 固化 v1（只创建一次）
     - 以后你把 dbo.att_pro_DayResult_UpdateCardRecords 改成 v2 之后，
       仍可用本脚本对比 v1 vs v2。
========================================================= */
IF OBJECT_ID(N'dbo.ut_att_pro_DayResult_UpdateCardRecords_v1', N'P') IS NULL
EXEC(N'
CREATE PROC dbo.ut_att_pro_DayResult_UpdateCardRecords_v1
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  PRINT ''开始更新刷卡记录：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0
        AND c.SlotCardTime BETWEEN b.valid_begin_time AND b.valid_end_time 
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;  

  PRINT '' 第一段刷卡时间影响行数为：''+CONVERT(NVARCHAR(20),@@ROWCOUNT);

  PRINT ''开始更新第二段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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
        AND b.sec_num=2
        AND a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate
        AND b.valid_begin_time_tag=0 AND b.valid_end_time_tag=0
        AND c.SlotCardTime BETWEEN b.valid_begin_time AND b.valid_end_time 
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    ) b 
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT ''开始更新第三段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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
        AND b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT ''开始更新第四段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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
        AND b.valid_begin_time_tag=-1 AND b.valid_end_time_tag=0
      GROUP BY  
        a.EMP_ID,a.attdate,b.begin_time,b.end_time
    ) b
    WHERE 
      a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
      AND a.attdate BETWEEN @attStartDate AND @attEndDate;

  PRINT ''开始更新第五段段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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

  PRINT ''开始更新第六段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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

  PRINT ''开始更新第七段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);

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

  PRINT ''开始更新第八段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);
			
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
    AND ABS(DATEDIFF(mi,sk1,sk2))>=60*5
    AND ISNULL(a.ShiftID,''00000000-0000-0000-0000-000000000000'') IN (''00000000-0000-0000-0000-000000000000'');
 
  PRINT ''开始更新第九段刷卡时间：''+CONVERT(NVARCHAR(20),GETDATE(),120);
 
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
    AND (b.sk1=b.sk2 OR (b.sk1 <> b.sk2 AND ABS(DATEDIFF(mi,b.sk1,b.sk2))<=60*5))
    AND ISNULL(a.ShiftID,''00000000-0000-0000-0000-000000000000'') IN (''00000000-0000-0000-0000-000000000000'');

  PRINT ''结束更新刷卡记录：''+CONVERT(NVARCHAR(20),GETDATE(),120);
END
');
GO

DECLARE
  @attStartDate DATETIME = '2026-03-01',
  @attEndDate   DATETIME = '2026-03-02',
  @emp_id       CHAR(10) = 'UT00000001',
  @emp_id2      CHAR(10) = 'UT00000002',
  @shift_00     UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000',
  @shift_day    UNIQUEIDENTIFIER = NEWID(),
  @shift_m10    UNIQUEIDENTIFIER = NEWID(),
  @shift_p01    UNIQUEIDENTIFIER = NEWID(),
  @fid1         UNIQUEIDENTIFIER = NEWID(),
  @fid2         UNIQUEIDENTIFIER = NEWID(),
  @fid3         UNIQUEIDENTIFIER = NEWID();

BEGIN TRAN;

  /* 清理：避免误碰到已有同名测试员工数据（事务内，最后回滚） */

  /* 1) 准备班次时间段（只插入本次测试需要的三种 tag：0/0、-1/0、0/1） */
  INSERT INTO dbo.att_lst_time_interval
  (
    FID, pb_code_fid, name,
    sec_num,
    valid_begin_time_tag, valid_begin_time,
    valid_end_time_tag, valid_end_time,
    begin_time_slot_card
  )
  VALUES
  (NEWID(), @shift_day, N'UT 0/0', 1, 0, '1900-01-01T08:00:00', 0, '1900-01-01T20:00:00', 1),
  (NEWID(), @shift_day, N'UT 0/0 sec2', 2, 0, '1900-01-01T12:00:00', 0, '1900-01-01T18:00:00', 1),
  (NEWID(), @shift_m10, N'UT -1/0', 1, -1, '1900-01-01T20:00:00', 0, '1900-01-01T08:00:00', 1),
  (NEWID(), @shift_p01, N'UT 0/1', 1, 0, '1900-01-01T08:00:00', 1, '1900-01-01T08:00:00', 1);

  /* 2) 准备刷卡记录 */
  INSERT INTO dbo.att_lst_Cardrecord
  (
    FID, EMP_ID, SlotCardDate, SlotCardTime, CardReason, AppState, OperationTime
  )
  VALUES
  -- 0/0：同一天两次刷卡
  (NEWID(), @emp_id, '2026-03-01', '2026-03-01T08:55:00', NULL, NULL, GETDATE()),
  (NEWID(), @emp_id, '2026-03-01', '2026-03-01T18:05:00', NULL, NULL, GETDATE()),
  -- 0/0 sec_num=2：同一天两次刷卡（覆盖 ST2/ET2）
  (NEWID(), @emp_id, '2026-03-01', '2026-03-01T12:10:00', NULL, NULL, GETDATE()),
  (NEWID(), @emp_id, '2026-03-01', '2026-03-01T17:50:00', NULL, NULL, GETDATE()),

  -- -1/0：跨天，刷卡发生在前一天与当天早晨
  (NEWID(), @emp_id, '2026-02-28', '2026-02-28T23:00:00', NULL, NULL, GETDATE()),
  (NEWID(), @emp_id, '2026-03-01', '2026-03-01T07:30:00', NULL, NULL, GETDATE()),

  -- 0/1：跨天，刷卡发生在当天晚上与次日清晨
  (NEWID(), @emp_id, '2026-03-01', '2026-03-01T21:00:00', NULL, NULL, GETDATE()),
  (NEWID(), @emp_id, '2026-03-02', '2026-03-02T06:00:00', NULL, NULL, GETDATE()),

  -- 休息班：同日两次刷卡（用于第8段/第9段）
  (NEWID(), @emp_id, '2026-03-02', '2026-03-02T09:10:00', NULL, NULL, GETDATE()),
  (NEWID(), @emp_id, '2026-03-02', '2026-03-02T16:10:00', NULL, NULL, GETDATE()),

  -- OR 分支：补卡/审批通过（CardReason 非空 + AppState=1）
  (NEWID(), @emp_id2, '2026-03-01', '2026-03-01T09:05:00', '补卡', '1', GETDATE()),
  (NEWID(), @emp_id2, '2026-03-01', '2026-03-01T18:10:00', '补卡', '1', GETDATE());

  /* 3) 准备日结临时表（只保留本过程会读写的字段） */
  DROP TABLE IF EXISTS #t_att_lst_DayResult;
  CREATE TABLE #t_att_lst_DayResult
  (
    EMP_ID CHAR(10) NOT NULL,
    attDate DATE NOT NULL,
    ShiftID UNIQUEIDENTIFIER NULL,

    BCST1 DATETIME NULL,
    begin_time_tag1 INT NULL,
    BCET1 DATETIME NULL,
    end_time_tag1 INT NULL,
    ST1 DATETIME NULL,
    ET1 DATETIME NULL,

    BCST2 DATETIME NULL,
    begin_time_tag2 INT NULL,
    BCET2 DATETIME NULL,
    end_time_tag2 INT NULL,
    ST2 DATETIME NULL,
    ET2 DATETIME NULL
  );

  /* 三种班次各插一行 + 一行休息班 */
  INSERT INTO #t_att_lst_DayResult
  (
    EMP_ID, attDate, ShiftID,
    BCST1, begin_time_tag1, BCET1, end_time_tag1,
    BCST2, begin_time_tag2, BCET2, end_time_tag2
  )
  VALUES
  (@emp_id, '2026-03-01', @shift_day, '1900-01-01T08:00:00', 0, '1900-01-01T20:00:00', 0, NULL, NULL, NULL, NULL),
  (@emp_id, '2026-03-01', @shift_m10, '1900-01-01T20:00:00', -1, '1900-01-01T08:00:00', 0, NULL, NULL, NULL, NULL),
  (@emp_id, '2026-03-01', @shift_p01, '1900-01-01T08:00:00', 0, '1900-01-01T08:00:00', 1, NULL, NULL, NULL, NULL),
  (@emp_id, '2026-03-02', @shift_00,  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  (@emp_id2, '2026-03-01', @shift_day, '1900-01-01T08:00:00', 0, '1900-01-01T20:00:00', 0, NULL, NULL, NULL, NULL);

  /* 保存一份基线数据，用于两次执行之间恢复 */
  DROP TABLE IF EXISTS #base_dayresult;
  SELECT *
  INTO #base_dayresult
  FROM #t_att_lst_DayResult;

  /* 4) 跑 v1 */
  EXEC dbo.ut_att_pro_DayResult_UpdateCardRecords_v1 @attStartDate=@attStartDate, @attEndDate=@attEndDate;

  DROP TABLE IF EXISTS #out_v1;
  SELECT EMP_ID, attDate, ShiftID, ST1, ET1, ST2, ET2
  INTO #out_v1
  FROM #t_att_lst_DayResult
  ORDER BY EMP_ID, attDate;

  /* 5) 恢复基线数据，再跑 current（避免重复 DROP/CREATE 临时表导致 2714） */
  DELETE FROM #t_att_lst_DayResult;
  INSERT INTO #t_att_lst_DayResult
  SELECT * FROM #base_dayresult;

  EXEC dbo.att_pro_DayResult_UpdateCardRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;

  DROP TABLE IF EXISTS #out_curr;
  SELECT EMP_ID, attDate, ShiftID, ST1, ET1, ST2, ET2
  INTO #out_curr
  FROM #t_att_lst_DayResult
  ORDER BY EMP_ID, attDate;

  /* 6) 对比差异 */
  SELECT 'v1_minus_curr' AS diff, *
  FROM #out_v1
  EXCEPT
  SELECT 'v1_minus_curr', *
  FROM #out_curr;

  SELECT 'curr_minus_v1' AS diff, *
  FROM #out_curr
  EXCEPT
  SELECT 'curr_minus_v1', *
  FROM #out_v1;

ROLLBACK TRAN;
GO

