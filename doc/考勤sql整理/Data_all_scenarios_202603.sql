/*
  Data_all_scenarios_202603.sql
  全场景测试：两次卡、四次卡、六次卡 + 跨天 [-1,0]、[0,1] + 正常/异常

  前提：
    - 已执行 alter_att_lst_DayResult_add_segment_status.sql、alter_att_lst_DayResult_add_segment3.sql
    - att_lst_Cardrecord 若需 IsOk 等列，请自行在 INSERT 中补充

  场景分配（2026-03 月）：
  ┌────────┬──────────────┬─────────────────────────────────────────────────────────┐
  │ 日期   │ 班次         │ 场景说明                                                  │
  ├────────┼──────────────┼─────────────────────────────────────────────────────────┤
  │ 03-01  │ 2cards [0,0] │ 正常                                                      │
  │ 03-02  │ 2cards [0,0] │ 迟到                                                      │
  │ 03-03  │ 2cards [0,0] │ 早退                                                      │
  │ 03-04  │ 2cards [0,0] │ 缺上班卡(旷工)                                            │
  │ 03-05  │ 2cards [0,0] │ 缺下班卡(旷工)                                            │
  │ 03-06  │ 2cards [0,0] │ 迟到+早退                                                 │
  │ 03-07  │ 2cards[-1,0] │ 跨天：上班前日22:00 下班当日06:00 → 正常                  │
  │ 03-08  │ 2cards [0,1] │ 跨天：上班当日22:00 下班次日06:00 → 正常                  │
  │ 03-10  │ 4cards [0,0] │ 正常四次卡                                                │
  │ 03-11  │ 4cards [0,0] │ 上午迟到                                                  │
  │ 03-12  │ 4cards [0,0] │ 下午早退                                                  │
  │ 03-13  │ 4cards [0,0] │ 缺下午下班卡                                              │
  │ 03-14  │ 4cards[-1,0,0]│ 跨天：第1段[-1,0] 上班03-13 22:00 下班03-14 06:00       │
  │ 03-15  │ 4cards[0,0,1]│ 跨天：第2段[0,1] 上班03-15 18:00 下班03-16 02:00         │
  │ 03-17  │ 6cards [0,0,0]│ 正常六次卡                                               │
  │ 03-18  │ 6cards [0,0,0]│ 第三段迟到                                               │
  │ 03-19  │ 6cards [0,0,0]│ 缺第三段下班卡                                           │
  └────────┴──────────────┴─────────────────────────────────────────────────────────┘
*/

USE [SJHRsalarySystemDb]
GO
SET NOCOUNT ON;

DECLARE @Emp      CHAR(10) = 'A8425';
DECLARE @JS_Month CHAR(20) = '202603';
DECLARE @Start    DATE = '2026-03-01';
DECLARE @End      DATE = '2026-03-31';
DECLARE @Base     DATETIME = '1900-01-01';

-- 班次ID（创建后获取）
DECLARE @S2_00   UNIQUEIDENTIFIER;
DECLARE @S2_m10  UNIQUEIDENTIFIER;
DECLARE @S2_p01  UNIQUEIDENTIFIER;
DECLARE @S4_00   UNIQUEIDENTIFIER;
DECLARE @S4_m100 UNIQUEIDENTIFIER;
DECLARE @S4_001  UNIQUEIDENTIFIER;
DECLARE @S6_000  UNIQUEIDENTIFIER;

PRINT '========== 1. 创建/获取班次 ==========';

-- 两次卡 [0,0] 08:30-17:30（有效窗口 08:00-18:00）
SELECT @S2_00 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_2CARDS';
IF @S2_00 IS NULL
BEGIN
  SET @S2_00 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S2_00, 'BC_2CARDS', 8.0, 0, 0, 'TEST_两次卡', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES (NEWID(), @S2_00, '2CARDS_SEG1', 0, '1900-01-01 08:00:00', 0, '1900-01-01 08:30:00', 1, 0, '1900-01-01 17:30:00', 1, 0, '1900-01-01 18:00:00', 1);
END

-- 两次卡 [-1,0] 夜班：前日22:00-当日06:00
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_2CARDS_M10')
BEGIN
  SET @S2_m10 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S2_m10, 'BC_2CARDS_M10', 8.0, 0, 0, 'TEST_两次卡跨天[-1,0]', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES (NEWID(), @S2_m10, '2M10_SEG1', -1, '1900-01-01 22:00:00', -1, '1900-01-01 22:00:00', 1, 0, '1900-01-01 06:00:00', 1, 0, '1900-01-01 06:00:00', 1);
