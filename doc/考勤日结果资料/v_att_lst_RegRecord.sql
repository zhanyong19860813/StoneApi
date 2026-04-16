









                     
--签卡记录 表结构 和 数据样本
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

select top 10 * from    att_lst_Cardrecord
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

--签卡记录视图和 数据样本
CREATE VIEW [dbo].[v_att_lst_RegRecord]
AS
SELECT  
	a.FID ,
    a.EMP_ID ,
    emp.name ,
    emp.dept_id ,
    dept.SJCode AS dpm_id ,
    dept.name AS long_name ,
    --deptC.name AS longdeptname ,
		duty.name AS dutyName ,
    emp.frist_join_date ,
    emp.leave_time AS EMP_OutDate ,
    emp.EMP_NormalDate ,
    a.SlotCardDate ,
    CAST(CAST(a.SlotCardTime AS TIME) AS VARCHAR(5)) AS SlotCardTime ,
    --a.SlotCardTime,
	a.OperatorName ,
    a.CardReason ,
    a.OperationTime ,
    a.ArchiveLogo ,
    CASE 
		WHEN ISNULL(a.CardReason, '') <> ''
        THEN 
			CASE 
				WHEN a.AppState = 1 THEN '已审核'
                WHEN a.AppState = 0 THEN '审批中'
                ELSE '未审核'
            END
		ELSE ''
        END AS AppState ,
    a.Approver ,
    a.approverTime ,
    a.Entry ,
    a.EntryTime ,
    a.ReginsterCause
FROM    
	dbo.att_lst_Cardrecord AS a WITH(NOLOCK)
    JOIN dbo.t_base_employee AS emp ON a.EMP_ID = emp.code
	--LEFT JOIN dbo.ufn_get_dept_children('1F8DD5B1-EA39-4A55-9F3B-173D9FA22859') AS deptC ON  emp.dept_id = deptC.id
	LEFT JOIN dbo.t_base_department AS dept ON emp.dept_id = dept.id
	LEFT JOIN dbo.t_base_duty AS duty ON duty.id = emp.duty_id
WHERE   
	ISNULL(a.CardReason, '') <> ''; 


GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "a"
            Begin Extent = 
               Top = 9
               Left = 57
               Bottom = 201
               Right = 302
            End
            DisplayFlags = 280
            TopColumn = 15
         End
         Begin Table = "emp"
            Begin Extent = 
               Top = 9
               Left = 359
               Bottom = 201
               Right = 631
            End
            DisplayFlags = 280
            TopColumn = 24
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_RegRecord'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_RegRecord'
GO


