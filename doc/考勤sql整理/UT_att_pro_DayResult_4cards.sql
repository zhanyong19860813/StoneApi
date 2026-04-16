/*
  UT_att_pro_DayResult_4cards.sql
  用途：测试 att_pro_DayResult 对「四次卡」班次（BC_4CARDS）的支持
  前提：A8425 在 2026-03 排班 Day10~Day14 为 BC_4CARDS（诊断显示 Day9=休息）

  测试场景：
    - 03-10：正常四次打卡（上午上班/下班 + 下午上班/下班）
    - 03-11：缺下午段一次卡（验证漏打卡/旷工）
*/

USE [SJHRsalarySystemDb]
GO

SET NOCOUNT ON;

DECLARE @TestEmp   NVARCHAR(10) = 'A8425';
DECLARE @TestOp    NVARCHAR(50) = 'A8425';
DECLARE @TestStart DATE         = '2026-03-01';
DECLARE @TestEnd   DATE         = '2026-03-31';

-- 测试日期（根据实际排班：Day10=03-10 为 BC_4CARDS）
DECLARE @Date1 DATE = '2026-03-10';  -- 正常四次卡
DECLARE @Date2 DATE = '2026-03-11';  -- 缺下午下班卡

PRINT '========== 〇、清理旧数据 ==========';
DELETE FROM dbo.att_lst_Cardrecord
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND CAST(SlotCardDate AS DATE) IN (@Date1, @Date2);
PRINT '  - 已清理 ' + CONVERT(VARCHAR(10),@Date1,120) + '、' + CONVERT(VARCHAR(10),@Date2,120) + ' 刷卡记录';

PRINT '';
PRINT '========== 一、准备四次卡测试数据 ==========';

-- 03-10：正常四次卡（上午 08:15/12:20，下午 13:15/17:45）
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @TestEmp, @Date1, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date1,120)+' 08:15:00'), '1'),
  (NEWID(), @TestEmp, @Date1, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date1,120)+' 12:20:00'), '1'),
  (NEWID(), @TestEmp, @Date1, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date1,120)+' 13:15:00'), '1'),
  (NEWID(), @TestEmp, @Date1, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date1,120)+' 17:45:00'), '1');
PRINT '  - ' + CONVERT(VARCHAR(10),@Date1,120) + ' 已插入 4 条刷卡（正常四次卡）';

-- 03-11：缺下午下班卡（只有 3 次：08:15、12:20、13:15，缺 17:xx）
INSERT INTO dbo.att_lst_Cardrecord (FID, EMP_ID, SlotCardDate, SlotCardTime, IsOk)
VALUES
  (NEWID(), @TestEmp, @Date2, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date2,120)+' 08:15:00'), '1'),
  (NEWID(), @TestEmp, @Date2, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date2,120)+' 12:20:00'), '1'),
  (NEWID(), @TestEmp, @Date2, CONVERT(DATETIME, CONVERT(VARCHAR(10),@Date2,120)+' 13:15:00'), '1');
PRINT '  - ' + CONVERT(VARCHAR(10),@Date2,120) + ' 已插入 3 条刷卡（缺下午下班卡）';

PRINT '';
PRINT '========== 二、执行 att_pro_DayResult ==========';
EXEC dbo.att_pro_DayResult
  @emp_list      = @TestEmp,
  @DayResultType = '0',
  @attStartDate  = @TestStart,
  @attEndDate    = @TestEnd,
  @op            = @TestOp;
PRINT '  - 执行完成';

PRINT '';
PRINT '========== 三、结果查看（att_lst_DayResult） ==========';
-- 使用 RTRIM 避免 CHAR 类型空格导致不匹配
SELECT
  EMP_ID,
  attdate,
  attStatus,
  BCST1, BCET1, ST1, ET1,
  BCST2, BCET2, ST2, ET2,
  attLate, attEarly, attAbsenteeism,
  errorMessage
FROM dbo.att_lst_DayResult
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND attdate IN (@Date1, @Date2)
ORDER BY attdate;

PRINT '';
PRINT '========== 三.1、诊断（输出到 Messages）==========';
DECLARE @Diag NVARCHAR(MAX) = '';

