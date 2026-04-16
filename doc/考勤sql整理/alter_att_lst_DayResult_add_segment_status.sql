/*
  alter_att_lst_DayResult_add_segment_status.sql
  用途：为 att_lst_DayResult 增加每段状态字段，支持四次卡两段独立展示异常

  执行前请备份！
*/
USE [SJHRsalarySystemDb]
GO

-- 1. 正式表增加字段
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.att_lst_DayResult') AND name = 'attStatus1')
BEGIN
  ALTER TABLE dbo.att_lst_DayResult ADD attStatus1 INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'第一段(上午)状态: 0正常 1迟到 2早退 3漏打卡 NULL不适用', 
    @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attStatus1';
  PRINT '已添加 attStatus1';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.att_lst_DayResult') AND name = 'attStatus2')
BEGIN
  ALTER TABLE dbo.att_lst_DayResult ADD attStatus2 INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'第二段(下午)状态: 0正常 1迟到 2早退 3漏打卡 NULL不适用', 
    @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attStatus2';
  PRINT '已添加 attStatus2';
END

-- 2. 可选：每段迟到早退分钟数（若需要精确展示）
/*
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.att_lst_DayResult') AND name = 'attLate1')
  ALTER TABLE dbo.att_lst_DayResult ADD attLate1 INT NULL, attEarly1 INT NULL, attLate2 INT NULL, attEarly2 INT NULL;
*/

PRINT '表结构更新完成。';
PRINT '注意：需同步修改 att_pro_DayResult 主过程，在迟到/早退/旷工逻辑中写入 attStatus1、attStatus2。';
GO
