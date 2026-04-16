/* =========================================================
  测试数据：两段班次（四次卡）+ 排班 + 刷卡
  数据库：SJHRsalarySystemDb
  人员：A8425
  日期：2626-03-17
========================================================= */

USE [SJHRsalarySystemDb];
GO

/* 0) 参数 */
DECLARE @EmpId  char(10) = 'A8425';
DECLARE @D date = '2626-03-17';
DECLARE @JS_Month char(20) = '262603';

/* 1) 生成测试班次 ShiftId，并插入两段班次设定（sec_num=1/2） */
DECLARE @ShiftId uniqueidentifier = NEWID();
PRINT 'ShiftId_For_Test = ' + CONVERT(varchar(36), @ShiftId);

-- 清理：如果你反复执行，建议先删掉这次 ShiftId 的班次设定
DELETE FROM dbo.att_lst_time_interval WHERE pb_code_fid = @ShiftId;

-- 时间段1：08:30-12:00，有效刷卡窗口 08:00-12:30
INSERT INTO dbo.att_lst_time_interval
(
  FID, pb_code_fid, name,
  valid_begin_time_tag, valid_begin_time,
  begin_time_tag, begin_time, begin_time_slot_card,
  end_time_tag, end_time, end_time_slot_card,
  valid_end_time_tag, valid_end_time,
  centre_time_tag, centre_time,
  half_time, time_length, remark, sec_num,
  import_sign, op, modifyTime
)
VALUES
(
  NEWID(), @ShiftId, 'SEG1',
  0, CAST('08:00:00' AS datetime),
  0, CAST('08:30:00' AS datetime), 1,
  0, CAST('12:00:00' AS datetime), 1,
  0, CAST('12:30:00' AS datetime),
  0, CAST('10:15:00' AS datetime),
  0, 3.5, NULL, 1,
  NULL, N'test', CONVERT(nvarchar(50), GETDATE(), 120)
);

-- 时间段2：13:00-17:30，有效刷卡窗口 12:30-18:00
INSERT INTO dbo.att_lst_time_interval
(
  FID, pb_code_fid, name,
  valid_begin_time_tag, valid_begin_time,
  begin_time_tag, begin_time, begin_time_slot_card,
  end_time_tag, end_time, end_time_slot_card,
  valid_end_time_tag, valid_end_time,
  centre_time_tag, centre_time,
  half_time, time_length, remark, sec_num,
  import_sign, op, modifyTime
)
VALUES
(
  NEWID(), @ShiftId, 'SEG2',
  0, CAST('12:30:00' AS datetime),
  0, CAST('13:00:00' AS datetime), 1,
  0, CAST('17:30:00' AS datetime), 1,
  0, CAST('18:00:00' AS datetime),
  0, CAST('15:15:00' AS datetime),
  0, 4.5, NULL, 2,
  NULL, N'test', CONVERT(nvarchar(50), GETDATE(), 120)
);
GO

/* 2) 生成 A8425 在 2626-03-17 的排班（JS_Month=262603，Day17_ID=@ShiftId） */
USE [SJHRsalarySystemDb];
GO

DECLARE @EmpId  char(10) = 'A8425';
DECLARE @JS_Month char(20) = '262603';

-- !!! 把这里替换成你刚才 PRINT 出来的 ShiftId !!!
DECLARE @ShiftId uniqueidentifier = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

IF EXISTS (SELECT 1 FROM dbo.att_lst_JobScheduling WHERE EMP_ID=@EmpId AND JS_Month=@JS_Month)
BEGIN
  UPDATE dbo.att_lst_JobScheduling
  SET Day17_ID = @ShiftId,
      Day17_Name = N'两段班次(测试)',
      modifier = N'test',
      modifyTime = GETDATE()
  WHERE EMP_ID=@EmpId AND JS_Month=@JS_Month;
END
ELSE
BEGIN
  INSERT INTO dbo.att_lst_JobScheduling
  (
    FID, EMP_ID, JS_Month,
    Day17_ID, Day17_Name,
    modifier, modifyTime
  )
  VALUES
  (
    NEWID(), @EmpId, @JS_Month,
    @ShiftId, N'两段班次(测试)',
    N'test', GETDATE()
  );
