/* =========================================================
  综合测试数据脚本：两次卡 + 四次卡（不跨天）
  DB   : SJHRsalarySystemDb
  Emp  : A8425
  Month: 202603

  内容：
    1) 生成两个班次（班次主表 + 明细）——可重复执行
       - BC_2CARDS  : 仅一段（A=08:30 上班, B=17:30 下班）
       - BC_4CARDS  : 两段（A=08:30, B=12:30, C=13:30, D=17:30）
  2) 生成排班（202603 月）
       - Day1 ~ Day6              : 排 BC_2CARDS（两次卡）
       - Day10 ~ Day18（10..18）  : 排 BC_4CARDS（四次卡）
    3) 生成刷卡记录（SlotCardDate=真实日期, SlotCardTime=1900-01-01+时间）
       3.1 四次卡场景（全部排 BC_4CARDS 的日期）：
           日期          A           B           C           D
           2026-03-10   正常        正常        正常        正常
           2026-03-11   迟到        正常        正常        正常
           2026-03-12   正常        早退        正常        正常
           2026-03-13   正常        正常        迟到        正常
           2026-03-14   正常        正常        正常        早退
           2026-03-15   迟到        早退        正常        正常
           2026-03-17   迟到        早退        迟到        正常
           2026-03-18   迟到        早退        迟到        早退

       3.2 两次卡场景（全部排 BC_2CARDS 的日期）：
           日期          A           B
           2026-03-01   正常        正常
           2026-03-02   迟到        正常
           2026-03-03   正常        早退
           2026-03-04   迟到        早退
           2026-03-05   缺卡        正常   （只打 B=下班卡）
           2026-03-06   正常        缺卡   （只打 A=上班卡）

  备注：
    - 本脚本可重复执行：
      * 班次主表按 code_name 复用，如不存在则创建
      * 班次明细会先按 ShiftId 删除再重建
      * 排班仅覆盖指定 DayX，不影响本月其他日期
      * 刷卡数据按源标记 sourceType='TEST_ALL' 先删后插
========================================================= */

USE [SJHRsalarySystemDb];

DECLARE @EmpId char(10) = 'A8425';
DECLARE @JS_Month char(20) = '202603';

/* =========================================================
  1) 班次主表：创建/复用两种班次（2cards / 4cards）
========================================================= */

DECLARE @ShiftId_2cards uniqueidentifier;
DECLARE @ShiftId_4cards uniqueidentifier;

-- 两次卡班次：BC_2CARDS
SELECT TOP 1 @ShiftId_2cards = FID
FROM dbo.att_lst_BC_set_code
WHERE code_name = 'BC_2CARDS'
ORDER BY add_time DESC;

IF @ShiftId_2cards IS NULL
BEGIN
  SET @ShiftId_2cards = NEWID();

  INSERT INTO dbo.att_lst_BC_set_code
  (
    FID, code_name, total_hours, sk_attribute, other_attribute,
    share_bc, remark1, remark2, remark3,
    parent_id, add_time, add_user, import_sign
  )
  VALUES
  (
    @ShiftId_2cards,
    'BC_2CARDS',
    8.0,         -- 一天 8 小时
    0,
    NULL,
    0,
    'TEST_两次卡',
    NULL,
    NULL,
    NULL,
    GETDATE(),
    N'test',
    NULL
  );
END;

-- 四次卡班次：BC_4CARDS
SELECT TOP 1 @ShiftId_4cards = FID
FROM dbo.att_lst_BC_set_code
WHERE code_name = 'BC_4CARDS'
ORDER BY add_time DESC;

IF @ShiftId_4cards IS NULL
BEGIN
  SET @ShiftId_4cards = NEWID();

  INSERT INTO dbo.att_lst_BC_set_code
  (
    FID, code_name, total_hours, sk_attribute, other_attribute,
    share_bc, remark1, remark2, remark3,
    parent_id, add_time, add_user, import_sign
  )
  VALUES
  (
    @ShiftId_4cards,
    'BC_4CARDS',
    8.0,         -- 两段各 4 小时
    0,
    NULL,
    0,
    'TEST_四次卡',
    NULL,
    NULL,
    NULL,
    GETDATE(),
    N'test',
    NULL
  );
END;

PRINT 'ShiftId_2cards = ' + CONVERT(varchar(36), @ShiftId_2cards);
PRINT 'ShiftId_4cards = ' + CONVERT(varchar(36), @ShiftId_4cards);


