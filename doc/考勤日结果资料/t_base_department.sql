
USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[t_base_department]    Script Date: 2026/3/20 12:12:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_base_department](
	[id] [uniqueidentifier] NOT NULL,
	[parent_id] [uniqueidentifier] NULL,
	[name] [nvarchar](50) NULL,
	[long_name] [nvarchar](500) NULL,
	[help_code] [varchar](40) NULL,
	[manager] [varchar](200) NULL,
	[replacemanager] [varchar](200) NULL,
	[organize] [int] NULL,
	[status] [varchar](2) NULL,
	[level_no] [int] NULL,
	[path] [varchar](50) NULL,
	[sort] [int] NULL,
	[effect_date] [datetime] NULL,
	[expire_date] [datetime] NULL,
	[is_out_department] [int] NULL,
	[is_virtual_department] [int] NULL,
	[dept_type] [int] NULL,
	[description] [nvarchar](150) NULL,
	[email] [varchar](100) NULL,
	[url] [varchar](100) NULL,
	[office_address] [varchar](100) NULL,
	[phone] [varchar](30) NULL,
	[post_code] [varchar](30) NULL,
	[fax] [varchar](30) NULL,
	[isbussiness_dept] [int] NULL,
	[isgetmoney_dept] [int] NULL,
	[is_stop] [bit] NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
	[SJCode] [nvarchar](50) NULL,
	[SJPCode] [nvarchar](50) NULL,
	[dingtalk_id] [varchar](50) NULL,
	[alimail_id] [varchar](100) NULL,
	[Modify_Name] [nvarchar](50) NULL,
	[Modify_Time] [datetime] NULL,
	[add_name] [nvarchar](20) NULL,
	[generalmanager] [nvarchar](50) NULL,
	[generalmanagercode] [nvarchar](50) NULL,
	[secondmanager] [nvarchar](50) NULL,
	[secondmanagercode] [nvarchar](50) NULL,
	[firstmanagercode] [nvarchar](50) NULL,
	[firstmanager] [nvarchar](50) NULL,
	[isapprove] [int] NULL,
 CONSTRAINT [PK_t_base_department] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[t_base_department] ADD  CONSTRAINT [DF_t_base_department_id]  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[t_base_department] ADD  CONSTRAINT [DF_t_base_department_dept_type]  DEFAULT ((2)) FOR [dept_type]
GO

ALTER TABLE [dbo].[t_base_department] ADD  CONSTRAINT [DF_t_base_department_is_stop]  DEFAULT ((0)) FOR [is_stop]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'部门名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_department', @level2type=N'COLUMN',@level2name=N'name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'部门长名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_department', @level2type=N'COLUMN',@level2name=N'long_name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'助记码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_department', @level2type=N'COLUMN',@level2name=N'help_code'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'部门负责人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_department', @level2type=N'COLUMN',@level2name=N'manager'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否业务部门' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_department', @level2type=N'COLUMN',@level2name=N'isbussiness_dept'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否收款单位' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_department', @level2type=N'COLUMN',@level2name=N'isgetmoney_dept'
GO



select  top  10 * from t_base_department

FC37131B-326F-47A3-960C-00C6B2A40189	7876F37E-71EF-4753-BAD3-7B48BA5C0821	江门彩华拆零配货部	江门彩华拆零配货部	NULL	A2283     		NULL	0	NULL	@01-020-001-010	10	NULL	NULL	NULL	0	1								0	NULL	0	NULL	2025-10-09 17:30:06.000	150110	1501	1042369884	-----V----.LPDucV:2:----.MmeyD3	尹棋	2025-10-16 09:02:35.133	尹棋	NULL	NULL	NULL	NULL	NULL	NULL	0
2A5792FB-5777-4752-956C-00CE8B041718	B23EBC55-A9EA-4588-A75B-D97FF2B6976D	设备工程部	设备工程部	NULL	NULL	NULL	NULL	1	NULL	@01-003-004	4	NULL	NULL	NULL	NULL	2	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	1	NULL	2018-07-04 16:00:00.317	010504              	0105                	NULL	NULL	NULL	2023-03-31 16:39:00.790	NULL	NULL	NULL	林海	A0541	A0541	林海	NULL
BDA72C9E-1B79-4CA9-A618-00E382199843	0FF7F439-74AB-4FE8-BA89-BA9CA20F67F2	多爱一婴仓储组	多爱一婴仓储组			A0369     	0	0	0	@01-005-002-004-001	1	1900-01-01 00:00:00.000	1900-01-01 00:00:00.000	0	0	1								0	0	1	NULL	2020-03-05 15:58:54.000	0107020401	01070204	NULL		梁健荣	2022-08-11 15:36:52.257	梁健荣	NULL	NULL	NULL	NULL	NULL	NULL	NULL
CEAB72F1-A00C-4F9E-8BFB-0162306285AE	54E2083B-BC1E-4A47-9F6C-AFFE4A3C8E87	中班组	中班组	NULL	NULL	NULL	NULL	1	NULL	@01-002-002-001-001	1	NULL	NULL	NULL	NULL	2	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	1	NULL	2018-07-04 16:00:00.317	0102020101          	01020201            	NULL	NULL	NULL	2022-08-11 15:36:52.257	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
20655B97-D535-4A79-A56A-017767170D7A	D7406005-72EE-43B1-A996-E249ADB8EE88	贵州客服组	贵州客服组	NULL	C2246		NULL	0	NULL	@01-018-001-002	2	NULL	NULL	NULL	0	0								0	NULL	0	NULL	2021-06-30 10:45:33.000	120102	1201	499944432	-----V----.LPDucV:2:----.M3FFIQ	谢飞	2025-07-30 14:53:47.377	梁健荣	NULL	NULL	NULL	NULL	NULL	NULL	NULL
2E75DE2D-7AD6-439E-B61C-01A7BCFDAB67	60FE7873-81C7-4FFD-8FD4-32FBC16EA1EC	桑园仓储部	桑园仓储部	NULL	A0016		NULL	0	NULL	@01-024-002	2	NULL	NULL	NULL	0	1								1	NULL	0	NULL	2023-05-13 12:08:45.000	2002	20	849878812	-----V----.LPDucV:2:----.ME4nas	尹棋	2025-04-02 10:25:42.040	梁健荣	NULL	NULL	NULL	NULL	NULL	NULL	0
1F0DF517-7FAA-4152-9FF6-01D5F2D0DF5E	7EBF006E-19A8-4558-AA71-88FA99ECBF7C	江门卸货组	江门卸货组	NULL			NULL	0	NULL	@01-020-001-001-001	1	NULL	NULL	NULL	0	0								0	NULL	0	NULL	2020-11-03 09:28:50.000	15010101	150101	422033050	-----V----.LPDucV:2:----.M.srV9	NULL	2023-03-31 16:39:00.683	梁健荣	NULL	NULL	金双全	A0012	A0065	翟志文	NULL
FAC481C0-2CFF-49A0-912E-02D2A90C0691	41F21253-77CE-42DE-B0B6-15C7771C41F3	江门整件侧向拣选区	江门整件侧向拣选区	NULL	D3125,A0101		NULL	0	NULL	@01-020-001-004-006	6	NULL	NULL	NULL	0	1								0	NULL	0	NULL	2024-12-09 16:57:16.000	15010406	150104	979334384	-----V----.LPDucV:2:----.MRkMWi	尹棋	2025-04-10 09:43:09.543	尹棋	NULL	NULL	NULL	NULL	NULL	NULL	0
A3527E37-F86D-478D-B1D6-030B2FFD73ED	E70C4502-8B9D-45BF-A4A9-819843786C9A	江西南昌信息组	江西南昌信息组	NULL	A2884	A7744     	NULL	0	NULL	@01-015-002-001	1	NULL	NULL	NULL	0	1								1	NULL	0	5D92A9E9-747D-457E-9A4E-1F9CABB72FE4	2019-04-26 15:15:46.000	090201	0902	113030200	-----V----.LPDucV:2:----.Luyt20	梁健荣	2022-08-11 15:50:29.717	NULL	张郁葱	A0001     			A0023     	巢松溪	NULL
BFDD45EA-4F00-4A2B-8300-0350EDE2530D	924880C3-FF6C-4A27-9DAE-7E36BD6778F5	惠东拆零三区	惠东拆零三区	NULL	A1433     		NULL	0	NULL	@01-019-010-002-003	3	NULL	NULL	NULL	0	1								0	NULL	0	NULL	2025-04-17 10:22:14.000	13120203	131202	995826221	-----V----.LPDucV:2:----.MYYNqj	尹棋	2025-05-28 11:15:55.550	尹棋	NULL	NULL	NULL	NULL	NULL	NULL	0