END
GO

/* 3) 生成 A8425 在 2626-03-17 的 4 次刷卡记录 */
USE [SJHRsalarySystemDb];
GO

DECLARE @EmpId  char(10) = 'A8425';
DECLARE @D date = '2626-03-17';

-- 可重复执行：先删掉当天测试刷卡（按 sourceType=TEST + 人员 + 日期）
DELETE FROM dbo.att_lst_Cardrecord
WHERE EMP_ID=@EmpId AND SlotCardDate=@D AND sourceType='TEST';

-- 4次卡：08:28 / 12:01 / 13:05 / 17:32（你可按需改）
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, @D, DATEFROMPARTS(2626,3,17) + CAST('08:28:00' AS time), NULL, N'test', GETDATE(), NULL, NULL, 'TEST'),
(NEWID(), @EmpId, @D, DATEFROMPARTS(2626,3,17) + CAST('12:01:00' AS time), NULL, N'test', GETDATE(), NULL, NULL, 'TEST'),
(NEWID(), @EmpId, @D, DATEFROMPARTS(2626,3,17) + CAST('13:05:00' AS time), NULL, N'test', GETDATE(), NULL, NULL, 'TEST'),
(NEWID(), @EmpId, @D, DATEFROMPARTS(2626,3,17) + CAST('17:32:00' AS time), NULL, N'test', GETDATE(), NULL, NULL, 'TEST');
GO

/* 4) 快速检查（可选） */
USE [SJHRsalarySystemDb];
GO

DECLARE @EmpId  char(10) = 'A8425';
DECLARE @D date = '2626-03-17';

SELECT 'time_interval' AS t, pb_code_fid, sec_num, valid_begin_time, begin_time, end_time, valid_end_time
FROM dbo.att_lst_time_interval
WHERE pb_code_fid IN (
  SELECT Day17_ID FROM dbo.att_lst_JobScheduling WHERE EMP_ID=@EmpId AND JS_Month='262603'
)
ORDER BY sec_num;

SELECT 'cards' AS t, EMP_ID, SlotCardDate, SlotCardTime, CardReason, AppState, sourceType
FROM dbo.att_lst_Cardrecord
WHERE EMP_ID=@EmpId AND SlotCardDate=@D
ORDER BY SlotCardTime;
GO

/* =========================================================
  下面两段是“你需要改存储过程/视图”的 SQL 片段（手工贴入对应文件/对象后再执行）
  - 我在 Ask mode 不能替你改文件，但你可以复制进去。
========================================================= */

/* 5) att_pro_DayResult：增加第2段迟到/早退的累加（把这两段放到原“迟到/早退”后面） */
-- 第2段迟到（第三次卡：ST2 vs BCST2）
-- UPDATE a
-- SET
--   a.attLate = ISNULL(a.attLate, 0)
--     + DATEDIFF(mi,
--         DATEADD(dd, DATEDIFF(dd, a.BCST2, a.attdate) + a.begin_time_tag2, a.BCST2),
--         a.ST2
--       )
-- FROM #t_att_lst_DayResult a
-- JOIN dbo.att_lst_time_interval c
--   ON a.ShiftID = c.pb_code_fid AND c.sec_num = 2
-- WHERE
--   c.begin_time_slot_card = 1
--   AND a.ST2 IS NOT NULL AND a.BCST2 IS NOT NULL
--   AND DATEADD(dd, DATEDIFF(dd, a.BCST2, a.attdate) + a.begin_time_tag2, a.BCST2) < a.ST2
--   AND a.ShiftID <> '00000000-0000-0000-0000-000000000000';

