/*
Data_full_scenarios_202603.sql
全场景测试：两次卡、四次卡、六次卡 + 跨天 [-1,0]、[0,1] + 正常/迟到/早退/旷工
前提：
- 已执行 alter_att_lst_DayResult_add_segment_status.sql、alter_att_lst_DayResult_add_segment3.sql
- att_lst_Cardrecord 需有 FID, EMP_ID, SlotCardDate, SlotCardTime 列
场景分配（2026-03 月）：
┌────────┬───────────────┬─────────────────────────────────────────────────────────┐
│ 日期   │ 班次          │ 场景说明                                                  │
├────────┼───────────────┼─────────────────────────────────────────────────────────┤
│ 03-01  │ 2cards [0,0]  │ 正常                                                      │
│ 03-02  │ 2cards [0,0]  │ 迟到                                                      │
│ 03-03  │ 2cards [0,0]  │ 早退                                                      │
│ 03-04  │ 2cards [0,0]  │ 缺上班卡(旷工)                                            │
│ 03-05  │ 2cards [0,0]  │ 缺下班卡(旷工)                                            │
│ 03-06  │ 2cards [0,0]  │ 迟到+早退                                                 │
│ 03-07  │ 2cards[-1,0]  │ 跨天：正常 上班03-06 22:00 下班03-07 06:00                │
│ 03-08  │ 2cards[-1,0]  │ 跨天：迟到 上班03-07 22:05 下班03-08 06:00                │
│ 03-09  │ 2cards[-1,0]  │ 跨天：早退 上班03-08 22:00 下班03-09 05:55                │
│ 03-10  │ 2cards[-1,0]  │ 跨天：缺上班卡                                            │
│ 03-11  │ 2cards[-1,0]  │ 跨天：缺下班卡                                            │
│ 03-12  │ 2cards [0,1]  │ 跨天：正常 上班03-12 22:00 下班03-13 06:00                │
│ 03-13  │ 2cards [0,1]  │ 跨天：迟到 上班03-13 22:05 下班03-14 06:00                │
│ 03-14  │ 2cards [0,1]  │ 跨天：早退 上班03-14 22:00 下班03-15 05:55                │
│ 03-15  │ 2cards [0,1]  │ 跨天：缺上班卡                                            │
│ 03-16  │ 2cards [0,1]  │ 跨天：缺下班卡                                            │
│ 03-17  │ 4cards [0,0]  │ 正常                                                      │
│ 03-18  │ 4cards [0,0]  │ 上午迟到                                                  │
│ 03-19  │ 4cards [0,0]  │ 下午早退                                                  │
│ 03-20  │ 4cards [0,0]  │ 缺下午下班卡                                              │
│ 03-21  │ 4cards[-1,0,0]│ 跨天：第1段正常                                           │
│ 03-22  │ 4cards[-1,0,0]│ 跨天：第1段迟到                                           │
│ 03-23  │ 4cards[-1,0,0]│ 跨天：第1段早退                                           │
│ 03-24  │ 4cards[-1,0,0]│ 跨天：第1段缺上班卡                                       │
│ 03-25  │ 4cards[-1,0,0]│ 跨天：第1段缺下班卡                                       │
│ 03-26  │ 4cards[0,0,1] │ 跨天：第2段正常                                           │
│ 03-27  │ 4cards[0,0,1] │ 跨天：第2段迟到                                           │
│ 03-28  │ 4cards[0,0,1] │ 跨天：第2段早退                                           │
│ 03-29  │ 4cards[0,0,1] │ 跨天：第2段缺下班卡                                       │
│ 03-30  │ 6cards [0,0,0]│ 正常六次卡                                                │
│ 03-31  │ 6cards [0,0,0]│ 第三段迟到                                                │
│ 04-01  │ 6cards[-1,0,0]│ 跨天：第1段正常 段1:03-31 22:00-04-01 06:00               │
│ 04-02  │ 6cards[-1,0,0]│ 跨天：第1段迟到 上班04-01 22:05                           │
│ 04-03  │ 6cards[0,0,1] │ 跨天：第3段正常 段3:04-03 18:00-04-04 02:00               │
│ 04-04  │ 6cards[0,0,1] │ 跨天：第3段迟到 上班04-04 18:30                           │
└────────┴───────────────┴─────────────────────────────────────────────────────────┘
注：03-31 简化为第三段迟到。04 月为六次卡跨天补充场景。
关于「迟到+早退」（如 03-06）：
存储过程按顺序执行迟到、早退的 UPDATE，后执行的早退会覆盖 attStatus/attStatus1，
故列表只显示「早退」。attLate、attEarly 会分别保留，校验会同时断言两者（5,5）。
*/
USE [SJHRsalarySystemDb] GO SET NOCOUNT ON;
DECLARE @Emp       CHAR(10) = 'A8425';
DECLARE @JS_Month  CHAR(20) = '202603';
DECLARE @JS_Month4 CHAR(20) = '202604';
DECLARE @Start     DATE     = '2026-03-01';
DECLARE @End       DATE     = '2026-04-12';
-- 班次ID
DECLARE @S2_00   UNIQUEIDENTIFIER;
DECLARE @S2_m10  UNIQUEIDENTIFIER;
DECLARE @S2_p01  UNIQUEIDENTIFIER;
DECLARE @S4_00   UNIQUEIDENTIFIER;
DECLARE @S4_m100 UNIQUEIDENTIFIER;
DECLARE @S4_001  UNIQUEIDENTIFIER;
DECLARE @S6_000  UNIQUEIDENTIFIER;
DECLARE @S6_m100 UNIQUEIDENTIFIER;
DECLARE @S6_001  UNIQUEIDENTIFIER;
DECLARE @S2_thr  UNIQUEIDENTIFIER;
DECLARE @S_OT    UNIQUEIDENTIFIER;
/* ===== 第1章：创建/获取班次 =====
  目标：
  - 保证测试脚本可重复执行（不存在则创建，存在则复用）；
  - 覆盖 2卡/4卡/6卡 与跨天组合（-1,0 / 0,1 / -1,0,0 / 0,0,1）。
*/
PRINT '========== 1. 创建/获取班次 ==========';
-- 两次卡 [0,0] 08:30-17:30
SELECT
    @S2_00 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_2CARDS';
IF @S2_00 IS NULL
BEGIN SET @S2_00 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S2_00     ,
            'BC_2CARDS',
            8.0        ,
            0          ,
            0          ,
            'TEST_两次卡' ,
            GETDATE()  ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S2_00               ,
            '2CARDS_SEG1'        ,
            0                    ,
            '1900-01-01 08:00:00',
            0                    ,
            '1900-01-01 08:30:00',
            1                    ,
            0                    ,
            '1900-01-01 17:30:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            1
        )
    ;
END
-- 两次卡 [-1,0] 夜班：前日22:00-当日06:00
SELECT
    @S2_m10 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_2CARDS_M10';