END
SELECT @S2_m10 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_2CARDS_M10';

-- 两次卡 [0,1] 夜班：当日22:00-次日06:00
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_2CARDS_P01')
BEGIN
  SET @S2_p01 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S2_p01, 'BC_2CARDS_P01', 8.0, 0, 0, 'TEST_两次卡跨天[0,1]', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES (NEWID(), @S2_p01, '2P01_SEG1', 0, '1900-01-01 22:00:00', 0, '1900-01-01 22:00:00', 1, 1, '1900-01-01 06:00:00', 1, 1, '1900-01-01 06:00:00', 1);
END
SELECT @S2_p01 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_2CARDS_P01';

-- 四次卡 [0,0]
SELECT @S4_00 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_4CARDS';
IF @S4_00 IS NULL
BEGIN
  SET @S4_00 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S4_00, 'BC_4CARDS', 8.0, 0, 0, 'TEST_四次卡', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES
    (NEWID(), @S4_00, '4CARDS_SEG1', 0, '1900-01-01 08:00:00', 0, '1900-01-01 08:30:00', 1, 0, '1900-01-01 12:30:00', 1, 0, '1900-01-01 13:00:00', 1),
    (NEWID(), @S4_00, '4CARDS_SEG2', 0, '1900-01-01 13:00:00', 0, '1900-01-01 13:30:00', 1, 0, '1900-01-01 17:30:00', 1, 0, '1900-01-01 18:00:00', 2);
END

-- 四次卡 [-1,0,0] 第1段跨天
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_4CARDS_M100')
BEGIN
  SET @S4_m100 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S4_m100, 'BC_4CARDS_M100', 8.0, 0, 0, 'TEST_四次卡[-1,0,0]', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES
    (NEWID(), @S4_m100, '4M100_S1', -1, '1900-01-01 22:00:00', -1, '1900-01-01 22:00:00', 1, 0, '1900-01-01 06:00:00', 1, 0, '1900-01-01 06:00:00', 1),
    (NEWID(), @S4_m100, '4M100_S2', 0, '1900-01-01 13:00:00', 0, '1900-01-01 13:30:00', 1, 0, '1900-01-01 17:30:00', 1, 0, '1900-01-01 18:00:00', 2);
END
SELECT @S4_m100 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_4CARDS_M100';