select top 10 * from v_att_lst_RegRecord
BA154E54-1223-4A3B-A9C5-6662404252FB	A0008                                             	郭兵	B5F92C23-5EFC-45B1-AB73-34D372453880	17	营运中心	副经理              	2002-09-01	NULL	2002-12-01 00:00:00.000	2025-06-25 00:00:00.000	18:00	郭兵提交                                                                                                                                                                                                	漏打卡	2025-06-27 09:35:42.000	NULL	已审核	张郁葱                                            	2025-06-27 19:36:27.000	钉钉签卡申请                                                                                                                                                                                            	2025-06-27 23:30:06.000	下班忘记打卡，请领导签批。                                                                                                                                                                              
4EB2EF61-9B9E-4AB7-8DD0-2B82F3905669	A0008                                             	郭兵	B5F92C23-5EFC-45B1-AB73-34D372453880	17	营运中心	副经理              	2002-09-01	NULL	2002-12-01 00:00:00.000	2025-07-11 00:00:00.000	18:00	郭兵提交                                                                                                                                                                                                	因公办事	2025-07-12 08:28:08.000	NULL	已审核	张郁葱                                            	2025-07-12 09:10:54.000	钉钉签卡申请                                                                                                                                                                                            	2025-07-12 12:30:08.000	天虹仓调研                                                                                                                                                                                              
BEBBED6A-5D38-4BBD-9F58-13F39E6B586E	A0008                                             	郭兵	B5F92C23-5EFC-45B1-AB73-34D372453880	17	营运中心	副经理              	2002-09-01	NULL	2002-12-01 00:00:00.000	2025-08-15 00:00:00.000	18:00	郭兵提交                                                                                                                                                                                                	因公办事	2025-09-03 14:52:56.000	NULL	已审核	张郁葱                                            	2025-09-05 11:19:24.000	钉钉签卡申请                                                                                                                                                                                            	2025-09-05 12:30:08.000	因公外出，请领导审批。                                                                                                                                                                                  
366947F1-D612-4D03-8DFC-FC974FB59A47	A0008                                             	郭兵	B5F92C23-5EFC-45B1-AB73-34D372453880	17	营运中心	副经理              	2002-09-01	NULL	2002-12-01 00:00:00.000	2025-08-20 00:00:00.000	18:00	郭兵提交                                                                                                                                                                                                	因公办事	2025-09-03 14:54:52.000	NULL	已审核	张郁葱                                            	2025-09-05 11:19:14.000	钉钉签卡申请                                                                                                                                                                                            	2025-09-05 12:30:08.000	因公外出，请领导审批。                                                                                                                                                                                  
D2191144-E05F-EAE8-8C79-2BE7183C951F	D7720                                             	房振良(离)	035CB64D-2135-4994-883D-70D9562AFA1B	0102070401	茶山拆零一区	配货员              	2025-03-14	2025-07-24	NULL	2025-06-20 00:00:00.000	06:30	何凌                                                                                                                                                                                                    	漏打卡	2025-06-21 07:07:33.000	NULL	已审核	郑剑茵                                            	2025-06-21 17:25:51.000	NULL	NULL	NULL
2AA00960-E61E-46F2-A23D-0C17EA66FA9F	D7761                                             	刘科鑫(离)	101BCE7E-8CD0-409E-880B-AC2772D0A146	15010303	江门拆零三区	配货员              	2025-03-18	2025-08-20	NULL	2025-06-13 00:00:00.000	06:30	刘科鑫提交                                                                                                                                                                                              	漏打卡	2025-06-14 14:01:31.000	NULL	已审核	劳其勋                                            	2025-06-15 15:22:54.000	钉钉签卡申请                                                                                                                                                                                            	2025-06-15 18:30:08.000	记不得打卡了                                                                                                                                                                                            
EDFC3120-DB68-4BBB-9A49-3817DBD4C99D	D7761                                             	刘科鑫(离)	101BCE7E-8CD0-409E-880B-AC2772D0A146	15010303	江门拆零三区	配货员              	2025-03-18	2025-08-20	NULL	2025-06-20 00:00:00.000	15:25	刘科鑫提交                                                                                                                                                                                              	漏打卡	2025-06-23 11:23:52.000	NULL	已审核	劳其勋                                            	2025-06-23 12:09:17.000	钉钉签卡申请                                                                                                                                                                                            	2025-06-23 15:30:09.000	以为打了忘记了                                                                                                                                                                                          
3F4016FD-94BF-44FD-BF85-0795AA004D72	D7829                                             	何坤(离)	016C3BF5-56F8-447A-AFE9-1E30B9CF9859	100202	重庆整件组	整件配货员          	2025-04-01	2025-08-31	2025-05-01 00:00:00.000	2025-08-08 00:00:00.000	06:30	何坤提交                                                                                                                                                                                                	漏打卡	2025-08-11 08:49:03.000	NULL	已审核	李灵                                              	2025-08-11 09:54:50.000	钉钉签卡申请                                                                                                                                                                                            	2025-08-11 12:30:07.000	忘记打卡                                                                                                                                                                                                
5E28E0A3-5311-4A89-1DCE-08EE331FB969	D6014                                             	樊玉萍(聚杰)	2888A812-7383-4381-8661-DBD30CFF4757	1601010202	安徽捷联低温分拣组	分拣员	2024-09-18	NULL	2024-12-01 00:00:00.000	2025-11-29 00:00:00.000	19:00	杨杰(伍)                                                                                                                                                                                                	漏打卡	2025-12-01 15:46:40.000	NULL	已审核	杨杰(伍)                                          	2025-12-01 15:52:40.000	NULL	NULL	NULL
3E68040F-AD4B-4D56-AFFD-0F70A99E3C66	A1801                                             	彭浆辉	B0A02BAD-A226-468C-8A1E-0978A3739DF7	2003	桑园配送部	调度专员	2016-07-09	NULL	2016-09-01 00:00:00.000	2025-06-12 00:00:00.000	18:00	彭浆辉提交                                                                                                                                                                                              	因公办事	2025-06-20 09:49:39.000	NULL	已审核	向立红                                            	2025-06-20 09:53:16.000	钉钉签卡申请                                                                                                                                                                                            	2025-06-20 12:30:07.000	东方拿单                                                                                                                                                                                                