IF @S2_m10 IS NULL
BEGIN SET @S2_m10 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S2_m10           ,
            'BC_2CARDS_M10'   ,
            8.0               ,
            0                 ,
            0                 ,
            'TEST_两次卡跨天[-1,0]',
            GETDATE()         ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S2_m10              ,
            '2M10_SEG1'          ,
            -1                   ,
            '1900-01-01 22:00:00',
            -1                   ,
            '1900-01-01 22:00:00',
            1                    ,
            0                    ,
            '1900-01-01 06:00:00',
            1                    ,
            0                    ,
            '1900-01-01 06:00:00',
            1
        )
    ;
END
-- 两次卡 [0,1] 夜班：当日22:00-次日06:00
SELECT
    @S2_p01 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_2CARDS_P01';
IF @S2_p01 IS NULL
BEGIN SET @S2_p01 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S2_p01          ,
            'BC_2CARDS_P01'  ,
            8.0              ,
            0                ,
            0                ,
            'TEST_两次卡跨天[0,1]',
            GETDATE()        ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S2_p01              ,
            '2P01_SEG1'          ,
            0                    ,
            '1900-01-01 22:00:00',
            0                    ,
            '1900-01-01 22:00:00',
            1                    ,
            1                    ,
            '1900-01-01 06:00:00',
            1                    ,
            1                    ,
            '1900-01-01 06:00:00',
            1
        )
    ;
END
-- 四次卡 [0,0]
SELECT
    @S4_00 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_4CARDS';
IF @S4_00 IS NULL
BEGIN SET @S4_00 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S4_00     ,
            'BC_4CARDS',
            8.0        ,
            0          ,
            0          ,
            'TEST_四次卡' ,
            GETDATE()  ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S4_00               ,
            '4CARDS_SEG1'        ,
            0                    ,
            '1900-01-01 08:00:00',
            0                    ,
            '1900-01-01 08:30:00',
            1                    ,
            0                    ,
            '1900-01-01 12:30:00',
            1                    ,
            0                    ,
            '1900-01-01 13:00:00',
            1
        )
        ,
        (
            NEWID()              ,
            @S4_00               ,
            '4CARDS_SEG2'        ,
            0                    ,
            '1900-01-01 13:00:00',
            0                    ,
            '1900-01-01 13:30:00',
            1                    ,
            0                    ,
            '1900-01-01 17:30:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            2
        )
    ;
END
-- 四次卡 [-1,0,0] 第1段跨天
SELECT
    @S4_m100 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_4CARDS_M100';
IF @S4_m100 IS NULL
BEGIN SET @S4_m100 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S4_m100          ,
            'BC_4CARDS_M100'  ,
            8.0               ,
            0                 ,
            0                 ,
            'TEST_四次卡[-1,0,0]',
            GETDATE()         ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S4_m100             ,
            '4M100_S1'           ,
            -1                   ,
            '1900-01-01 22:00:00',
            -1                   ,
            '1900-01-01 22:00:00',
            1                    ,
            0                    ,
            '1900-01-01 06:00:00',
            1                    ,
            0                    ,
            '1900-01-01 06:00:00',
            1
        )
        ,
        (
            NEWID()              ,
            @S4_m100             ,
            '4M100_S2'           ,
            0                    ,
            '1900-01-01 13:00:00',
            0                    ,
            '1900-01-01 13:30:00',
            1                    ,
            0                    ,
            '1900-01-01 17:30:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            2
        )
    ;
END
-- 四次卡 [0,0,1] 第2段跨天
SELECT
    @S4_001 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_4CARDS_001';
IF @S4_001 IS NULL
BEGIN SET @S4_001 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S4_001          ,
            'BC_4CARDS_001'  ,
            8.0              ,
            0                ,
            0                ,
            'TEST_四次卡[0,0,1]',
            GETDATE()        ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S4_001              ,
            '4001_S1'            ,
            0                    ,
            '1900-01-01 08:00:00',
            0                    ,
            '1900-01-01 08:30:00',
            1                    ,
            0                    ,
            '1900-01-01 12:30:00',
            1                    ,
            0                    ,
            '1900-01-01 13:00:00',
            1
        )
        ,
        (
            NEWID()              ,
            @S4_001              ,
            '4001_S2'            ,
            0                    ,
            '1900-01-01 18:00:00',
            0                    ,
            '1900-01-01 18:00:00',
            1                    ,
            1                    ,
            '1900-01-01 02:00:00',
            1                    ,
            1                    ,
            '1900-01-01 02:00:00',
            2
        )
    ;
END
-- 六次卡 [0,0,0]
SELECT
    @S6_000 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_6CARDS';
IF @S6_000 IS NULL
BEGIN SET @S6_000 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S6_000    ,
            'BC_6CARDS',
            11.0       ,
            0          ,
            0          ,
            'TEST_六次卡' ,
            GETDATE()  ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S6_000              ,
            '6CARDS_S1'          ,
            0                    ,
            '1900-01-01 08:00:00',
            0                    ,
            '1900-01-01 08:30:00',
            1                    ,
            0                    ,
            '1900-01-01 12:00:00',
            1                    ,
            0                    ,
            '1900-01-01 13:00:00',
            1
        )
        ,
        (
            NEWID()              ,
            @S6_000              ,
            '6CARDS_S2'          ,
            0                    ,
            '1900-01-01 13:00:00',
            0                    ,
            '1900-01-01 13:00:00',
            1                    ,
            0                    ,
            '1900-01-01 17:00:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            2
        )
        ,
        (
            NEWID()              ,
            @S6_000              ,
            '6CARDS_S3'          ,
            0                    ,
            '1900-01-01 18:00:00',
            0                    ,
            '1900-01-01 18:00:00',
            1                    ,
            0                    ,
            '1900-01-01 21:00:00',
            1                    ,
            0                    ,
            '1900-01-01 22:00:00',
            3
        )
    ;
END
-- 六次卡 [-1,0,0] 第1段跨天：段1 前日22:00-当日06:00，段2 13:00-17:00，段3 18:00-21:00
SELECT
    @S6_m100 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_6CARDS_M100';
IF @S6_m100 IS NULL
BEGIN SET @S6_m100 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S6_m100          ,
            'BC_6CARDS_M100'  ,
            11.0              ,
            0                 ,
            0                 ,
            'TEST_六次卡[-1,0,0]',
            GETDATE()         ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S6_m100             ,
            '6M100_S1'           ,
            -1                   ,
            '1900-01-01 22:00:00',
            -1                   ,
            '1900-01-01 22:00:00',
            1                    ,
            0                    ,
            '1900-01-01 06:00:00',
            1                    ,
            0                    ,
            '1900-01-01 06:00:00',
            1
        )
        ,
        (
            NEWID()              ,
            @S6_m100             ,
            '6M100_S2'           ,
            0                    ,
            '1900-01-01 12:00:00',
            0                    ,
            '1900-01-01 13:00:00',
            1                    ,
            0                    ,
            '1900-01-01 17:00:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            2
        )
        ,
        (
            NEWID()              ,
            @S6_m100             ,
            '6M100_S3'           ,
            0                    ,
            '1900-01-01 18:00:00',
            0                    ,
            '1900-01-01 18:00:00',
            1                    ,
            0                    ,
            '1900-01-01 21:00:00',
            1                    ,
            0                    ,
            '1900-01-01 22:00:00',
            3
        )
    ;