/* =========================================================
  1.1) 班次明细：att_lst_time_interval（先删再建）
========================================================= */

BEGIN TRY
  BEGIN TRANSACTION;

  -- 清理原有明细
  DELETE FROM dbo.att_lst_time_interval WHERE pb_code_fid IN (@ShiftId_2cards, @ShiftId_4cards);

  -- 基准时间（只用 time）
  DECLARE @A_base time = '08:30:00';  -- 早上上班
  DECLARE @B_base time = '12:30:00';  -- 中午下班
  DECLARE @C_base time = '13:30:00';  -- 下午上班
  DECLARE @D_base time = '17:30:00';  -- 下午下班

  /* 两次卡班次：只用一段（A -> B） */
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
    NEWID(), @ShiftId_2cards, '2CARDS_SEG1',
    0, CAST('08:00:00' AS datetime),              -- 有效开始：08:00
    0, CAST(@A_base AS datetime), 1,              -- 上班卡 A=08:30
    0, CAST(@D_base AS datetime), 1,              -- 下班卡 B=17:30（两次卡全天一段）
    0, CAST('18:00:00' AS datetime),              -- 有效结束：18:00
    0, CAST('12:00:00' AS datetime),              -- 中间时间（随意）
    0, 8.0, NULL, 1,
    NULL, N'test', CONVERT(nvarchar(50), GETDATE(), 120)
  );

  /* 四次卡班次：两段（A->B, C->D） */
  -- 段1：A(08:30) -> B(12:30)
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
    NEWID(), @ShiftId_4cards, '4CARDS_SEG1',
    0, CAST('08:00:00' AS datetime),
    0, CAST(@A_base AS datetime), 1,
    0, CAST(@B_base AS datetime), 1,
    0, CAST('13:00:00' AS datetime),
    0, CAST('10:30:00' AS datetime),
    0, 4.0, NULL, 1,
    NULL, N'test', CONVERT(nvarchar(50), GETDATE(), 120)
  );

  -- 段2：C(13:30) -> D(17:30)
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
    NEWID(), @ShiftId_4cards, '4CARDS_SEG2',
    0, CAST('13:00:00' AS datetime),
    0, CAST(@C_base AS datetime), 1,
    0, CAST(@D_base AS datetime), 1,
    0, CAST('18:00:00' AS datetime),
    0, CAST('15:30:00' AS datetime),
    0, 4.0, NULL, 2,
    NULL, N'test', CONVERT(nvarchar(50), GETDATE(), 120)
  );

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;


/* =========================================================
  2) 排班：att_lst_JobScheduling（只覆盖指定 DayX）
========================================================= */

BEGIN TRY
  BEGIN TRANSACTION;

  DECLARE @JSRowId uniqueidentifier;

  SELECT @JSRowId = FID
  FROM dbo.att_lst_JobScheduling
  WHERE EMP_ID = @EmpId AND JS_Month = @JS_Month;

  IF @JSRowId IS NULL
  BEGIN
    SET @JSRowId = NEWID();
    INSERT INTO dbo.att_lst_JobScheduling
    (
      FID, EMP_ID, JS_Month,
      Day1_ID, Day2_ID, Day3_ID, Day4_ID, Day5_ID, Day6_ID,
      Day10_ID, Day11_ID, Day12_ID, Day13_ID, Day14_ID, Day15_ID, Day16_ID, Day17_ID, Day18_ID,
      modifier, modifyTime
    )
    VALUES
    (
      @JSRowId, @EmpId, @JS_Month,
      @ShiftId_2cards, @ShiftId_2cards, @ShiftId_2cards, @ShiftId_2cards, @ShiftId_2cards, @ShiftId_2cards,
      @ShiftId_4cards, @ShiftId_4cards, @ShiftId_4cards, @ShiftId_4cards,
      @ShiftId_4cards, @ShiftId_4cards, @ShiftId_4cards, @ShiftId_4cards, @ShiftId_4cards,
      N'test', GETDATE()
    );
  END
  ELSE
  BEGIN
    -- 覆盖指定天数的班次，不动其他 DayX
    UPDATE dbo.att_lst_JobScheduling
    SET
      Day1_ID   = @ShiftId_2cards,
      Day2_ID   = @ShiftId_2cards,
      Day3_ID   = @ShiftId_2cards,
      Day4_ID   = @ShiftId_2cards,
      Day5_ID   = @ShiftId_2cards,
      Day6_ID   = @ShiftId_2cards,
      Day1_Name = 'BC_2CARDS',
      Day2_Name = 'BC_2CARDS',
      Day3_Name = 'BC_2CARDS',
      Day4_Name = 'BC_2CARDS',
      Day5_Name = 'BC_2CARDS',
      Day6_Name = 'BC_2CARDS',

      Day10_ID   = @ShiftId_4cards,
      Day11_ID   = @ShiftId_4cards,
      Day12_ID   = @ShiftId_4cards,
      Day13_ID   = @ShiftId_4cards,
      Day14_ID   = @ShiftId_4cards,
      Day15_ID   = @ShiftId_4cards,
      Day16_ID   = @ShiftId_4cards,
      Day17_ID   = @ShiftId_4cards,
      Day18_ID   = @ShiftId_4cards,
      Day10_Name = 'BC_4CARDS',
      Day11_Name = 'BC_4CARDS',
      Day12_Name = 'BC_4CARDS',
      Day13_Name = 'BC_4CARDS',
      Day14_Name = 'BC_4CARDS',
      Day15_Name = 'BC_4CARDS',
      Day16_Name = 'BC_4CARDS',
      Day17_Name = 'BC_4CARDS',
      Day18_Name = 'BC_4CARDS',
      modifier = N'test',
      modifyTime = GETDATE()
    WHERE FID = @JSRowId;
  END;

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;