-- 四次卡 [0,0,1] 第2段跨天（注：四次卡只有2段，此处为第2段[0,1]）
IF NOT EXISTS (SELECT 1 FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_4CARDS_001')
BEGIN
  SET @S4_001 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S4_001, 'BC_4CARDS_001', 8.0, 0, 0, 'TEST_四次卡[0,0,1]', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES
    (NEWID(), @S4_001, '4001_S1', 0, '1900-01-01 08:00:00', 0, '1900-01-01 08:30:00', 1, 0, '1900-01-01 12:30:00', 1, 0, '1900-01-01 13:00:00', 1),
    (NEWID(), @S4_001, '4001_S2', 0, '1900-01-01 18:00:00', 0, '1900-01-01 18:00:00', 1, 1, '1900-01-01 02:00:00', 1, 1, '1900-01-01 02:00:00', 2);
END
SELECT @S4_001 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_4CARDS_001';

-- 六次卡 [0,0,0]
SELECT @S6_000 = FID FROM dbo.att_lst_BC_set_code WHERE code_name = 'BC_6CARDS';
IF @S6_000 IS NULL
BEGIN
  SET @S6_000 = NEWID();
  INSERT INTO dbo.att_lst_BC_set_code (FID, code_name, total_hours, sk_attribute, share_bc, remark1, add_time, add_user)
  VALUES (@S6_000, 'BC_6CARDS', 11.0, 0, 0, 'TEST_六次卡', GETDATE(), 'test');
  INSERT INTO dbo.att_lst_time_interval (FID, pb_code_fid, name, valid_begin_time_tag, valid_begin_time, begin_time_tag, begin_time, begin_time_slot_card, end_time_tag, end_time, end_time_slot_card, valid_end_time_tag, valid_end_time, sec_num)
  VALUES
    (NEWID(), @S6_000, '6CARDS_S1', 0, '1900-01-01 08:00:00', 0, '1900-01-01 08:30:00', 1, 0, '1900-01-01 12:00:00', 1, 0, '1900-01-01 13:00:00', 1),
    (NEWID(), @S6_000, '6CARDS_S2', 0, '1900-01-01 13:00:00', 0, '1900-01-01 13:00:00', 1, 0, '1900-01-01 17:00:00', 1, 0, '1900-01-01 18:00:00', 2),
    (NEWID(), @S6_000, '6CARDS_S3', 0, '1900-01-01 18:00:00', 0, '1900-01-01 18:00:00', 1, 0, '1900-01-01 21:00:00', 1, 0, '1900-01-01 22:00:00', 3);
END

PRINT '  - 班次就绪';

PRINT '';
PRINT '========== 2. 排班 ==========';

DECLARE @JSRowId UNIQUEIDENTIFIER;
SELECT @JSRowId = FID FROM dbo.att_lst_JobScheduling WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND JS_Month = @JS_Month;
IF @JSRowId IS NULL
BEGIN
  SET @JSRowId = NEWID();
  INSERT INTO dbo.att_lst_JobScheduling (FID, EMP_ID, JS_Month, Day1_ID, Day2_ID, Day3_ID, Day4_ID, Day5_ID, Day6_ID, Day7_ID, Day8_ID, Day10_ID, Day11_ID, Day12_ID, Day13_ID, Day14_ID, Day15_ID, Day17_ID, Day18_ID, Day19_ID, modifier, modifyTime)
  VALUES (@JSRowId, @Emp, @JS_Month, @S2_00, @S2_00, @S2_00, @S2_00, @S2_00, @S2_00, @S2_m10, @S2_p01, @S4_00, @S4_00, @S4_00, @S4_00, @S4_m100, @S4_001, @S6_000, @S6_000, @S6_000, N'test', GETDATE());
END
ELSE
BEGIN
  UPDATE dbo.att_lst_JobScheduling SET
    Day1_ID=@S2_00, Day2_ID=@S2_00, Day3_ID=@S2_00, Day4_ID=@S2_00, Day5_ID=@S2_00, Day6_ID=@S2_00,
    Day7_ID=@S2_m10, Day8_ID=@S2_p01,
    Day10_ID=@S4_00, Day11_ID=@S4_00, Day12_ID=@S4_00, Day13_ID=@S4_00, Day14_ID=@S4_m100, Day15_ID=@S4_001,
    Day17_ID=@S6_000, Day18_ID=@S6_000, Day19_ID=@S6_000,
    Day1_Name='BC_2CARDS', Day2_Name='BC_2CARDS', Day3_Name='BC_2CARDS', Day4_Name='BC_2CARDS', Day5_Name='BC_2CARDS', Day6_Name='BC_2CARDS',
    Day7_Name='BC_2CARDS_M10', Day8_Name='BC_2CARDS_P01',
    Day10_Name='BC_4CARDS', Day11_Name='BC_4CARDS', Day12_Name='BC_4CARDS', Day13_Name='BC_4CARDS', Day14_Name='BC_4CARDS_M100', Day15_Name='BC_4CARDS_001',
    Day17_Name='BC_6CARDS', Day18_Name='BC_6CARDS', Day19_Name='BC_6CARDS',
    modifier=N'test', modifyTime=GETDATE()
  WHERE FID = @JSRowId;
END
PRINT '  - 排班已更新';

PRINT '';
PRINT '========== 3. 清理旧测试数据 ==========';

DELETE FROM dbo.att_lst_Cardrecord
WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND SlotCardDate BETWEEN '2026-03-01' AND '2026-03-31';

DELETE FROM dbo.att_lst_DayResult
WHERE RTRIM(EMP_ID) = RTRIM(@Emp) AND attdate BETWEEN '2026-03-01' AND '2026-03-31';

PRINT '';
PRINT '========== 4. 插入刷卡数据 ==========';

-- 辅助：插入单条（兼容不同表结构）
-- 使用最简结构 FID, EMP_ID, SlotCardDate, SlotCardTime

-- 两次卡 [0,0] 03-01~03-06
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-01', '2026-03-01 08:30:00'), (NEWID(), @Emp, '2026-03-01', '2026-03-01 17:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-02', '2026-03-02 08:35:00'), (NEWID(), @Emp, '2026-03-02', '2026-03-02 17:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-03', '2026-03-03 08:30:00'), (NEWID(), @Emp, '2026-03-03', '2026-03-03 17:25:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-04', '2026-03-04 17:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-05', '2026-03-05 08:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-06', '2026-03-06 08:35:00'), (NEWID(), @Emp, '2026-03-06', '2026-03-06 17:25:00');

-- 两次卡 [-1,0] 03-07：attdate=03-07，上班03-06 22:00 下班03-07 06:00
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-06', '2026-03-06 22:00:00'), (NEWID(), @Emp, '2026-03-07', '2026-03-07 06:00:00');

-- 两次卡 [0,1] 03-08：attdate=03-08，上班03-08 22:00 下班03-09 06:00
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES (NEWID(), @Emp, '2026-03-08', '2026-03-08 22:00:00'), (NEWID(), @Emp, '2026-03-09', '2026-03-09 06:00:00');

-- 四次卡 [0,0] 03-10~03-13
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 08:30:00'), (NEWID(), @Emp, '2026-03-10', '2026-03-10 12:30:00'),
  (NEWID(), @Emp, '2026-03-10', '2026-03-10 13:30:00'), (NEWID(), @Emp, '2026-03-10', '2026-03-10 17:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 08:35:00'), (NEWID(), @Emp, '2026-03-11', '2026-03-11 12:30:00'),
  (NEWID(), @Emp, '2026-03-11', '2026-03-11 13:30:00'), (NEWID(), @Emp, '2026-03-11', '2026-03-11 17:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 08:30:00'), (NEWID(), @Emp, '2026-03-12', '2026-03-12 12:25:00'),
  (NEWID(), @Emp, '2026-03-12', '2026-03-12 13:30:00'), (NEWID(), @Emp, '2026-03-12', '2026-03-12 17:30:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-13', '2026-03-13 08:30:00'), (NEWID(), @Emp, '2026-03-13', '2026-03-13 12:30:00'),
  (NEWID(), @Emp, '2026-03-13', '2026-03-13 13:30:00');

-- 四次卡 [-1,0,0] 03-14：第1段 03-13 22:00 - 03-14 06:00
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-13', '2026-03-13 22:00:00'), (NEWID(), @Emp, '2026-03-14', '2026-03-14 06:00:00'),
  (NEWID(), @Emp, '2026-03-14', '2026-03-14 13:30:00'), (NEWID(), @Emp, '2026-03-14', '2026-03-14 17:30:00');

-- 四次卡 [0,0,1] 03-15：第2段 03-15 18:00 - 03-16 02:00
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-15', '2026-03-15 08:30:00'), (NEWID(), @Emp, '2026-03-15', '2026-03-15 12:30:00'),
  (NEWID(), @Emp, '2026-03-15', '2026-03-15 18:00:00'), (NEWID(), @Emp, '2026-03-16', '2026-03-16 02:00:00');

-- 六次卡 03-17~03-19
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-17', '2026-03-17 08:15:00'), (NEWID(), @Emp, '2026-03-17', '2026-03-17 12:05:00'),
  (NEWID(), @Emp, '2026-03-17', '2026-03-17 12:55:00'), (NEWID(), @Emp, '2026-03-17', '2026-03-17 17:05:00'),
  (NEWID(), @Emp, '2026-03-17', '2026-03-17 17:55:00'), (NEWID(), @Emp, '2026-03-17', '2026-03-17 21:05:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-18', '2026-03-18 08:15:00'), (NEWID(), @Emp, '2026-03-18', '2026-03-18 12:05:00'),
  (NEWID(), @Emp, '2026-03-18', '2026-03-18 12:55:00'), (NEWID(), @Emp, '2026-03-18', '2026-03-18 17:05:00'),
  (NEWID(), @Emp, '2026-03-18', '2026-03-18 18:30:00'), (NEWID(), @Emp, '2026-03-18', '2026-03-18 21:05:00');
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime) VALUES
  (NEWID(), @Emp, '2026-03-19', '2026-03-19 08:15:00'), (NEWID(), @Emp, '2026-03-19', '2026-03-19 12:05:00'),
  (NEWID(), @Emp, '2026-03-19', '2026-03-19 12:55:00'), (NEWID(), @Emp, '2026-03-19', '2026-03-19 17:05:00'),
  (NEWID(), @Emp, '2026-03-19', '2026-03-19 17:55:00');

