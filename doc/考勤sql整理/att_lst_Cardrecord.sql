USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_Cardrecord]    Script Date: 2026/3/17 16:49:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[att_lst_Cardrecord](
	[FID] [uniqueidentifier] NOT NULL,
	[EMP_ID] [char](50) NULL,
	[Approver] [char](50) NULL,
	[Automan] [char](20) NULL,
	[AppState] [char](50) NULL,
	[SlotCardDate] [datetime] NULL,
	[SlotCardTime] [datetime] NULL,
	[AttendanceCard] [varchar](500) NULL,
	[OperatorName] [char](200) NULL,
	[IsOk] [char](40) NULL,
	[CardReason] [varchar](200) NULL,
	[Logo] [char](200) NULL,
	[Attendance] [char](300) NULL,
	[ReginsterCause] [char](200) NULL,
	[Entry] [char](200) NULL,
	[EntryTime] [datetime] NULL,
	[OperationTime] [datetime] NULL,
	[ArchiveLogo] [char](200) NULL,
	[approverTime] [datetime] NULL,
	[sourceType] [varchar](30) NULL,
 CONSTRAINT [PK_att_lst_Cardrecord] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_Cardrecord] ADD  CONSTRAINT [DF_att_lst_Cardrecord_FID]  DEFAULT (newid()) FOR [FID]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'主键' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'FID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'人员ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'EMP_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批者' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'Approver'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Automan' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'Automan'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批状态' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'AppState'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'刷卡日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'SlotCardDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'刷卡时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'SlotCardTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'考勤机号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'AttendanceCard'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'操作者' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'OperatorName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否有效' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'IsOk'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'补卡原因' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'CardReason'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'标识' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'Logo'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'考勤地点' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'Attendance'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'签卡事由' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'ReginsterCause'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'入口' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'Entry'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'入口时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'EntryTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'操作时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'OperationTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'归档标识' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'ArchiveLogo'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Cardrecord', @level2type=N'COLUMN',@level2name=N'approverTime'
GO