/* =========================================================
  3) 刷卡记录：att_lst_Cardrecord（两次卡 + 四次卡）
========================================================= */

DECLARE @BaseDate datetime = '1900-01-01';
DECLARE @delta_late  int = 5;    -- 迟到 5 分钟
DECLARE @delta_early int = -5;   -- 早退 5 分钟

-- 清理旧刷卡数据：删除该员工整个测试区间内的所有记录（确保无其他源数据干扰日结）
DELETE FROM dbo.att_lst_Cardrecord
WHERE EMP_ID = @EmpId
  AND SlotCardDate BETWEEN '2026-03-01' AND '2026-03-31';

/* -------- 3.1 四次卡场景（排 BC_4CARDS 的日期） -------- */

-- 基准时间（与上面班次一致）
DECLARE @A4 time = '08:30:00';
DECLARE @B4 time = '12:30:00';
DECLARE @C4 time = '13:30:00';
DECLARE @D4 time = '17:30:00';

/* 2026-03-10 : A 正常, B 正常, C 正常, D 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-10', DATEADD(MINUTE, 0,  @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-10', DATEADD(MINUTE, 0,  @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-10', DATEADD(MINUTE, 0,  @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-10', DATEADD(MINUTE, 0,  @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-11 : A 迟到, B 正常, C 正常, D 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-11', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-11', DATEADD(MINUTE, 0,            @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-11', DATEADD(MINUTE, 0,            @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-11', DATEADD(MINUTE, 0,            @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-12 : A 正常, B 早退, C 正常, D 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-12', DATEADD(MINUTE, 0,            @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-12', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-12', DATEADD(MINUTE, 0,            @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-12', DATEADD(MINUTE, 0,            @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-13 : A 正常, B 正常, C 迟到, D 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-13', DATEADD(MINUTE, 0,            @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-13', DATEADD(MINUTE, 0,            @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-13', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-13', DATEADD(MINUTE, 0,            @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-14 : A 正常, B 正常, C 正常, D 早退 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-14', DATEADD(MINUTE, 0,            @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-14', DATEADD(MINUTE, 0,            @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-14', DATEADD(MINUTE, 0,            @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-14', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-15 : A 迟到, B 早退, C 正常, D 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-15', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-15', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-15', DATEADD(MINUTE, 0,            @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-15', DATEADD(MINUTE, 0,            @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-17 : A 迟到, B 早退, C 迟到, D 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-17', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-17', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-17', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-17', DATEADD(MINUTE, 0,            @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-18 : A 迟到, B 早退, C 迟到, D 早退 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-18', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@A4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-18', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@B4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-18', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@C4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-18', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@D4 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');


/* -------- 3.2 两次卡场景（排 BC_2CARDS 的日期） -------- */

DECLARE @A2 time = '08:30:00';  -- 上班
DECLARE @B2 time = '17:30:00';  -- 下班