PRINT '  - 刷卡数据已插入';

PRINT '';
PRINT '========== 5. 执行 att_pro_DayResult ==========';
EXEC dbo.att_pro_DayResult @emp_list=@Emp, @DayResultType='0', @attStartDate=@Start, @attEndDate=@End, @op=@Emp;
PRINT '  - 日结完成';

PRINT '';
PRINT '========== 6. 日结果汇总 ==========';
SELECT
  attdate AS [日期],
  bc.code_name AS [班次],
  attStatus AS [状态],
  attStatus1, attStatus2, attStatus3,
  attLate AS [迟到分], attEarly AS [早退分], attAbsenteeism AS [旷工],
  ST1, ET1, ST2, ET2, ST3, ET3,
  errorMessage AS [错误信息]
FROM dbo.att_lst_DayResult d
LEFT JOIN dbo.att_lst_BC_set_code bc ON d.ShiftID = bc.FID
WHERE RTRIM(d.EMP_ID) = RTRIM(@Emp) AND d.attdate BETWEEN '2026-03-01' AND '2026-03-31'
ORDER BY d.attdate;

PRINT '';
PRINT '========== 7. 断言校验（预期 vs 实际）==========';

-- 预期结果：attStatus(0正常1迟到2早退3旷工) attStatus1/2/3 attAbsenteeism(0/1) attLate attEarly
DROP TABLE IF EXISTS #expected;
CREATE TABLE #expected (
  attdate DATE PRIMARY KEY,
  scenario NVARCHAR(50),
  exp_attStatus INT,
  exp_attStatus1 INT,
  exp_attStatus2 INT,
  exp_attStatus3 INT,
  exp_attAbsenteeism INT,
  exp_attLate INT,
  exp_attEarly INT,
  exp_hasST1 BIT,
  exp_hasET1 BIT,
  exp_hasST2 BIT,
  exp_hasET2 BIT,
  exp_hasST3 BIT,
  exp_hasET3 BIT
);