-- 实际结果摘要
SELECT @Diag = @Diag + '  [' + CONVERT(VARCHAR(10), attdate, 120) + '] ST1=' + ISNULL(CONVERT(VARCHAR(20), ST1, 120), 'NULL')
  + ' ET1=' + ISNULL(CONVERT(VARCHAR(20), ET1, 120), 'NULL')
  + ' ST2=' + ISNULL(CONVERT(VARCHAR(20), ST2, 120), 'NULL')
  + ' ET2=' + ISNULL(CONVERT(VARCHAR(20), ET2, 120), 'NULL')
  + ' attAbs=' + ISNULL(CAST(attAbsenteeism AS VARCHAR), 'NULL') + CHAR(13)+CHAR(10)
FROM dbo.att_lst_DayResult
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND attdate IN (@Date1, @Date2)
ORDER BY attdate;
IF @Diag = '' SET @Diag = '  (无记录)';
PRINT '日结果摘要：';
PRINT @Diag;

-- Day10 排班 ShiftID（03-10 对应 Day10）
SET @Diag = NULL;
SELECT @Diag = '  Day10_ID=' + ISNULL(CAST(Day10_ID AS VARCHAR(50)), 'NULL')
FROM dbo.att_lst_JobScheduling
WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND JS_Month = '202603';
PRINT 'A8425三月Day10排班：';
PRINT ISNULL(@Diag, '  (无排班)');

-- sec_num=2 配置
SET @Diag = NULL;
SELECT @Diag = '  valid=' + CAST(ISNULL(valid_begin_time_tag,-9) AS VARCHAR) + '/' + CAST(ISNULL(valid_end_time_tag,-9) AS VARCHAR)
  + ' ' + ISNULL(CONVERT(VARCHAR(20), valid_begin_time, 108), '?') + '~' + ISNULL(CONVERT(VARCHAR(20), valid_end_time, 108), '?')
FROM dbo.att_lst_time_interval t
WHERE t.pb_code_fid IN (SELECT Day10_ID FROM dbo.att_lst_JobScheduling WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND JS_Month = '202603')
  AND t.sec_num = 2;
PRINT 'Day10班次sec_num=2有效窗口：';
PRINT ISNULL(@Diag, '  (无sec_num=2)');

PRINT '';
PRINT '========== 四、判断点 ==========';
DECLARE @ErrCnt INT = 0;

-- 判断点 1：03-10 应有 ST1/ET1/ST2/ET2 四段刷卡
IF NOT EXISTS (
  SELECT 1 FROM dbo.att_lst_DayResult
  WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND attdate = @Date1
    AND ST1 IS NOT NULL AND ET1 IS NOT NULL AND ST2 IS NOT NULL AND ET2 IS NOT NULL
    AND attAbsenteeism = 0
)
BEGIN
  PRINT '  [FAIL] 判断点1：' + CONVERT(VARCHAR(10),@Date1,120) + ' 应有四段刷卡且无旷工';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点1：' + CONVERT(VARCHAR(10),@Date1,120) + ' 四段刷卡正常、无旷工';

-- 判断点 2：03-11 缺下午下班卡，应标记旷工
IF NOT EXISTS (
  SELECT 1 FROM dbo.att_lst_DayResult
  WHERE RTRIM(EMP_ID) = RTRIM(@TestEmp) AND attdate = @Date2
    AND attAbsenteeism = 1
    AND (errorMessage LIKE N'%漏打卡%' OR errorMessage IS NOT NULL)
)
BEGIN
  PRINT '  [FAIL] 判断点2：' + CONVERT(VARCHAR(10),@Date2,120) + ' 缺下午下班卡应标记旷工/漏打卡';
  SET @ErrCnt = @ErrCnt + 1;
END
ELSE
  PRINT '  [PASS] 判断点2：' + CONVERT(VARCHAR(10),@Date2,120) + ' 缺卡标记正确';

PRINT '';
IF @ErrCnt = 0
  PRINT '========== 全部判断点通过 ==========';
ELSE
  PRINT '========== 失败 ' + CAST(@ErrCnt AS VARCHAR) + ' 项 ==========';

GO

/*
-- 清理测试数据（根据实际测试日期修改）
DELETE FROM dbo.att_lst_Cardrecord WHERE RTRIM(EMP_ID) = 'A8425' AND CAST(SlotCardDate AS DATE) IN ('2026-03-10','2026-03-11');
DELETE FROM dbo.att_lst_DayResult  WHERE EMP_ID = 'A8425' AND attdate IN ('2026-03-10','2026-03-11');
*/