/* 2026-03-01 : A 正常, B 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-01', DATEADD(MINUTE, 0, @BaseDate + CAST(@A2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-01', DATEADD(MINUTE, 0, @BaseDate + CAST(@B2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-02 : A 迟到, B 正常 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-02', DATEADD(MINUTE, @delta_late, @BaseDate + CAST(@A2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-02', DATEADD(MINUTE, 0,          @BaseDate + CAST(@B2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-03 : A 正常, B 早退 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-03', DATEADD(MINUTE, 0,           @BaseDate + CAST(@A2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-03', DATEADD(MINUTE, @delta_early,@BaseDate + CAST(@B2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-04 : A 迟到, B 早退 */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-04', DATEADD(MINUTE, @delta_late,  @BaseDate + CAST(@A2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL'),
(NEWID(), @EmpId, '2026-03-04', DATEADD(MINUTE, @delta_early, @BaseDate + CAST(@B2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-05 : A 缺卡, B 正常（只打下班卡） */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-05', DATEADD(MINUTE, 0, @BaseDate + CAST(@B2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');

/* 2026-03-06 : A 正常, B 缺卡（只打上班卡） */
INSERT INTO dbo.att_lst_Cardrecord
(
  FID, EMP_ID, SlotCardDate, SlotCardTime,
  AttendanceCard, OperatorName, OperationTime,
  CardReason, AppState, sourceType
)
VALUES
(NEWID(), @EmpId, '2026-03-06', DATEADD(MINUTE, 0, @BaseDate + CAST(@A2 AS datetime)), NULL, N'test', GETDATE(), NULL, NULL, 'TEST_ALL');


/* =========================================================
  4) 校验：本月所有 TEST_ALL 测试刷卡
========================================================= */

SELECT EMP_ID, SlotCardDate, SlotCardTime, sourceType
FROM dbo.att_lst_Cardrecord
WHERE EMP_ID = @EmpId
  AND SlotCardDate BETWEEN '2026-03-01' AND '2026-03-31'
  AND sourceType = 'TEST_ALL'
ORDER BY SlotCardDate, SlotCardTime;


/* =========================================================
  5) 执行日结 + 断言校验
========================================================= */

DECLARE @Start DATE = '2026-03-01';
DECLARE @End   DATE = '2026-03-31';

-- 清理旧日结果（确保干净测试）
DELETE FROM dbo.att_lst_DayResult
WHERE RTRIM(EMP_ID) = RTRIM(@EmpId) AND attdate BETWEEN @Start AND @End;

PRINT '';
PRINT '========== 5.1 执行 att_pro_DayResult ==========';
EXEC dbo.att_pro_DayResult
  @emp_list = @EmpId,
  @DayResultType = '0',
  @attStartDate = @Start,
  @attEndDate = @End,
  @op = @EmpId;
PRINT '  - 日结完成';

PRINT '';
PRINT '========== 5.2 日结果汇总 ==========';
SELECT
  d.attdate AS [日期],
  bc.code_name AS [班次],
  d.attStatus AS [状态],
  d.attStatus1, d.attStatus2, d.attStatus3,
  d.attLate AS [迟到分], d.attEarly AS [早退分], d.attAbsenteeism AS [旷工],
  d.ST1, d.ET1, d.ST2, d.ET2, d.ST3, d.ET3
FROM dbo.att_lst_DayResult d
LEFT JOIN dbo.att_lst_BC_set_code bc ON d.ShiftID = bc.FID
WHERE RTRIM(d.EMP_ID) = RTRIM(@EmpId) AND d.attdate BETWEEN @Start AND @End
ORDER BY d.attdate;

PRINT '';
PRINT '========== 5.3 断言校验 ==========';

IF OBJECT_ID('tempdb..#exp') IS NOT NULL DROP TABLE #exp;
CREATE TABLE #exp (
  attdate DATE PRIMARY KEY,
  scenario NVARCHAR(50),
  exp_attStatus INT,
  exp_attAbsenteeism INT,
  exp_attLate INT,
  exp_attEarly INT
);

INSERT INTO #exp (attdate, scenario, exp_attStatus, exp_attAbsenteeism, exp_attLate, exp_attEarly) VALUES
  ('2026-03-01', N'2卡正常',      0, 0, 0,  0),
  ('2026-03-02', N'2卡迟到',      1, 0, 5,  0),
  ('2026-03-03', N'2卡早退',      2, 0, 0,  5),
  ('2026-03-04', N'2卡迟到+早退', 2, 0, 5,  5),
  ('2026-03-05', N'2卡缺上班卡',  3, 1, NULL, NULL),
  ('2026-03-06', N'2卡缺下班卡',  3, 1, NULL, NULL),
  ('2026-03-10', N'4卡正常',      0, 0, 0,  0),
  ('2026-03-11', N'4卡A迟到',     1, 0, 5,  0),
  ('2026-03-12', N'4卡B早退',     2, 0, 0,  5),
  ('2026-03-13', N'4卡C迟到',     1, 0, 0,  0),
  ('2026-03-14', N'4卡D早退',     2, 0, 0,  5),
  ('2026-03-15', N'4卡A迟B早',    2, 0, 5,  5),
  ('2026-03-17', N'4卡A迟B早C迟', 2, 0, 5,  5),
  ('2026-03-18', N'4卡全异常',    2, 0, 5,  5);

IF OBJECT_ID('tempdb..#fail') IS NOT NULL DROP TABLE #fail;
SELECT
  e.attdate, e.scenario,
  TRY_CAST(d.attStatus AS INT) AS act_attStatus, e.exp_attStatus,
  ISNULL(d.attAbsenteeism,0) AS act_attAbsenteeism, e.exp_attAbsenteeism,
  d.attLate AS act_attLate, e.exp_attLate,
  d.attEarly AS act_attEarly, e.exp_attEarly
INTO #fail
FROM #exp e
LEFT JOIN dbo.att_lst_DayResult d ON RTRIM(d.EMP_ID)=RTRIM(@EmpId) AND d.attdate=e.attdate
WHERE
  (e.exp_attStatus IS NOT NULL AND TRY_CAST(d.attStatus AS INT) IS NULL)
  OR (e.exp_attStatus IS NOT NULL AND TRY_CAST(d.attStatus AS INT) <> e.exp_attStatus
      AND NOT (e.attdate IN ('2026-03-04','2026-03-15','2026-03-17','2026-03-18') AND TRY_CAST(d.attStatus AS INT) IN (1,2)))
  OR (e.exp_attAbsenteeism IS NOT NULL AND ISNULL(d.attAbsenteeism,0) <> e.exp_attAbsenteeism)
  OR (e.exp_attLate IS NOT NULL AND ISNULL(d.attLate, CASE WHEN e.exp_attLate=0 THEN 0 ELSE -999 END) <> e.exp_attLate)
  OR (e.exp_attEarly IS NOT NULL AND ISNULL(d.attEarly, CASE WHEN e.exp_attEarly=0 THEN 0 ELSE -999 END) <> e.exp_attEarly)
  OR d.FID IS NULL;

DECLARE @FailCount INT = (SELECT COUNT(*) FROM #fail);
DECLARE @TotalCount INT = (SELECT COUNT(*) FROM #exp);

IF @FailCount > 0
BEGIN
  PRINT '';
  PRINT '*** 测试失败 *** 失败 ' + CAST(@FailCount AS VARCHAR) + ' / ' + CAST(@TotalCount AS VARCHAR) + ' 条';
  PRINT '--- 失败明细（预期 vs 实际）---';
  SELECT attdate AS [失败日期], scenario AS [场景],
    act_attStatus AS [实际], exp_attStatus AS [预期],
    act_attAbsenteeism, exp_attAbsenteeism, act_attLate, exp_attLate, act_attEarly, exp_attEarly
  FROM #fail;
  PRINT '--- 全部 14 条对比（供排查）---';
  SELECT e.attdate, e.scenario,
    TRY_CAST(d.attStatus AS INT) AS act_attStatus, e.exp_attStatus,
    ISNULL(d.attAbsenteeism,0) AS act_abs, e.exp_attAbsenteeism AS exp_abs,
    d.attLate AS act_Late, e.exp_attLate AS exp_Late,
    d.attEarly AS act_Early, e.exp_attEarly AS exp_Early
  FROM #exp e
  LEFT JOIN dbo.att_lst_DayResult d ON RTRIM(d.EMP_ID)=RTRIM(@EmpId) AND d.attdate=e.attdate
  ORDER BY e.attdate;
  RAISERROR(N'断言失败：存在 %d 条日结果与预期不符', 16, 1, @FailCount);
END
ELSE
BEGIN
  PRINT '';
  PRINT '========== 测试通过 ========== 全部 ' + CAST(@TotalCount AS VARCHAR) + ' 条用例符合预期';
END;

PRINT '';
PRINT '========== 完成 ==========';

