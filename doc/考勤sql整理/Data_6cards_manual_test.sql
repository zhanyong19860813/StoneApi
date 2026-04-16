/*
  Data_6cards_manual_test.sql
  用途：六次卡（BC_6CARDS）测试数据，供手动调用 att_pro_DayResult 验证

  前提：执行前需已运行 alter_att_lst_DayResult_add_segment3.sql
  班次：三段 08:30~12:00、13:00~17:00、18:00~21:00（均当天 [0,0]）

  场景一览：
  ┌─────┬────────────────────┬──────────────────────────────────────────────────┐
  │场景 │ 说明               │ 打卡时间（上午/下午/晚班）                        │
  ├─────┼────────────────────┼──────────────────────────────────────────────────┤
  │  1  │ 正常六次卡         │ 08:15 12:05 12:55 17:05 17:55 21:05              │
  │  2  │ 第三段上班迟到     │ 08:15 12:05 12:55 17:05 18:30 21:05              │
  │  3  │ 缺第三段下班卡     │ 08:15 12:05 12:55 17:05 17:55 -                  │
  │  4  │ 多场景组合(默认)   │ 03-10正常 03-11缺第三段下 03-12第三段迟到        │
  └─────┴────────────────────┴──────────────────────────────────────────────────┘

  使用方式：
    1. 首次执行：运行全文（含班次创建、排班更新、场景4数据、日结、结果查看）
    2. 测单场景：注释掉场景4的 INSERT，取消注释目标场景的 INSERT
*/

USE [SJHRsalarySystemDb]
GO

SET NOCOUNT ON;

DECLARE @Emp   NVARCHAR(10) = 'A8425';
DECLARE @Start DATE = '2026-03-01';
DECLARE @End   DATE = '2026-03-31';
DECLARE @BC6CARDS UNIQUEIDENTIFIER = 'A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D';  -- 六次卡班次 FID

PRINT '========== 〇、创建 BC_6CARDS 班次（若不存在）==========';
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_6CARDS')
BEGIN
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, other_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@BC6CARDS, 'BC_6CARDS', 11.0, 0, NULL, 0, 'TEST_六次卡', GETDATE(), 'test');
  PRINT '  - 已创建 BC_6CARDS';

  -- 三段 [0,0]：上午 08:30~12:00、下午 13:00~17:00、晚班 18:00~21:00
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES
    (NEWID(), @BC6CARDS, '6CARDS_SEG1', 0, '1900-01-01 08:00:00', 0, '1900-01-01 08:30:00', 1, 0, '1900-01-01 12:00:00', 1, 0, '1900-01-01 13:00:00', 1),
    (NEWID(), @BC6CARDS, '6CARDS_SEG2', 0, '1900-01-01 13:00:00', 0, '1900-01-01 13:00:00', 1, 0, '1900-01-01 17:00:00', 1, 0, '1900-01-01 18:00:00', 2),
    (NEWID(), @BC6CARDS, '6CARDS_SEG3', 0, '1900-01-01 18:00:00', 0, '1900-01-01 18:00:00', 1, 0, '1900-01-01 21:00:00', 1, 0, '1900-01-01 22:00:00', 3);
  PRINT '  - 已创建三段 att_lst_time_interval';
END
ELSE
  SELECT @BC6CARDS = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_6CARDS';

PRINT '';
PRINT '========== 〇.1、更新 A8425 排班 Day10~Day14 为 BC_6CARDS ==========';
UPDATE dbo.att_lst_JobScheduling
SET
  Day10_ID = @BC6CARDS, Day10_Name = N'BC_6CARDS',
  Day11_ID = @BC6CARDS, Day11_Name = N'BC_6CARDS',
  Day12_ID = @BC6CARDS, Day12_Name = N'BC_6CARDS',
  Day13_ID = @BC6CARDS, Day13_Name = N'BC_6CARDS',
  Day14_ID = @BC6CARDS, Day14_Name = N'BC_6CARDS'
WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND JS_Month = '202603';
IF @@ROWCOUNT = 0
  PRINT '  - 警告：未找到 A8425 的 202603 排班，请先创建排班记录';
ELSE
  PRINT '  - 已更新 Day10~Day14 为 BC_6CARDS';

PRINT '';
PRINT '========== 〇.2、清理旧数据（Day10~Day14 = 03-10~03-14）==========';
DELETE FROM dbo.att_lst_Cardrecord
WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND CAST(SlotCardDate AS DATE) BETWEEN '2026-03-10' AND '2026-03-14';
PRINT '  - 已清理刷卡记录';

DELETE FROM dbo.att_lst_DayResult
WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND attdate BETWEEN '2026-03-10' AND '2026-03-14';
PRINT '  - 已清理日结果';

-- ============================================================================
-- 一、测试场景（取消注释要测试的那一段）
-- ============================================================================

/*
----------- 场景1：正常六次卡 --------
03-10：08:15 12:05 12:55 17:05 17:55 21:05（均满足各段窗口）
*/
/*
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 08:15:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:55:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:55:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 21:05:00', '1');
PRINT '场景1：正常六次卡 已插入';
*/

/*
----------- 场景2：第三段上班迟到 --------
03-10：第三段 18:30 上班（晚于 18:00）
*/
/*
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 08:15:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:55:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 18:30:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 21:05:00', '1');
PRINT '场景2：第三段上班迟到 已插入';
*/

/*
----------- 场景3：缺第三段下班卡 --------
03-10：缺第六次打卡（晚班下班）
*/
/*
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 08:15:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:55:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:55:00', '1');
PRINT '场景3：缺第三段下班卡 已插入';
*/

-- ----------- 场景4：多场景组合（默认启用）-----------
-- 03-10 正常六次卡 | 03-11 缺第三段下班 | 03-12 第三段上班迟到
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 08:15:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:55:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:05:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:55:00', '1'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 21:05:00', '1'),
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 08:15:00', '1'),
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 12:05:00', '1'),
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 12:55:00', '1'),
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 17:05:00', '1'),
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 17:55:00', '1'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 08:15:00', '1'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 12:05:00', '1'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 12:55:00', '1'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 17:05:00', '1'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 18:30:00', '1'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 21:05:00', '1');
PRINT '场景4：多场景组合 已插入';

-- ============================================================================
-- 二、执行日结
-- ============================================================================
PRINT '';
PRINT '========== 二、执行 att_pro_DayResult ==========';
EXEC dbo.att_pro_DayResult
  @emp_list      = @Emp,
  @DayResultType = '0',
  @attStartDate  = @Start,
  @attEndDate    = @End,
  @op            = @Emp;
PRINT '  - 日结完成';

-- ============================================================================
-- 三、查看结果
-- ============================================================================
PRINT '';
PRINT '========== 三、日结果（att_lst_DayResult）==========';
SELECT
  attdate       AS [日期],
  attStatus     AS [状态],
  BCST1, BCET1, ST1, ET1,
  BCST2, BCET2, ST2, ET2,
  BCST3, BCET3, ST3, ET3,
  attStatus1, attStatus2, attStatus3,
  attLate       AS [迟到分],
  attEarly      AS [早退分],
  attAbsenteeism AS [旷工],
  errorMessage  AS [错误信息]
FROM dbo.att_lst_DayResult
WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND attdate BETWEEN '2026-03-10' AND '2026-03-14'
ORDER BY attdate;

GO

/*
-- 清理测试数据
DELETE FROM dbo.att_lst_Cardrecord WHERE RTRIM(EMP_ID) = 'A8425' AND CAST(SlotCardDate AS DATE) BETWEEN '2026-03-10' AND '2026-03-14';
DELETE FROM dbo.att_lst_DayResult  WHERE RTRIM(EMP_ID) = 'A8425' AND attdate BETWEEN '2026-03-10' AND '2026-03-14';
*/
