/*
  att_lst_JobScheduling.sql
  用途：排班主表（按“人 + 月”存储 Day1~Day31 的班次）

  说明：
  - 一条记录对应一个员工在某个月的排班快照；
  - DayX_ID / DayX_Name 分别表示某日班次ID与班次名称；
  - 日结过程会基于该表把班次展开到每天，再结合刷卡记录计算日结果。
*/
USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_JobScheduling]    Script Date: 2026/3/17 17:11:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[att_lst_JobScheduling](
	[FID] [uniqueidentifier] NOT NULL,
	[EMP_ID] [char](10) NOT NULL,
	[JS_Month] [char](20) NOT NULL,
	[Day1_ID] [uniqueidentifier] NULL,
	[Day1_Name] [nvarchar](200) NULL,
	[Day2_ID] [uniqueidentifier] NULL,
	[Day2_Name] [nvarchar](200) NULL,
	[Day3_ID] [uniqueidentifier] NULL,
	[Day3_Name] [nvarchar](200) NULL,
	[Day4_ID] [uniqueidentifier] NULL,
	[Day4_Name] [nvarchar](200) NULL,
	[Day5_ID] [uniqueidentifier] NULL,
	[Day5_Name] [nvarchar](200) NULL,
	[Day6_ID] [uniqueidentifier] NULL,
	[Day6_Name] [nvarchar](200) NULL,
	[Day7_ID] [uniqueidentifier] NULL,
	[Day7_Name] [nvarchar](200) NULL,
	[Day8_ID] [uniqueidentifier] NULL,
	[Day8_Name] [nvarchar](200) NULL,
	[Day9_ID] [uniqueidentifier] NULL,
	[Day9_Name] [nvarchar](200) NULL,
	[Day10_ID] [uniqueidentifier] NULL,
	[Day10_Name] [nvarchar](200) NULL,
	[Day11_ID] [uniqueidentifier] NULL,
	[Day11_Name] [nvarchar](200) NULL,
	[Day12_ID] [uniqueidentifier] NULL,
	[Day12_Name] [nvarchar](200) NULL,
	[Day13_ID] [uniqueidentifier] NULL,
	[Day13_Name] [nvarchar](200) NULL,
	[Day14_ID] [uniqueidentifier] NULL,
	[Day14_Name] [nvarchar](200) NULL,
	[Day15_ID] [uniqueidentifier] NULL,
	[Day15_Name] [nvarchar](200) NULL,
	[Day16_ID] [uniqueidentifier] NULL,
	[Day16_Name] [nvarchar](200) NULL,
	[Day17_ID] [uniqueidentifier] NULL,
	[Day17_Name] [nvarchar](200) NULL,
	[Day18_ID] [uniqueidentifier] NULL,
	[Day18_Name] [nvarchar](200) NULL,
	[Day19_ID] [uniqueidentifier] NULL,
	[Day19_Name] [nvarchar](200) NULL,
	[Day20_ID] [uniqueidentifier] NULL,
	[Day20_Name] [nvarchar](200) NULL,
	[Day21_ID] [uniqueidentifier] NULL,
	[Day21_Name] [nvarchar](200) NULL,
	[Day22_ID] [uniqueidentifier] NULL,
	[Day22_Name] [nvarchar](200) NULL,
	[Day23_ID] [uniqueidentifier] NULL,
	[Day23_Name] [nvarchar](200) NULL,
	[Day24_ID] [uniqueidentifier] NULL,
	[Day24_Name] [nvarchar](200) NULL,
	[Day25_ID] [uniqueidentifier] NULL,
	[Day25_Name] [nvarchar](200) NULL,
	[Day26_ID] [uniqueidentifier] NULL,
	[Day26_Name] [nvarchar](200) NULL,
	[Day27_ID] [uniqueidentifier] NULL,
	[Day27_Name] [nvarchar](200) NULL,
	[Day28_ID] [uniqueidentifier] NULL,
	[Day28_Name] [nvarchar](200) NULL,
	[Day29_ID] [uniqueidentifier] NULL,
	[Day29_Name] [nvarchar](200) NULL,
	[Day30_ID] [uniqueidentifier] NULL,
	[Day30_Name] [nvarchar](200) NULL,
	[Day31_ID] [uniqueidentifier] NULL,
	[Day31_Name] [nvarchar](200) NULL,
	[modifier] [nvarchar](200) NULL,
	[modifyTime] [datetime] NULL,
 CONSTRAINT [PK__att_lst___C1BEA5A2AFF5D639] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day1_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day1_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day2_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day2_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day3_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day3_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day4_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day4_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day5_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day5_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day6_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day6_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day7_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day7_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day8_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day8_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day9_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day9_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day10_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day10_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day11_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day11_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day12_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day12_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day13_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day13_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day14_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day14_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day15_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day15_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day16_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day16_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day17_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day17_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day18_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day18_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day19_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day19_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day20_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day20_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day21_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day21_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day22_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day22_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day23_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day23_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day24_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day24_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day25_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day25_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day26_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day26_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day27_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day27_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day28_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day28_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day29_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day29_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day30_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day30_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_Day31_ID]  DEFAULT ('00000000-0000-0000-0000-000000000000') FOR [Day31_ID]
GO

ALTER TABLE [dbo].[att_lst_JobScheduling] ADD  CONSTRAINT [DF_att_lst_JobScheduling_modifyTime]  DEFAULT (getdate()) FOR [modifyTime]
GO


