/*
  alter_att_lst_DayResult_add_segment3.sql
  用途：为 att_lst_DayResult 增加第三段字段，支持六次卡（三段六次打卡）

  执行前请备份！
*/
USE [SJHRsalarySystemDb]
GO

-- 1. 第三段班次时间与打卡
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.att_lst_DayResult') AND name = 'BCST3')
BEGIN
  ALTER TABLE dbo.att_lst_DayResult ADD BCST3 DATETIME NULL, begin_time_tag3 INT NULL, BCET3 DATETIME NULL, end_time_tag3 INT NULL, ST3 DATETIME NULL, ET3 DATETIME NULL;
  PRINT '已添加 BCST3, begin_time_tag3, BCET3, end_time_tag3, ST3, ET3';
END

-- 2. 第三段状态
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.att_lst_DayResult') AND name = 'attStatus3')
BEGIN
  ALTER TABLE dbo.att_lst_DayResult ADD attStatus3 INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'第三段状态: 0正常 1迟到 2早退 3漏打卡 NULL不适用',
    @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attStatus3';
  PRINT '已添加 attStatus3';
END

PRINT '表结构更新完成。';
GO