INSERT INTO #expected (attdate, scenario, exp_attStatus, exp_attStatus1, exp_attStatus2, exp_attStatus3, exp_attAbsenteeism, exp_attLate, exp_attEarly, exp_hasST1, exp_hasET1, exp_hasST2, exp_hasET2, exp_hasST3, exp_hasET3) VALUES
  ('2026-03-01', N'2卡正常',           0, 0, NULL, NULL, 0, 0,  0, 1, 1, 0, 0, 0, 0),
  ('2026-03-02', N'2卡迟到',           1, 1, NULL, NULL, 0, 5,  0, 1, 1, 0, 0, 0, 0),
  ('2026-03-03', N'2卡早退',           2, 2, NULL, NULL, 0, 0,  5, 1, 1, 0, 0, 0, 0),
  ('2026-03-04', N'2卡缺上班卡',       3, 3, NULL, NULL, 1, NULL, NULL, 0, 1, 0, 0, 0, 0),
  ('2026-03-05', N'2卡缺下班卡',       3, 3, NULL, NULL, 1, NULL, NULL, 1, 0, 0, 0, 0, 0),
  ('2026-03-06', N'2卡迟到+早退',      2, 2, NULL, NULL, 0, 5,  5, 1, 1, 0, 0, 0, 0),
  ('2026-03-07', N'2卡跨天[-1,0]',     0, 0, NULL, NULL, 0, 0,  0, 1, 1, 0, 0, 0, 0),
  ('2026-03-08', N'2卡跨天[0,1]',      0, 0, NULL, NULL, 0, 0,  0, 1, 1, 0, 0, 0, 0),
  ('2026-03-10', N'4卡正常',           0, 0, 0, NULL, 0, 0,  0, 1, 1, 1, 1, 0, 0),
  ('2026-03-11', N'4卡上午迟到',       1, 1, 0, NULL, 0, 5,  0, 1, 1, 1, 1, 0, 0),
  ('2026-03-12', N'4卡下午早退',       2, 0, 2, NULL, 0, 0,  5, 1, 1, 1, 1, 0, 0),
  ('2026-03-13', N'4卡缺下午下班',     3, 0, 3, NULL, 1, NULL, NULL, 1, 1, 1, 0, 0, 0),
  ('2026-03-14', N'4卡跨天[-1,0,0]',   0, 0, 0, NULL, 0, 0,  0, 1, 1, 1, 1, 0, 0),
  ('2026-03-15', N'4卡跨天[0,0,1]',    0, 0, 0, NULL, 0, 0,  0, 1, 1, 1, 1, 0, 0),
  ('2026-03-17', N'6卡正常',           0, 0, 0, 0, 0, 0,  0, 1, 1, 1, 1, 1, 1),
  ('2026-03-18', N'6卡第三段迟到',     1, 0, 0, 1, 0, 30,  0, 1, 1, 1, 1, 1, 1),
  ('2026-03-19', N'6卡缺第三段下班',   3, 0, 0, 3, 1, NULL, NULL, 1, 1, 1, 1, 1, 0);

