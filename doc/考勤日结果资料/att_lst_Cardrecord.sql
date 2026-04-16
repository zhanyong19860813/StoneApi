 
  --刷卡记录 查询表结构 和 数据样本
  
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
 select top 10  * from   att_lst_Cardrecord
  2516E2CC-4CB7-4CDA-836C-00000123EE42	C3668                                             	NULL	-1                  	0                                                 	2025-09-18 00:00:00.000	1900-01-01 10:27:00.000	茶山司机	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-09-18 12:30:01.000	NULL	NULL	NULL	NULL
0B6E2732-A807-4B89-ACEE-00001684F6DD	D3261                                             	NULL	-1                  	0                                                 	2025-11-30 00:00:00.000	1900-01-01 06:30:00.000	江门公司2	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-11-30 09:30:00.000	NULL	NULL	NULL	NULL
81A8B220-C55E-46CD-A77E-00001792884C	C6361                                             	NULL	-1                  	0                                                 	2025-11-19 00:00:00.000	1900-01-01 16:57:00.000	赣州时捷	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-11-19 18:30:01.000	NULL	NULL	NULL	NULL
0A8142D3-26ED-4AD3-9996-00001CA85C92	D2528                                             	NULL	-1                  	0                                                 	2025-11-23 00:00:00.000	1900-01-01 15:05:00.000	茶山-拆零C	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-11-23 18:30:00.000	NULL	NULL	NULL	NULL
B4927940-F6A9-41EA-BA49-00001EC135C6	D7316                                             	NULL	-1                  	0                                                 	2025-06-30 00:00:00.000	1900-01-01 20:58:00.000	安徽捷联	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-07-01 06:30:00.000	NULL	NULL	NULL	NULL
B322F82E-AC6B-4889-8DBF-00002CF32DA2	D1253                                             	NULL	-1                  	0                                                 	2025-06-05 00:00:00.000	1900-01-01 12:00:00.000	惠州-拆零-05	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-06-05 15:30:00.000	NULL	NULL	NULL	NULL
86812CEF-3CB3-47C9-9F9C-00002D683606	D2895                                             	NULL	-1                  	0                                                 	2025-07-17 00:00:00.000	1900-01-01 18:00:00.000	惠州-信息部	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-07-17 18:30:01.000	NULL	NULL	NULL	NULL
11A52C4A-0B2F-4476-8505-000036F0BE1D	D4669                                             	NULL	-1                  	0                                                 	2025-09-07 00:00:00.000	1900-01-01 05:27:00.000	江门公司3	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-09-07 06:30:00.000	NULL	NULL	NULL	NULL
B38E7048-5B4A-4B26-9A5C-0000524635EB	A6150                                             	NULL	-1                  	0                                                 	2025-08-01 00:00:00.000	1900-01-01 12:34:00.000	茶山-收货部	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-08-01 15:30:00.000	NULL	NULL	NULL	NULL
BD660F89-6905-4904-B2CF-00006A82ED7C	D8539                                             	NULL	-1                  	0                                                 	2025-11-24 00:00:00.000	1900-01-01 16:35:00.000	茶山-拆零D	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-11-24 18:30:02.000	NULL	NULL	NULL	NULL





 --刷卡记录 查询视图和 数据样本
 SELECT a.FID,a.EMP_ID,(CASE WHEN ISNULL(CardReason,'')!='' THEN CASE WHEN a.AppState=1 THEN '已审核' WHEN a.AppState=0 THEN '审批中' ELSE '' END
						ELSE '' END ) AS AppState,
a.SlotCardDate,CONVERT(VARCHAR(100), a.SlotCardTime, 108) AS SlotCardTime,a.AttendanceCard,a.OperatorName,
a.IsOk,a.CardReason,a.Logo,a.Attendance,a.ReginsterCause,a.entry,a.EntryTime,a.OperationTime,a.ArchiveLogo,
b.name,b.EMP_NormalDate,b.frist_join_date,dept.long_name longdeptname,duty.name dutyName,b.leave_time EMP_OutDate,dept.long_name,dept.SJCode dpm_id
FROM att_lst_Cardrecord a
LEFT JOIN t_base_employee b ON a.emp_id=b.code
LEFT JOIN dbo.t_base_department dept ON b.dept_id=dept.id
LEFT JOIN dbo.t_base_duty duty ON b.duty_id=duty.id

 select top 10  * from  v_att_lst_Cardrecord
