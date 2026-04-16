 
 --班次主表
 att_lst_BC_set_code
 USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_BC_set_code]    Script Date: 2026/3/20 12:21:22 ******/
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

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'排班名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'code_name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'总小时' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'total_hours'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'刷卡属性' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'sk_attribute'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'其他属性' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'other_attribute'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'共享班次' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'share_bc'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'备注1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'remark1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'备注2' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'remark2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'备注3' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'remark3'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'父级ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'parent_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'添加时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'add_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'添加人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_BC_set_code', @level2type=N'COLUMN',@level2name=N'add_user'
GO




 --班次明细表
USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_time_interval]    Script Date: 2026/3/20 12:22:06 ******/
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



 
 
 --  两次卡 数据样本begin
select * from att_lst_BC_set_code where code_name ='BC_2CARDS'
2B29BBA4-8AF1-44BF-97E9-0EF7CBC258F8	BC_2CARDS	8.0	0	NULL	0	TEST_两次卡	NULL	NULL	NULL	2026-03-18 12:06:13.627	test	NULL

select * from att_lst_time_interval where pb_code_fid='2B29BBA4-8AF1-44BF-97E9-0EF7CBC258F8'
287A105F-B75E-436C-A86D-22BE7EE17B65	2B29BBA4-8AF1-44BF-97E9-0EF7CBC258F8	2CARDS_SEG1	0	1900-01-01 08:00:00.000	0	1900-01-01 08:30:00.000	1	0	1900-01-01 12:30:00.000	1	0	1900-01-01 18:00:00.000	0	1900-01-01 12:00:00.000	0	8.0	NULL	1	NULL	test	2026-03-18 12:58:49

 --  两次卡 数据样本end




 --  四次卡 数据样本begin
select * from att_lst_BC_set_code where code_name ='BC_4CARDS'
 8951628D-0DC4-4B8E-9F29-3740CB7A63AF	BC_4CARDS	8.0	0	NULL	0	TEST_四次卡	NULL	NULL	NULL	2026-03-18 12:06:13.627	test	NULL

select * from att_lst_time_interval where pb_code_fid='8951628D-0DC4-4B8E-9F29-3740CB7A63AF'
 D2B38F2E-F21F-4BA0-A1FA-1C53B1B7F618	8951628D-0DC4-4B8E-9F29-3740CB7A63AF	4CARDS_SEG1	0	1900-01-01 08:00:00.000	0	1900-01-01 08:30:00.000	1	0	1900-01-01 12:30:00.000	1	0	1900-01-01 13:00:00.000	0	1900-01-01 10:30:00.000	0	4.0	NULL	1	NULL	test	2026-03-18 12:58:49
5E5478CB-B7C0-4CCC-8760-531D2FD5F700	8951628D-0DC4-4B8E-9F29-3740CB7A63AF	4CARDS_SEG2	0	1900-01-01 13:00:00.000	0	1900-01-01 13:30:00.000	1	0	1900-01-01 17:30:00.000	1	0	1900-01-01 18:00:00.000	0	1900-01-01 15:30:00.000	0	4.0	NULL	2	NULL	test	2026-03-18 12:58:49
 --  四次卡 数据样本end