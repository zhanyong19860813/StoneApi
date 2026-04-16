/*
  att_lst_BC_set_code.sql
  用途：班次主表（班次名称、工时、刷卡属性、考勤阈值）

  阈值字段：
  - late_allow_minutes：迟到允许值（超过才计迟到）
  - early_allow_minutes：早退允许值（超过才计早退）
  - absenteeism_start_minutes：旷工阈值（迟到+早退超过该值计旷工）
  - overtime_start_minutes：加班起算阈值（超过该值才开始计加班）

  备注：
  - 本文件中部分历史扩展属性注释存在乱码，为历史编码问题；
  - 实际业务含义以上述字段说明及增量脚本为准。
*/
USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_BC_set_code]    Script Date: 2026/3/17 22:56:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[att_lst_BC_set_code](
	[FID] [uniqueidentifier] NOT NULL,
	[code_name] [varchar](300) NULL,
	[total_hours] [numeric](19, 1) NULL,
	[sk_attribute] [int] NULL,
	[other_attribute] [varchar](10) NULL,
	[share_bc] [bit] NULL,
	[late_allow_minutes] [int] NULL,
	[early_allow_minutes] [int] NULL,
	[absenteeism_start_minutes] [int] NULL,
	[overtime_start_minutes] [int] NULL,
	[remark1] [varchar](80) NULL,
	[remark2] [varchar](80) NULL,
	[remark3] [varchar](80) NULL,
	[parent_id] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
	[add_user] [nvarchar](50) NULL,
	[import_sign] [uniqueidentifier] NULL,
 CONSTRAINT [PK__PB_set_c__C1BEA5A2C699CF5D] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�Ű�����' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'code_name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��Сʱ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'total_hours'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ˢ������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'sk_attribute'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'other_attribute'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'share_bc'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�ٵ�����ֵ(��)���ٵ������÷��Ӳ���ٵ�' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'late_allow_minutes'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��������ֵ(��)�����˳����÷��Ӳ�������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'early_allow_minutes'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'������ʼֵ(��)���ٵ�+���˳����÷��������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'absenteeism_start_minutes'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'�Ӱ���ʼֵ(��)�������÷��Ӳſ�ʼ����Ӱ�' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'overtime_start_minutes'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��ע1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'remark1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��ע2' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'remark2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'��ע3' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'remark3'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'����ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'parent_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'����ʱ��' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'add_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'������' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'add_user'
GO