2516E2CC-4CB7-4CDA-836C-00000123EE42	C3668                                             		2025-09-18 00:00:00.000	10:27:00	茶山司机	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-09-18 12:30:01.000	NULL	NULL	段同雪(启创)(外)	2021-08-01 00:00:00.000	2021-07-15	茶山配送四组	驾驶员              	NULL	茶山配送四组	0108050104
81A8B220-C55E-46CD-A77E-00001792884C	C6361                                             		2025-11-19 00:00:00.000	16:57:00	赣州时捷	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-11-19 18:30:01.000	NULL	NULL	陈路平	2022-07-01 00:00:00.000	2022-04-22	江西赣州收理退组	退货员              	NULL	江西赣州收理退组	090601
11A52C4A-0B2F-4476-8505-000036F0BE1D	D4669                                             		2025-09-07 00:00:00.000	05:27:00	江门公司3	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-09-07 06:30:00.000	NULL	NULL	李健炜	2024-09-01 00:00:00.000	2024-07-09	江门设备工程部	初级设备工程师	NULL	江门设备工程部	1504
B38E7048-5B4A-4B26-9A5C-0000524635EB	A6150                                             		2025-08-01 00:00:00.000	12:34:00	茶山-收货部	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-08-01 15:30:00.000	NULL	NULL	向海敬	2017-12-01 00:00:00.000	2017-10-14	茶山整件配货C区	班长                	NULL	茶山整件配货C区	0102070203
CBCCB0B0-212F-4E62-9987-00007B754EA4	C8648                                             		2025-07-23 00:00:00.000	17:43:00	安徽捷联	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-07-23 18:30:00.000	NULL	NULL	黄后翠(聚杰)	2023-04-01 00:00:00.000	2023-01-16	安徽捷联低温分拣组	库维员	NULL	安徽捷联低温分拣组	1601010202
1C44986F-8651-418B-96A1-00009ADC820E	C6355                                             		2025-09-29 00:00:00.000	07:58:00	茶山-办公大楼	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-09-29 09:30:01.000	NULL	NULL	李亚东	2022-07-01 00:00:00.000	2022-04-25	茶山配送四组	调度专员	NULL	茶山配送四组	0108050104
ABE988D7-21AC-416E-8546-00009AE63635	C0287                                             		2025-10-10 00:00:00.000	08:20:00	福建厦门仓	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-10-10 12:30:00.000	NULL	NULL	李清娟	2020-10-01 00:00:00.000	2020-08-06	福建仓储部	作业员              	NULL	福建仓储部	1102
3C7826B6-C8FE-4D85-9485-00009D6F3413	B9196                                             		2025-09-15 00:00:00.000	13:02:00	惠州-宿舍	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-09-15 15:30:00.000	NULL	NULL	黄光文	2020-06-01 00:00:00.000	2020-03-25	惠州后勤组	厨工                	NULL	惠州后勤组	130702
4EF7BDEC-3D93-4F6D-A1D8-0000F2E6C6BC	B9409                                             		2025-07-30 00:00:00.000	23:35:00	江门公司4	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-07-31 06:30:00.000	NULL	NULL	谭洪(外)	2020-07-01 00:00:00.000	2020-04-27	江门配送三组	驾驶员              	NULL	江门配送三组	150205
9910A3EB-181F-4EBE-ACEB-0000F744552B	D7364                                             		2025-10-27 00:00:00.000	08:28:00	桑园-办公楼	NULL	NULL	NULL	NULL	NULL	NULL	钉钉接口                                                                                                                                                                                                	2025-10-27 12:30:01.000	NULL	NULL	周凤妹	2025-09-01 00:00:00.000	2025-02-17	核算部	会计专员	NULL	核算部	010602