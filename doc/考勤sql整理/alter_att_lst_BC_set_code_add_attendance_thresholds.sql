USE [SJHRsalarySystemDb]
GO

/* 班次主表新增阈值字段：迟到/早退/旷工/加班 */
IF COL_LENGTH('dbo.att_lst_BC_set_code', 'late_allow_minutes') IS NULL
BEGIN
  ALTER TABLE dbo.att_lst_BC_set_code ADD late_allow_minutes INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'迟到允许值(分)：迟到超过该分钟才算迟到',
       @level0type=N'SCHEMA', @level0name=N'dbo',
       @level1type=N'TABLE',  @level1name=N'att_lst_BC_set_code',
       @level2type=N'COLUMN', @level2name=N'late_allow_minutes';
END
GO

IF COL_LENGTH('dbo.att_lst_BC_set_code', 'early_allow_minutes') IS NULL
BEGIN
  ALTER TABLE dbo.att_lst_BC_set_code ADD early_allow_minutes INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'早退允许值(分)：早退超过该分钟才算早退',
       @level0type=N'SCHEMA', @level0name=N'dbo',
       @level1type=N'TABLE',  @level1name=N'att_lst_BC_set_code',
       @level2type=N'COLUMN', @level2name=N'early_allow_minutes';
END
GO

IF COL_LENGTH('dbo.att_lst_BC_set_code', 'absenteeism_start_minutes') IS NULL
BEGIN
  ALTER TABLE dbo.att_lst_BC_set_code ADD absenteeism_start_minutes INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'旷工起始值(分)：迟到+早退超过该分钟算旷工',
       @level0type=N'SCHEMA', @level0name=N'dbo',
       @level1type=N'TABLE',  @level1name=N'att_lst_BC_set_code',
       @level2type=N'COLUMN', @level2name=N'absenteeism_start_minutes';
END
GO

IF COL_LENGTH('dbo.att_lst_BC_set_code', 'overtime_start_minutes') IS NULL
BEGIN
  ALTER TABLE dbo.att_lst_BC_set_code ADD overtime_start_minutes INT NULL;
  EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'加班起始值(分)：超过该分钟才开始计算加班',
       @level0type=N'SCHEMA', @level0name=N'dbo',
       @level1type=N'TABLE',  @level1name=N'att_lst_BC_set_code',
       @level2type=N'COLUMN', @level2name=N'overtime_start_minutes';
END
GO