END
-- 六次卡 [0,0,1] 第3段跨天：段1 08:30-12:00，段2 13:00-17:00，段3 当日18:00-次日02:00
SELECT
    @S6_001 = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_6CARDS_001';
IF @S6_001 IS NULL
BEGIN SET @S6_001 = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S6_001          ,
            'BC_6CARDS_001'  ,
            11.0             ,
            0                ,
            0                ,
            'TEST_六次卡[0,0,1]',
            GETDATE()        ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S6_001              ,
            '6001_S1'            ,
            0                    ,
            '1900-01-01 08:00:00',
            0                    ,
            '1900-01-01 08:30:00',
            1                    ,
            0                    ,
            '1900-01-01 12:00:00',
            1                    ,
            0                    ,
            '1900-01-01 13:00:00',
            1
        )
        ,
        (
            NEWID()              ,
            @S6_001              ,
            '6001_S2'            ,
            0                    ,
            '1900-01-01 13:00:00',
            0                    ,
            '1900-01-01 13:00:00',
            1                    ,
            0                    ,
            '1900-01-01 17:00:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            2
        )
        ,
        (
            NEWID()              ,
            @S6_001              ,
            '6001_S3'            ,
            0                    ,
            '1900-01-01 18:00:00',
            0                    ,
            '1900-01-01 18:00:00',
            1                    ,
            1                    ,
            '1900-01-01 02:00:00',
            1                    ,
            1                    ,
            '1900-01-01 02:00:00',
            3
        )
    ;
END
-- 两次卡阈值专项班次 [0,0]：用于迟到/早退/旷工阈值触发与不触发验证
SELECT
    @S2_thr = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_2CARDS_THR';
IF @S2_thr IS NULL
BEGIN SET @S2_thr = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S2_thr        ,
            'BC_2CARDS_THR',
            8.0            ,
            0              ,
            0              ,
            'TEST_阈值专项_两次卡',
            GETDATE()      ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S2_thr              ,
            '2THR_SEG1'          ,
            0                    ,
            '1900-01-01 08:00:00',
            0                    ,
            '1900-01-01 08:30:00',
            1                    ,
            0                    ,
            '1900-01-01 17:30:00',
            1                    ,
            0                    ,
            '1900-01-01 18:00:00',
            1
        )
    ;
END
-- 加班阈值专项班次：不参与迟到/早退判定，仅用于 overtime_start_minutes 验证
SELECT
    @S_OT = FID
FROM
    dbo.att_lst_BC_set_code
WHERE
    code_name = 'BC_OT_THR';
IF @S_OT IS NULL
BEGIN SET @S_OT = NEWID();
    INSERT INTO dbo.att_lst_BC_set_code
        (
            FID         ,
            code_name   ,
            total_hours ,
            sk_attribute,
            share_bc    ,
            remark1     ,
            add_time    ,
            add_user
        )
    VALUES
        (
            @S_OT         ,
            'BC_OT_THR'   ,
            0.0           ,
            0             ,
            0             ,
            'TEST_阈值专项_加班',
            GETDATE()     ,
            'test'
        )
    ;
    INSERT INTO dbo.att_lst_time_interval
        (
            FID                 ,
            pb_code_fid         ,
            name                ,
            valid_begin_time_tag,
            valid_begin_time    ,
            begin_time_tag      ,
            begin_time          ,
            begin_time_slot_card,
            end_time_tag        ,
            end_time            ,
            end_time_slot_card  ,
            valid_end_time_tag  ,
            valid_end_time      ,
            sec_num
        )
    VALUES
        (
            NEWID()              ,
            @S_OT                ,
            'OTTHR_SEG1'         ,
            0                    ,
            '1900-01-01 00:00:00',
            0                    ,
            '1900-01-01 00:00:00',
            0                    ,
            0                    ,
            '1900-01-01 23:59:59',
            0                    ,
            0                    ,
            '1900-01-01 23:59:59',
            1
        )
    ;
END
-- 班次阈值配置（新字段）：默认不改变既有用例；专项班次单独配置
UPDATE
    dbo.att_lst_BC_set_code
SET
    late_allow_minutes =
    CASE
        WHEN
            code_name='BC_2CARDS_THR'
        THEN 5
        ELSE 0
    END,
    early_allow_minutes =
    CASE
        WHEN
            code_name='BC_2CARDS_THR'
        THEN 5
        ELSE 0
    END,
    absenteeism_start_minutes =
    CASE
        WHEN
            code_name='BC_2CARDS_THR'
        THEN 20
        ELSE 60
    END,
    overtime_start_minutes =
    CASE
        WHEN
            code_name='BC_OT_THR'
        THEN 120
        ELSE 0
    END
WHERE
    code_name IN ('BC_2CARDS',
                  'BC_2CARDS_M10',
                  'BC_2CARDS_P01',
                  'BC_4CARDS',
                  'BC_4CARDS_M100',
                  'BC_4CARDS_001',
                  'BC_6CARDS',
                  'BC_6CARDS_M100',
                  'BC_6CARDS_001',
                  'BC_2CARDS_THR',
                  'BC_OT_THR');
-- 为避免历史脏数据干扰，专项场景班次时间段每次重建
DELETE
FROM
    dbo.att_lst_time_interval
WHERE
    pb_code_fid IN (@S2_m10,
                    @S6_m100,
                    @S2_thr,
                    @S_OT);
INSERT INTO dbo.att_lst_time_interval
    (
        FID                 ,
        pb_code_fid         ,
        name                ,
        valid_begin_time_tag,
        valid_begin_time    ,
        begin_time_tag      ,
        begin_time          ,
        begin_time_slot_card,
        end_time_tag        ,
        end_time            ,
        end_time_slot_card  ,
        valid_end_time_tag  ,
        valid_end_time      ,
        sec_num
    )
VALUES
    (
        NEWID()              ,
        @S2_m10              ,
        '2M10_SEG1'          ,
        -1                   ,
        '1900-01-01 22:00:00',
        -1                   ,
        '1900-01-01 22:00:00',
        1                    ,
        0                    ,
        '1900-01-01 06:00:00',
        1                    ,
        0                    ,
        '1900-01-01 06:00:00',
        1
    )
    ,
    (
        NEWID()              ,
        @S2_thr              ,
        '2THR_SEG1'          ,
        0                    ,
        '1900-01-01 08:00:00',
        0                    ,
        '1900-01-01 08:30:00',
        1                    ,
        0                    ,
        '1900-01-01 17:30:00',
        1                    ,
        0                    ,
        '1900-01-01 18:00:00',
        1
    )
    ,
    (
        NEWID()              ,
        @S_OT                ,
        'OTTHR_SEG1'         ,
        0                    ,
        '1900-01-01 00:00:00',
        0                    ,
        '1900-01-01 00:00:00',
        0                    ,
        0                    ,
        '1900-01-01 23:59:59',
        0                    ,
        0                    ,
        '1900-01-01 23:59:59',
        1
    )
