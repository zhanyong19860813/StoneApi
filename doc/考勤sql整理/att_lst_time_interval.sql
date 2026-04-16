/*
  att_lst_time_interval.sql
  用途：班次时段明细表（一个班次可拆分为 1~N 个时段）

  关键字段说明：
  - begin_time_tag / end_time_tag：时段起止相对 attdate 的日偏移（-1 前一天，0 当天，1 次日）；
  - valid_begin_time / valid_end_time：可识别刷卡的有效窗口；
  - centre_time_tag / centre_time：中间分割点（用于多次卡时段划分与配对）；
  - sec_num：时段序号（第几段）。
*/
USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_time_interval]    Script Date: 2026/3/17 17:08:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[att_lst_time_interval](
	[FID] [uniqueidentifier] NOT NULL,
	[pb_code_fid] [uniqueidentifier] NULL,
	[name] [varchar](500) NULL,
	[valid_begin_time_tag] [int] NULL,
	[valid_begin_time] [datetime] NULL,
	[begin_time_tag] [int] NULL,
	[begin_time] [datetime] NULL,
	[begin_time_slot_card] [bit] NULL,
	[end_time_tag] [int] NULL,
	[end_time] [datetime] NULL,
	[end_time_slot_card] [bit] NULL,
	[valid_end_time_tag] [int] NULL,
	[valid_end_time] [datetime] NULL,
	[centre_time_tag] [int] NULL,
	[centre_time] [datetime] NULL,
	[half_time] [int] NULL,
	[time_length] [numeric](19, 1) NULL,
	[remark] [varchar](10) NULL,
	[sec_num] [int] NULL,
	[import_sign] [uniqueidentifier] NULL,
	[op] [nvarchar](50) NULL,
	[modifyTime] [nvarchar](50) NULL,
 CONSTRAINT [PK__PB_info__C1BEA5A2F4353F44] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_time_interval] ADD  CONSTRAINT [DF_att_lst_time_interval_modifyTime]  DEFAULT (getdate()) FOR [modifyTime]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次信息表ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'pb_code_fid'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效开始时间标记' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'valid_begin_time_tag'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'valid_begin_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始时间标记' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'begin_time_tag'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'begin_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始时间是否刷卡' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'begin_time_slot_card'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束时间标记' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'end_time_tag'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'end_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'介绍时间是否刷卡' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'end_time_slot_card'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效结束时间标记' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'valid_end_time_tag'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'valid_end_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'中间时间标记' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'centre_time_tag'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'中间时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'centre_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'休息时长' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'half_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'此段时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'time_length'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'备注' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'remark'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'排序字段' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_time_interval', @level2type=N'COLUMN',@level2name=N'sec_num'
GO


