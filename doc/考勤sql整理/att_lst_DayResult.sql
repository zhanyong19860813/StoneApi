CREATE TABLE [dbo].[att_lst_DayResult](
	[FID] [uniqueidentifier] NOT NULL,
	[EMP_ID] [nvarchar](50) NULL,
	[dpm_id] [nvarchar](50) NULL,
	[ps_id] [nvarchar](50) NULL,
	[attdate] [date] NULL,
	[isHoliday] [bit] NULL,
	[ShiftID] [uniqueidentifier] NULL,
	[attStatus] [nvarchar](50) NULL,
	[attTime] [numeric](18, 2) NULL,
	[attDay] [numeric](18, 1) NULL,
	[attHolidayID] [uniqueidentifier] NULL,
	[attLate] [numeric](18, 0) NULL,
	[attEarly] [numeric](18, 0) NULL,
	[attAbsenteeism] [numeric](18, 0) NULL,
	[attHoliday] [numeric](18, 0) NULL,
	[attHolidayCategory] [nvarchar](200) NULL,
	[attovertime15] [numeric](18, 1) NULL,
	[attovertime20] [numeric](18, 1) NULL,
	[attovertime30] [numeric](18, 1) NULL,
	[BCST1] [datetime] NULL,
	[begin_time_tag1] [int] NULL,
	[BCET1] [datetime] NULL,
	[end_time_tag1] [int] NULL,
	[ST1] [datetime] NULL,
	[ET1] [datetime] NULL,
	[BCST2] [datetime] NULL,
	[begin_time_tag2] [int] NULL,
	[BCET2] [datetime] NULL,
	[end_time_tag2] [int] NULL,
	[ST2] [datetime] NULL,
	[ET2] [datetime] NULL,
	[errorMessage] [nvarchar](2000) NULL,
	[approval] [int] NULL,
	[approvaler] [nvarchar](50) NULL,
	[approvalTime] [datetime] NULL,
	[ModifyTime] [datetime] NULL,
	[OperatorName] [nvarchar](50) NULL,
	[OperationTime] [datetime] NULL,
	[regcard_sum] [int] NULL,
	[cancel] [nvarchar](50) NULL,
	[cancelTime] [datetime] NULL,
	[PushAbsenteeism] [nvarchar](100) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_DayResult] ADD  CONSTRAINT [DF_att_lst_DayResult_FID]  DEFAULT (newid()) FOR [FID]
GO

ALTER TABLE [dbo].[att_lst_DayResult] ADD  CONSTRAINT [DF_att_lst_DayResult_ModifyTime]  DEFAULT (getdate()) FOR [ModifyTime]
GO

ALTER TABLE [dbo].[att_lst_DayResult] ADD  CONSTRAINT [DF__att_lst_D__regca__6AFC63FE]  DEFAULT ((0)) FOR [regcard_sum]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'工号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'EMP_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'出勤日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attdate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否假期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'isHoliday'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'ShiftID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'出勤状态' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attStatus'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'出勤时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'出勤天数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attDay'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'假别ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attHolidayID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'迟到数(m)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attLate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'早退数(m)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attEarly'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'旷工' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attAbsenteeism'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'请假数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attHoliday'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'加班数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'attovertime15'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'BCST1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始时间跨天' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'begin_time_tag1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次一段结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'BCET1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束时间跨天' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'end_time_tag1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始刷卡时间1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'ST1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束刷卡时间1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'ET1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次二段开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'BCST2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次二段结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'BCET2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'第二段刷卡1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'ST2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'第二段刷卡2' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'ET2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批状态' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'approval'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批者' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'approvaler'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'approvalTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'操作人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'OperatorName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'操作时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult', @level2type=N'COLUMN',@level2name=N'OperationTime'
GO