;
INSERT INTO dbo.att_lst_time_interval
    (
        FID                 ,
        pb_code_fid         ,
        name                ,
        valid_begin_time_tag,
        valid_begin_time    ,
        begin_time_tag      ,
        begin_time          ,
        begin_time_slot_card,
        end_time_tag        ,
        end_time            ,
        end_time_slot_card  ,
        valid_end_time_tag  ,
        valid_end_time      ,
        sec_num
    )
VALUES
    (
        NEWID()              ,
        @S6_m100             ,
        '6M100_S1'           ,
        -1                   ,
        '1900-01-01 22:00:00',
        -1                   ,
        '1900-01-01 22:00:00',
        1                    ,
        0                    ,
        '1900-01-01 06:00:00',
        1                    ,
        0                    ,
        '1900-01-01 06:00:00',
        1
    )
    ,
    (
        NEWID()              ,
        @S6_m100             ,
        '6M100_S2'           ,
        0                    ,
        '1900-01-01 12:00:00',
        0                    ,
        '1900-01-01 13:00:00',
        1                    ,
        0                    ,
        '1900-01-01 17:00:00',
        1                    ,
        0                    ,
        '1900-01-01 18:00:00',
        2
    )
    ,
    (
        NEWID()              ,
        @S6_m100             ,
        '6M100_S3'           ,
        0                    ,
        '1900-01-01 18:00:00',
        0                    ,
        '1900-01-01 18:00:00',
        1                    ,
        0                    ,
        '1900-01-01 21:00:00',
        1                    ,
        0                    ,
        '1900-01-01 22:00:00',
        3
    )
;
PRINT '  - 班次就绪';
PRINT '';
/* ===== 第2章：排班 =====
  目标：
  - 将 2026-03 与 2026-04 的测试日期映射到指定班次；
  - 通过 DayX_ID/DayX_Name 固化测试窗口，避免受历史排班干扰。
*/
PRINT '========== 2. 排班 ==========';
DECLARE @JSRowId UNIQUEIDENTIFIER;
SELECT
    @JSRowId = FID
FROM
    dbo.att_lst_JobScheduling
WHERE
    RTRIM(EMP_ID) = RTRIM(@Emp)
AND JS_Month      = @JS_Month;
IF @JSRowId IS NULL
BEGIN SET @JSRowId = NEWID();
    INSERT INTO dbo.att_lst_JobScheduling
        (
            FID     ,
            EMP_ID  ,
            JS_Month,
            modifier,
            modifyTime
        )
    VALUES
        (
            @JSRowId ,
            @Emp     ,
            @JS_Month,
            N'test'  ,
            GETDATE()
        )
    ;
END
-- 按日期分配班次：Day1~Day31
UPDATE
    dbo.att_lst_JobScheduling
SET
    Day1_ID   =@S2_00          ,
    Day2_ID   =@S2_00          ,
    Day3_ID   =@S2_00          ,
    Day4_ID   =@S2_00          ,
    Day5_ID   =@S2_00          ,
    Day6_ID   =@S2_00          ,
    Day7_ID   =@S2_m10         ,
    Day8_ID   =@S2_m10         ,
    Day9_ID   =@S2_m10         ,
    Day10_ID  =@S2_m10         ,
    Day11_ID  =@S2_m10         ,
    Day12_ID  =@S2_p01         ,
    Day13_ID  =@S2_p01         ,
    Day14_ID  =@S2_p01         ,
    Day15_ID  =@S2_p01         ,
    Day16_ID  =@S2_p01         ,
    Day17_ID  =@S4_00          ,
    Day18_ID  =@S4_00          ,
    Day19_ID  =@S4_00          ,
    Day20_ID  =@S4_00          ,
    Day21_ID  =@S4_m100        ,
    Day22_ID  =@S4_m100        ,
    Day23_ID  =@S4_m100        ,
    Day24_ID  =@S4_m100        ,
    Day25_ID  =@S4_m100        ,
    Day26_ID  =@S4_001         ,
    Day27_ID  =@S4_001         ,
    Day28_ID  =@S4_001         ,
    Day29_ID  =@S4_001         ,
    Day30_ID  =@S6_000         ,
    Day31_ID  =@S6_000         ,
    Day1_Name ='BC_2CARDS'     ,
    Day2_Name ='BC_2CARDS'     ,
    Day3_Name ='BC_2CARDS'     ,
    Day4_Name ='BC_2CARDS'     ,
    Day5_Name ='BC_2CARDS'     ,
    Day6_Name ='BC_2CARDS'     ,
    Day7_Name ='BC_2CARDS_M10' ,
    Day8_Name ='BC_2CARDS_M10' ,
    Day9_Name ='BC_2CARDS_M10' ,
    Day10_Name='BC_2CARDS_M10' ,
    Day11_Name='BC_2CARDS_M10' ,
    Day12_Name='BC_2CARDS_P01' ,
    Day13_Name='BC_2CARDS_P01' ,
    Day14_Name='BC_2CARDS_P01' ,
    Day15_Name='BC_2CARDS_P01' ,
    Day16_Name='BC_2CARDS_P01' ,
    Day17_Name='BC_4CARDS'     ,
    Day18_Name='BC_4CARDS'     ,
    Day19_Name='BC_4CARDS'     ,
    Day20_Name='BC_4CARDS'     ,
    Day21_Name='BC_4CARDS_M100',
    Day22_Name='BC_4CARDS_M100',
    Day23_Name='BC_4CARDS_M100',
    Day24_Name='BC_4CARDS_M100',
    Day25_Name='BC_4CARDS_M100',
    Day26_Name='BC_4CARDS_001' ,
    Day27_Name='BC_4CARDS_001' ,
    Day28_Name='BC_4CARDS_001' ,
    Day29_Name='BC_4CARDS_001' ,
    Day30_Name='BC_6CARDS'     ,
    Day31_Name='BC_6CARDS'     ,
    modifier  =N'test'         ,
    modifyTime=GETDATE()
WHERE
    FID = @JSRowId;
-- 202604 排班：04-01/02 BC_6CARDS_M100，04-03/04 BC_6CARDS_001
DECLARE @JSRowId4 UNIQUEIDENTIFIER;
SELECT
    @JSRowId4 = FID
FROM
    dbo.att_lst_JobScheduling
WHERE
    RTRIM(EMP_ID) = RTRIM(@Emp)
AND JS_Month      = @JS_Month4;
IF @JSRowId4 IS NULL
BEGIN SET @JSRowId4 = NEWID();
    INSERT INTO dbo.att_lst_JobScheduling
        (
            FID     ,
            EMP_ID  ,
            JS_Month,
            modifier,
            modifyTime
        )
    VALUES
        (
            @JSRowId4 ,
            @Emp      ,
            @JS_Month4,
            N'test'   ,
            GETDATE()
        )
    ;