-- 第2段早退（第四次卡：ET2 vs BCET2）
-- UPDATE a
-- SET
--   a.attEarly = ISNULL(a.attEarly, 0)
--     + DATEDIFF(mi,
--         a.ET2,
--         DATEADD(dd, DATEDIFF(dd, a.BCET2, a.attdate) + a.end_time_tag2, a.BCET2)
--       )
-- FROM #t_att_lst_DayResult a
-- JOIN dbo.att_lst_time_interval c
--   ON a.ShiftID = c.pb_code_fid AND c.sec_num = 2
-- WHERE
--   c.end_time_slot_card = 1
--   AND a.ET2 IS NOT NULL AND a.BCET2 IS NOT NULL
--   AND DATEADD(dd, DATEDIFF(dd, a.BCET2, a.attdate) + a.end_time_tag2, a.BCET2) > a.ET2
--   AND a.ShiftID <> '00000000-0000-0000-0000-000000000000';

/* 6) att_pro_DayResult：新增四次卡描述写入 errorMessage（独立一段，不绑定旷工） */
-- UPDATE a
-- SET a.errorMessage =
--   STUFF(
--     COALESCE(
--       CASE WHEN a.ST1 IS NULL THEN N'|缺第一次卡' ELSE N'' END +
--       CASE WHEN a.ET1 IS NULL THEN N'|缺第二次卡' ELSE N'' END +
--       CASE WHEN a.ST2 IS NULL THEN N'|缺第三次卡' ELSE N'' END +
--       CASE WHEN a.ET2 IS NULL THEN N'|缺第四次卡' ELSE N'' END +
--       CASE WHEN a.ST1 IS NOT NULL AND a.BCST1 IS NOT NULL
--              AND a.ST1 > DATEADD(dd, DATEDIFF(dd, a.BCST1, a.attdate) + a.begin_time_tag1, a.BCST1)
--            THEN N'|第一次卡迟到' + CONVERT(nvarchar(10),
--                 DATEDIFF(mi,
--                   DATEADD(dd, DATEDIFF(dd, a.BCST1, a.attdate) + a.begin_time_tag1, a.BCST1),
--                   a.ST1
--                 )
--               ) + N'分钟'
--            ELSE N'' END +
--       CASE WHEN a.ET1 IS NOT NULL AND a.BCET1 IS NOT NULL
--              AND a.ET1 < DATEADD(dd, DATEDIFF(dd, a.BCET1, a.attdate) + a.end_time_tag1, a.BCET1)
--            THEN N'|第二次卡早退' + CONVERT(nvarchar(10),
--                 DATEDIFF(mi,
--                   a.ET1,
--                   DATEADD(dd, DATEDIFF(dd, a.BCET1, a.attdate) + a.end_time_tag1, a.BCET1)
--                 )
--               ) + N'分钟'
--            ELSE N'' END +
--       CASE WHEN a.ST2 IS NOT NULL AND a.BCST2 IS NOT NULL
--              AND a.ST2 > DATEADD(dd, DATEDIFF(dd, a.BCST2, a.attdate) + a.begin_time_tag2, a.BCST2)
--            THEN N'|第三次卡迟到' + CONVERT(nvarchar(10),
--                 DATEDIFF(mi,
--                   DATEADD(dd, DATEDIFF(dd, a.BCST2, a.attdate) + a.begin_time_tag2, a.BCST2),
--                   a.ST2
--                 )
--               ) + N'分钟'
--            ELSE N'' END +
--       CASE WHEN a.ET2 IS NOT NULL AND a.BCET2 IS NOT NULL
--              AND a.ET2 < DATEADD(dd, DATEDIFF(dd, a.BCET2, a.attdate) + a.end_time_tag2, a.BCET2)
--            THEN N'|第四次卡早退' + CONVERT(nvarchar(10),
--                 DATEDIFF(mi,
--                   a.ET2,
--                   DATEADD(dd, DATEDIFF(dd, a.BCET2, a.attdate) + a.end_time_tag2, a.BCET2)
--                 )
--               ) + N'分钟'
--            ELSE N'' END
--     , N'')
--   , 1, 1, N'');

/* 7) v_att_lst_DayResult：attTime 改为两段相加（把视图里的 attTime 那行替换成下面） */
-- CONVERT(varchar(8),
--   DATEADD(SECOND,
--     ISNULL(DATEDIFF(SECOND, dr.ST1, dr.ET1), 0) +
--     ISNULL(DATEDIFF(SECOND, dr.ST2, dr.ET2), 0),
--   0),
-- 108) AS attTime