-- 比对：实际 vs 预期（允许 attStatus 为 NVARCHAR，用 TRY_CAST 比较）
DROP TABLE IF EXISTS #assert_fail;
SELECT
  e.attdate,
  e.scenario,
  TRY_CAST(d.attStatus AS INT) AS act_attStatus,
  e.exp_attStatus,
  d.attStatus1 AS act_attStatus1,
  e.exp_attStatus1,
  d.attStatus2 AS act_attStatus2,
  e.exp_attStatus2,
  d.attStatus3 AS act_attStatus3,
  e.exp_attStatus3,
  ISNULL(d.attAbsenteeism,0) AS act_attAbsenteeism,
  e.exp_attAbsenteeism,
  d.attLate AS act_attLate,
  e.exp_attLate,
  d.attEarly AS act_attEarly,
  e.exp_attEarly
INTO #assert_fail
FROM #expected e
LEFT JOIN dbo.att_lst_DayResult d ON RTRIM(d.EMP_ID)=RTRIM(@Emp) AND d.attdate=e.attdate
WHERE
  (e.exp_attStatus IS NOT NULL AND (TRY_CAST(d.attStatus AS INT) IS NULL OR TRY_CAST(d.attStatus AS INT) <> e.exp_attStatus))
  OR (e.exp_attStatus1 IS NOT NULL AND ISNULL(d.attStatus1,-9) <> e.exp_attStatus1)
  OR (e.exp_attStatus2 IS NOT NULL AND ISNULL(d.attStatus2,-9) <> e.exp_attStatus2)
  OR (e.exp_attStatus3 IS NOT NULL AND ISNULL(d.attStatus3,-9) <> e.exp_attStatus3)
  OR (e.exp_attAbsenteeism IS NOT NULL AND ISNULL(d.attAbsenteeism,0) <> e.exp_attAbsenteeism)
  OR (e.exp_attLate IS NOT NULL AND ISNULL(d.attLate, CASE WHEN e.exp_attLate=0 THEN 0 ELSE -999 END) <> e.exp_attLate)
  OR (e.exp_attEarly IS NOT NULL AND ISNULL(d.attEarly, CASE WHEN e.exp_attEarly=0 THEN 0 ELSE -999 END) <> e.exp_attEarly)
  OR ((e.exp_hasST1=1 AND d.ST1 IS NULL) OR (e.exp_hasST1=0 AND d.ST1 IS NOT NULL))
  OR ((e.exp_hasET1=1 AND d.ET1 IS NULL) OR (e.exp_hasET1=0 AND d.ET1 IS NOT NULL))
  OR ((e.exp_hasST2=1 AND d.ST2 IS NULL) OR (e.exp_hasST2=0 AND d.ST2 IS NOT NULL))
  OR ((e.exp_hasET2=1 AND d.ET2 IS NULL) OR (e.exp_hasET2=0 AND d.ET2 IS NOT NULL))
  OR ((e.exp_hasST3=1 AND d.ST3 IS NULL) OR (e.exp_hasST3=0 AND d.ST3 IS NOT NULL))
  OR ((e.exp_hasET3=1 AND d.ET3 IS NULL) OR (e.exp_hasET3=0 AND d.ET3 IS NOT NULL))
  OR d.FID IS NULL;

DECLARE @FailCount INT = (SELECT COUNT(*) FROM #assert_fail);
DECLARE @TotalCount INT = (SELECT COUNT(*) FROM #expected);

IF @FailCount > 0
BEGIN
  PRINT '';
  PRINT '*** 测试失败 *** 失败 ' + CAST(@FailCount AS VARCHAR) + ' / ' + CAST(@TotalCount AS VARCHAR) + ' 条';
  SELECT attdate AS [失败日期], scenario AS [场景],
    act_attStatus AS [实际状态], exp_attStatus AS [预期状态],
    act_attStatus1, exp_attStatus1, act_attStatus2, exp_attStatus2, act_attStatus3, exp_attStatus3,
    act_attAbsenteeism, exp_attAbsenteeism, act_attLate, exp_attLate, act_attEarly, exp_attEarly
  FROM #assert_fail;
  RAISERROR(N'断言失败：存在 %d 条日结果与预期不符', 16, 1, @FailCount);
END
ELSE
BEGIN
  PRINT '';
  PRINT '========== 测试通过 ========== 全部 ' + CAST(@TotalCount AS VARCHAR) + ' 条用例符合预期';
END;

PRINT '';
PRINT '========== 完成 ==========';
GO