END
UPDATE
    dbo.att_lst_JobScheduling
SET
    Day1_ID   =@S6_m100        ,
    Day2_ID   =@S6_m100        ,
    Day3_ID   =@S6_001         ,
    Day4_ID   =@S6_001         ,
    Day5_ID   =@S2_thr         ,
    Day6_ID   =@S2_thr         ,
    Day7_ID   =@S2_thr         ,
    Day8_ID   =@S2_thr         ,
    Day9_ID   =@S2_thr         ,
    Day10_ID  =@S2_thr         ,
    Day11_ID  =@S_OT           ,
    Day12_ID  =@S_OT           ,
    Day1_Name ='BC_6CARDS_M100',
    Day2_Name ='BC_6CARDS_M100',
    Day3_Name ='BC_6CARDS_001' ,
    Day4_Name ='BC_6CARDS_001' ,
    Day5_Name ='BC_2CARDS_THR' ,
    Day6_Name ='BC_2CARDS_THR' ,
    Day7_Name ='BC_2CARDS_THR' ,
    Day8_Name ='BC_2CARDS_THR' ,
    Day9_Name ='BC_2CARDS_THR' ,
    Day10_Name='BC_2CARDS_THR' ,
    Day11_Name='BC_OT_THR'     ,
    Day12_Name='BC_OT_THR'     ,
    modifier  =N'test'         ,
    modifyTime=GETDATE()
WHERE
    FID = @JSRowId4;
PRINT '  - 排班已更新（含202604）';
PRINT '';
/* ===== 第3章：清理旧数据 =====
  目标：
  - 删除同员工、同日期范围内历史刷卡/加班/日结果；
  - 保障断言结果仅由本次脚本插入的数据决定。
*/
PRINT '========== 3. 清理旧数据 ==========';
DELETE
FROM
    dbo.att_lst_Cardrecord
WHERE
    RTRIM(EMP_ID)=RTRIM(@Emp)
AND SlotCardDate BETWEEN @Start AND @End;
DELETE
FROM
    dbo.att_lst_OverTime
WHERE
    RTRIM(EMP_ID)=RTRIM(@Emp)
AND fDate BETWEEN @Start AND @End;
DELETE
FROM
    dbo.att_lst_DayResult
WHERE
    RTRIM(EMP_ID)=RTRIM(@Emp)
AND attdate BETWEEN @Start AND @End;
PRINT '';
/* ===== 第4章：插入刷卡数据 =====
  目标：
  - 构造正常/迟到/早退/漏打卡/旷工/加班阈值场景；
  - 同时覆盖跨天与多段班次（含 6 次卡新增跨天样例）。
*/
PRINT '========== 4. 插入刷卡数据 ==========';
-- 两次卡 [0,0] 03-01~03-06
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-01',
        '2026-03-01 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-01',
        '2026-03-01 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-02',
        '2026-03-02 08:35:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-02',
        '2026-03-02 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-03',
        '2026-03-03 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-03',
        '2026-03-03 17:25:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-04',
        '2026-03-04 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-05',
        '2026-03-05 08:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-06',
        '2026-03-06 08:35:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-06',
        '2026-03-06 17:25:00'
    )
;
-- 两次卡 [-1,0] 03-07~03-11
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-06',
        '2026-03-06 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-07',
        '2026-03-07 06:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-07',
        '2026-03-07 22:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-08',
        '2026-03-08 06:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-08',
        '2026-03-08 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-09',
        '2026-03-09 05:55:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-10',
        '2026-03-10 06:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-10',
        '2026-03-10 22:00:00'
    )
;
-- 两次卡 [0,1] 03-12~03-16
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-12',
        '2026-03-12 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-13',
        '2026-03-13 06:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-13',
        '2026-03-13 22:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-14',
        '2026-03-14 06:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-14',
        '2026-03-14 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-15',
        '2026-03-15 05:55:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-16',
        '2026-03-16 06:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-16',
        '2026-03-16 22:00:00'
    )
;
-- 四次卡 [0,0] 03-17~03-20
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-17',
        '2026-03-17 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-17',
        '2026-03-17 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-17',
        '2026-03-17 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-17',
        '2026-03-17 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-18',
        '2026-03-18 08:35:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-18',
        '2026-03-18 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-18',
        '2026-03-18 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-18',
        '2026-03-18 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-19',
        '2026-03-19 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-19',
        '2026-03-19 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-19',
        '2026-03-19 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-19',
        '2026-03-19 17:25:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-20',
        '2026-03-20 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-20',
        '2026-03-20 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-20',
        '2026-03-20 13:30:00'
    )
;
-- 四次卡 [-1,0,0] 03-21~03-25
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-20',
        '2026-03-20 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-21',
        '2026-03-21 06:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-21',
        '2026-03-21 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-21',
        '2026-03-21 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-21',
        '2026-03-21 22:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-22',
        '2026-03-22 06:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-22',
        '2026-03-22 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-22',
        '2026-03-22 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-22',
        '2026-03-22 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-23',
        '2026-03-23 05:55:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-23',
        '2026-03-23 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-23',
        '2026-03-23 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-24',
        '2026-03-24 06:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-24',
        '2026-03-24 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-24',
        '2026-03-24 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-24',
        '2026-03-24 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-24',
        '2026-03-24 17:30:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-24',
        '2026-03-24 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-25',
        '2026-03-25 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-25',
        '2026-03-25 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-25',
        '2026-03-25 13:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-25',
        '2026-03-25 17:30:00'
    )
;
-- 四次卡 [0,0,1] 03-26~03-29
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-26',
        '2026-03-26 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-26',
        '2026-03-26 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-26',
        '2026-03-26 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-27',
        '2026-03-27 02:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-27',
        '2026-03-27 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-27',
        '2026-03-27 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-27',
        '2026-03-27 18:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-28',
        '2026-03-28 02:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-28',
        '2026-03-28 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-28',
        '2026-03-28 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-28',
        '2026-03-28 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-29',
        '2026-03-29 01:55:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-29',
        '2026-03-29 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-29',
        '2026-03-29 12:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-29',
        '2026-03-29 18:00:00'
    )
;
-- 六次卡 03-30~03-31（valid窗口 Seg1:08-13 Seg2:13-18 Seg3:18-22；正常需准点 08:30/12:00/13:00/17:00/18:00/21:00）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-30',
        '2026-03-30 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-30',
        '2026-03-30 12:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-30',
        '2026-03-30 13:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-30',
        '2026-03-30 17:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-30',
        '2026-03-30 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-30',
        '2026-03-30 21:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 08:15:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 12:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 13:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 17:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 18:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 21:05:00'
    )
;
-- 六次卡 [-1,0,0] 04-01 第1段跨天正常 / 04-02 第1段迟到
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-03-31',
        '2026-03-31 22:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-01',
        '2026-04-01 06:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-01',
        '2026-04-01 13:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-01',
        '2026-04-01 17:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-01',
        '2026-04-01 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-01',
        '2026-04-01 21:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-01',
        '2026-04-01 22:05:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-02',
        '2026-04-02 06:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-02',
        '2026-04-02 13:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-02',
        '2026-04-02 17:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-02',
        '2026-04-02 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-02',
        '2026-04-02 21:00:00'
    )
;
-- 六次卡 [0,0,1] 04-03 第3段跨天正常 / 04-04 第3段迟到
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-03',
        '2026-04-03 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-03',
        '2026-04-03 12:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-03',
        '2026-04-03 13:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-03',
        '2026-04-03 17:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-03',
        '2026-04-03 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-04',
        '2026-04-04 02:00:00'
    )
;
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-04',
        '2026-04-04 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-04',
        '2026-04-04 12:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-04',
        '2026-04-04 13:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-04',
        '2026-04-04 17:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-04',
        '2026-04-04 18:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-05',
        '2026-04-05 02:00:00'
    )
;
-- 阈值专项（BC_2CARDS_THR: 迟到允许5分、早退允许5分、旷工阈值20分）
-- 04-05 迟到=5（不触发）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-05',
        '2026-04-05 08:35:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-05',
        '2026-04-05 17:30:00'
    )
;
-- 04-06 迟到=6（触发）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-06',
        '2026-04-06 08:36:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-06',
        '2026-04-06 17:30:00'
    )
;
-- 04-07 早退=5（不触发）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-07',
        '2026-04-07 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-07',
        '2026-04-07 17:25:00'
    )
;
-- 04-08 早退=6（触发）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-08',
        '2026-04-08 08:30:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-08',
        '2026-04-08 17:24:00'
    )
;
-- 04-09 迟到11 + 早退10 = 21（触发旷工）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-09',
        '2026-04-09 08:41:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-09',
        '2026-04-09 17:20:00'
    )
;
-- 04-10 迟到10 + 早退10 = 20（不触发旷工）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-10',
        '2026-04-10 08:40:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-10',
        '2026-04-10 17:20:00'
    )
;
-- 加班阈值专项（BC_OT_THR: 加班起始120分）
-- 04-11 110分（不触发）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-11',
        '2026-04-11 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-11',
        '2026-04-11 19:50:00'
    )
;
INSERT INTO dbo.att_lst_OverTime
    (
        FID          ,
        EMP_ID       ,
        fType        ,
        fDate        ,
        fStartTime   ,
        fEndTime     ,
        overtime     ,
        fReason      ,
        Remark       ,
        ApproveStatus,
        OperatorName ,
        OperatorTime
    )
VALUES
    (
        NEWID()              ,
        @Emp                 ,
        N'日常加班'              ,
        '2026-04-11'         ,
        '2026-04-11 18:00:00',
        '2026-04-11 19:50:00',
        1.8                  ,
        N'阈值专项_不触发'          ,
        N'test'              ,
        N'1'                 ,
        N'test'              ,
        GETDATE()
    )
;
-- 04-12 130分（触发）
INSERT INTO dbo.att_lst_Cardrecord
    (
        FID         ,
        EMP_ID      ,
        SlotCardDate,
        SlotCardTime
    )
VALUES
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-12',
        '2026-04-12 18:00:00'
    )
    ,
    (
        NEWID()     ,
        @Emp        ,
        '2026-04-12',
        '2026-04-12 20:10:00'
    )
;
INSERT INTO dbo.att_lst_OverTime
    (
        FID          ,
        EMP_ID       ,
        fType        ,
        fDate        ,
        fStartTime   ,
        fEndTime     ,
        overtime     ,
        fReason      ,
        Remark       ,
        ApproveStatus,
        OperatorName ,
        OperatorTime
    )
VALUES
    (
        NEWID()              ,
        @Emp                 ,
        N'日常加班'              ,
        '2026-04-12'         ,
        '2026-04-12 18:00:00',
        '2026-04-12 20:10:00',
        2.2                  ,
        N'阈值专项_触发'           ,
        N'test'              ,
        N'1'                 ,
        N'test'              ,
        GETDATE()
    )
;
PRINT '  - 刷卡数据已插入';
PRINT '';
/* ===== 第5章：执行日结 =====
  关键点：
  - att_pro_DayResult 单次按“起始月”处理，跨月需拆分调用；
  - 这里按 03 月与 04 月分开执行，避免 04 月数据被截断。
*/
PRINT '========== 5. 执行 att_pro_DayResult ==========';
-- 存储过程按单月处理：起止月份不同时会截断到起始月最后一天，故分两月分别调用
EXEC dbo.att_pro_DayResult @emp_list=@Emp        , @DayResultType='0', @attStartDate='2026-03-01', @attEndDate='2026-03-31', @op=@Emp;
EXEC dbo.att_pro_DayResult @emp_list=@Emp        ,
@DayResultType                      ='0'         ,
@attStartDate                       ='2026-04-01',
@attEndDate                         ='2026-04-12',
@op                                 =@Emp;
PRINT '  - 日结完成（03月+04月）';
PRINT '';
/* ===== 第6章：结果汇总 =====
  目标：
  - 直接查看日结果关键字段（总状态/段状态/迟到早退/刷卡时间/错误信息）；
  - 作为断言前的人工核对窗口。
*/
PRINT '========== 6. 日结果汇总 ==========';
SELECT
    attdate        AS [日期] ,
    bc.code_name   AS [班次] ,
    attStatus      AS [状态] ,
    attStatus1             ,
    attStatus2             ,
    attStatus3             ,
    attLate        AS [迟到分],
    attEarly       AS [早退分],
    attAbsenteeism AS [旷工] ,
    ST1                    ,
    ET1                    ,
    ST2                    ,
    ET2                    ,
    ST3                    ,
    ET3                    ,
    errorMessage   AS [错误信息]
FROM
    dbo.att_lst_DayResult d
LEFT JOIN
    dbo.att_lst_BC_set_code bc
ON
    d.ShiftID = bc.FID
WHERE
    RTRIM(d.EMP_ID) = RTRIM(@Emp)
AND d.attdate BETWEEN @Start AND @End
ORDER BY
    d.attdate;
PRINT '';
/* ===== 第7章：断言校验 =====
  规则：
  - 仅比较已设置期望值的字段（允许部分字段为 NULL 表示忽略）；
  - 覆盖 attStatus、段状态、迟到早退、旷工与 overtime15/20/30；
  - 若存在差异，统一汇总到 #fail 后 RAISERROR。
*/
PRINT '========== 7. 断言校验（attStatus/attAbsenteeism/attStatus1~3/attLate/attEarly/attovertime15~30）==========';
IF OBJECT_ID('tempdb..#exp') IS NOT NULL
DROP TABLE #exp;
SELECT
    *
INTO
    #exp
FROM
    (
        SELECT
            CAST('2026-03-01' AS DATE) AS attdate           ,
            N'2卡正常'                    AS scenario          ,
            0                          AS exp_attStatus     ,
            0                          AS exp_attAbsenteeism,
            0                          AS exp_attStatus1    ,
            CAST(NULL AS INT)          AS exp_attStatus2    ,
            CAST(NULL AS INT)          AS exp_attStatus3    ,
            0                          AS exp_attLate       ,
            0                          AS exp_attEarly
        
        UNION ALL
        
        SELECT
            '2026-03-02',
            N'2卡迟到'     ,
            1           ,
            0           ,
            1           ,
            NULL        ,
            NULL        ,
            5           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-03',
            N'2卡早退'     ,
            2           ,
            0           ,
            2           ,
            NULL        ,
            NULL        ,
            0           ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-04',
            N'2卡缺上班卡'   ,
            3           ,
            1           ,
            3           ,
            NULL        ,
            NULL        ,
            0           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-05',
            N'2卡缺下班卡'   ,
            3           ,
            1           ,
            3           ,
            NULL        ,
            NULL        ,
            0           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-06',
            N'2卡迟到+早退'  ,
            2           ,
            0           ,
            2           ,
            NULL        ,
            NULL        ,
            5           ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-07'   ,
            N'2卡跨天[-1,0]正常',
            0              ,
            0              ,
            0              ,
            NULL           ,
            NULL           ,
            0              ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-08'   ,
            N'2卡跨天[-1,0]迟到',
            1              ,
            0              ,
            1              ,
            NULL           ,
            NULL           ,
            5              ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-09'   ,
            N'2卡跨天[-1,0]早退',
            2              ,
            0              ,
            2              ,
            NULL           ,
            NULL           ,
            0              ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-10'    ,
            N'2卡跨天[-1,0]缺上班',
            3               ,
            1               ,
            3               ,
            NULL            ,
            NULL            ,
            0               ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-11'    ,
            N'2卡跨天[-1,0]缺下班',
            3               ,
            1               ,
            3               ,
            NULL            ,
            NULL            ,
            0               ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-12'  ,
            N'2卡跨天[0,1]正常',
            0             ,
            0             ,
            0             ,
            NULL          ,
            NULL          ,
            0             ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-13'  ,
            N'2卡跨天[0,1]迟到',
            1             ,
            0             ,
            1             ,
            NULL          ,
            NULL          ,
            5             ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-14'  ,
            N'2卡跨天[0,1]早退',
            2             ,
            0             ,
            2             ,
            NULL          ,
            NULL          ,
            0             ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-15'   ,
            N'2卡跨天[0,1]缺上班',
            3              ,
            1              ,
            3              ,
            NULL           ,
            NULL           ,
            0              ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-16'   ,
            N'2卡跨天[0,1]缺下班',
            3              ,
            1              ,
            3              ,
            NULL           ,
            NULL           ,
            0              ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-17',
            N'4卡正常'     ,
            0           ,
            0           ,
            0           ,
            0           ,
            NULL        ,
            0           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-18',
            N'4卡上午迟到'   ,
            1           ,
            0           ,
            1           ,
            0           ,
            NULL        ,
            5           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-19',
            N'4卡下午早退'   ,
            2           ,
            0           ,
            0           ,
            2           ,
            NULL        ,
            0           ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-20',
            N'4卡缺下午下班'  ,
            3           ,
            1           ,
            0           ,
            2           ,
            NULL        ,
            0           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-21'     ,
            N'4卡跨天[-1,0,0]正常',
            0                ,
            0                ,
            0                ,
            0                ,
            NULL             ,
            0                ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-22'        ,
            N'4卡跨天[-1,0,0]第1段迟到',
            1                   ,
            0                   ,
            1                   ,
            0                   ,
            NULL                ,
            5                   ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-23'        ,
            N'4卡跨天[-1,0,0]第1段早退',
            2                   ,
            0                   ,
            2                   ,
            0                   ,
            NULL                ,
            0                   ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-24'         ,
            N'4卡跨天[-1,0,0]第1段缺上班',
            3                    ,
            1                    ,
            3                    ,
            3                    ,
            NULL                 ,
            0                    ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-25'         ,
            N'4卡跨天[-1,0,0]第1段缺下班',
            3                    ,
            1                    ,
            3                    ,
            3                    ,
            NULL                 ,
            0                    ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-26'    ,
            N'4卡跨天[0,0,1]正常',
            0               ,
            0               ,
            0               ,
            0               ,
            NULL            ,
            0               ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-27'       ,
            N'4卡跨天[0,0,1]第2段迟到',
            1                  ,
            0                  ,
            0                  ,
            1                  ,
            NULL               ,
            0                  ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-28'       ,
            N'4卡跨天[0,0,1]第2段早退',
            2                  ,
            0                  ,
            0                  ,
            2                  ,
            NULL               ,
            0                  ,
            5
        
        UNION ALL
        
        SELECT
            '2026-03-29'        ,
            N'4卡跨天[0,0,1]第2段缺下班',
            3                   ,
            1                   ,
            0                   ,
            2                   ,
            NULL                ,
            0                   ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-30',
            N'6卡正常'     ,
            0           ,
            0           ,
            0           ,
            0           ,
            0           ,
            0           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-03-31',
            N'6卡第三段迟到'  ,
            1           ,
            0           ,
            0           ,
            1           ,
            1           ,
            0           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-01'        ,
            N'6卡跨天[-1,0,0]第1段正常',
            0                   ,
            0                   ,
            0                   ,
            0                   ,
            0                   ,
            0                   ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-02'        ,
            N'6卡跨天[-1,0,0]第1段迟到',
            1                   ,
            0                   ,
            1                   ,
            0                   ,
            0                   ,
            5                   ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-03'       ,
            N'6卡跨天[0,0,1]第3段正常',
            0                  ,
            0                  ,
            0                  ,
            0                  ,
            0                  ,
            0                  ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-04'       ,
            N'6卡跨天[0,0,1]第3段迟到',
            1                  ,
            0                  ,
            0                  ,
            0                  ,
            1                  ,
            0                  ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-05' ,
            N'阈值_迟到=5不触发',
            0            ,
            0            ,
            0            ,
            NULL         ,
            NULL         ,
            0            ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-06',
            N'阈值_迟到=6触发',
            1           ,
            0           ,
            1           ,
            NULL        ,
            NULL        ,
            6           ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-07' ,
            N'阈值_早退=5不触发',
            0            ,
            0            ,
            0            ,
            NULL         ,
            NULL         ,
            0            ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-08',
            N'阈值_早退=6触发',
            2           ,
            0           ,
            2           ,
            NULL        ,
            NULL        ,
            0           ,
            6
        
        UNION ALL
        
        SELECT
            '2026-04-09'                     ,
            N'阈值_迟到11+早退10=21触发旷工(段状态保留真实异常)',
            3                                ,
            1                                ,
            2                                ,
            NULL                             ,
            NULL                             ,
            0                                ,
            0
        
        UNION ALL
        
        SELECT
            '2026-04-10'           ,
            N'阈值_迟到10+早退10=20不触发旷工',
            2                      ,
            0                      ,
            2                      ,
            NULL                   ,
            NULL                   ,
            10                     ,
            10 ) x;
ALTER TABLE #exp
    ADD exp_attovertime15 INT NULL,
    exp_attovertime20     INT NULL,
    exp_attovertime30     INT NULL;
ALTER TABLE #exp
    ALTER COLUMN exp_attStatus INT NULL;
ALTER TABLE #exp
    ALTER COLUMN exp_attAbsenteeism INT NULL;
ALTER TABLE #exp
    ALTER COLUMN exp_attStatus1 INT NULL;
ALTER TABLE #exp
    ALTER COLUMN exp_attLate INT NULL;
ALTER TABLE #exp
    ALTER COLUMN exp_attEarly INT NULL;
-- 加班阈值专项：仅断言加班字段，其他字段不强校验
INSERT INTO #exp
    (
        attdate           ,
        scenario          ,
        exp_attStatus     ,
        exp_attAbsenteeism,
        exp_attStatus1    ,
        exp_attStatus2    ,
        exp_attStatus3    ,
        exp_attLate       ,
        exp_attEarly      ,
        exp_attovertime15 ,
        exp_attovertime20 ,
        exp_attovertime30
    )
VALUES
    (
        '2026-04-11'   ,
        N'阈值_加班110分不触发',
        NULL           ,
        NULL           ,
        NULL           ,
        NULL           ,
        NULL           ,
        NULL           ,
        NULL           ,
        0              ,
        0              ,
        0
    )
    ,
    (
        '2026-04-12'  ,
        N'阈值_加班130分触发',
        NULL          ,
        NULL          ,
        NULL          ,
        NULL          ,
        NULL          ,
        NULL          ,
        NULL          ,
        1             ,
        0             ,
        0
    )
;
IF OBJECT_ID('tempdb..#fail') IS NOT NULL
DROP TABLE #fail;
SELECT
    e.attdate                                          ,
    e.scenario                                         ,
    TRY_CAST(d.attStatus  AS INT) AS act_attStatus     ,
    e.exp_attStatus                                    ,
    ISNULL(d.attAbsenteeism,0)    AS act_attAbsenteeism,
    e.exp_attAbsenteeism                               ,
    TRY_CAST(d.attStatus1 AS INT) AS act_attStatus1    ,
    e.exp_attStatus1                                   ,
    TRY_CAST(d.attStatus2 AS INT) AS act_attStatus2    ,
    e.exp_attStatus2                                   ,
    TRY_CAST(d.attStatus3 AS INT) AS act_attStatus3    ,
    e.exp_attStatus3                                   ,
    ISNULL(d.attLate,0)           AS act_attLate       ,
    e.exp_attLate                                      ,
    ISNULL(d.attEarly,0)          AS act_attEarly      ,
    e.exp_attEarly                                     ,
    ISNULL(d.attovertime15,0)     AS act_attovertime15 ,
    e.exp_attovertime15                                ,
    ISNULL(d.attovertime20,0)     AS act_attovertime20 ,
    e.exp_attovertime20                                ,
    ISNULL(d.attovertime30,0)     AS act_attovertime30 ,
    e.exp_attovertime30
INTO
    #fail
FROM
    #exp e
LEFT JOIN
    dbo.att_lst_DayResult d
ON
    RTRIM(d.EMP_ID)=RTRIM(@Emp)
AND d.attdate      =e.attdate
WHERE
    (
        e.exp_attStatus IS NOT NULL
        AND (
            TRY_CAST(d.attStatus    AS INT) IS NULL
            OR TRY_CAST(d.attStatus AS INT) <> e.exp_attStatus))
OR  (
        e.exp_attAbsenteeism IS NOT NULL
        AND ISNULL(d.attAbsenteeism,0) <> e.exp_attAbsenteeism)
OR  (
        e.exp_attStatus1 IS NOT NULL
        AND (
            TRY_CAST(d.attStatus1    AS INT) IS NULL
            OR TRY_CAST(d.attStatus1 AS INT) <> e.exp_attStatus1))
OR  (
        e.exp_attStatus2 IS NOT NULL
        AND (
            TRY_CAST(d.attStatus2    AS INT) IS NULL
            OR TRY_CAST(d.attStatus2 AS INT) <> e.exp_attStatus2))
OR  (
        e.exp_attStatus3 IS NOT NULL
        AND (
            TRY_CAST(d.attStatus3    AS INT) IS NULL
            OR TRY_CAST(d.attStatus3 AS INT) <> e.exp_attStatus3))
OR  (
        e.exp_attLate IS NOT NULL
        AND ISNULL(d.attLate,0) <> e.exp_attLate)
OR  (
        e.exp_attEarly IS NOT NULL
        AND ISNULL(d.attEarly,0) <> e.exp_attEarly)
OR  (
        e.exp_attovertime15 IS NOT NULL
        AND ISNULL(d.attovertime15,0) <> e.exp_attovertime15)
OR  (
        e.exp_attovertime20 IS NOT NULL
        AND ISNULL(d.attovertime20,0) <> e.exp_attovertime20)
OR  (
        e.exp_attovertime30 IS NOT NULL
        AND ISNULL(d.attovertime30,0) <> e.exp_attovertime30)
OR  d.FID IS NULL;
DECLARE @FailCount INT =
(
    SELECT
        COUNT(*)
    FROM
        #fail);
DECLARE @TotalCount INT =
(
    SELECT
        COUNT(*)
    FROM
        #exp);
IF @FailCount > 0
    BEGIN PRINT '';
        PRINT '*** 测试失败 *** 失败 ' + CAST(@FailCount AS VARCHAR) + ' / ' + CAST(@TotalCount AS VARCHAR) + ' 条';
        SELECT
            attdate  AS [失败日期],
            scenario AS [场景]  ,
            act_attStatus     ,
            exp_attStatus     ,
            act_attAbsenteeism,
            exp_attAbsenteeism,
            act_attStatus1    ,
            exp_attStatus1    ,
            act_attStatus2    ,
            exp_attStatus2    ,
            act_attStatus3    ,
            exp_attStatus3    ,
            act_attLate       ,
            exp_attLate       ,
            act_attEarly      ,
            exp_attEarly      ,
            act_attovertime15 ,
            exp_attovertime15 ,
            act_attovertime20 ,
            exp_attovertime20 ,
            act_attovertime30 ,
            exp_attovertime30
        FROM
            #fail;
        RAISERROR(N'断言失败：存在 %d 条日结果与预期不符', 16, 1, @FailCount);
    END
ELSE
    BEGIN PRINT '';
        PRINT '========== 测试通过 ========== 全部 ' + CAST(@TotalCount AS VARCHAR) + ' 条用例符合预期';
    END;
    PRINT '';
    PRINT '========== 完成 ==========';
GO