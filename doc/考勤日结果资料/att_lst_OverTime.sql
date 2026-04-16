--加班作业 表结构 和 数据样本
CREATE TABLE [dbo].[att_lst_OverTime](
	[FID] [uniqueidentifier] NOT NULL,
	[EMP_ID] [nvarchar](50) NULL,
	[fType] [nvarchar](50) NULL,
	[fDate] [datetime] NULL,
	[fStartTime] [datetime] NULL,
	[IsSlotCard1] [bit] NULL,
	[fEndTime] [datetime] NULL,
	[IsSlotCard2] [bit] NULL,
	[overtime] [numeric](18, 1) NULL,
	[fReason] [nvarchar](500) NULL,
	[Remark] [nvarchar](500) NULL,
	[ApproveStatus] [nvarchar](50) NULL,
	[Approver] [nvarchar](50) NULL,
	[ApproveTime] [datetime] NULL,
	[OperatorName] [nvarchar](50) NULL,
	[OperatorTime] [datetime] NULL,
	[days] [int] NULL,
 CONSTRAINT [PK_att_lst_OverTime] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_OverTime] ADD  CONSTRAINT [DF_att_lst_OverTime_FID]  DEFAULT (newid()) FOR [FID]
GO

ALTER TABLE [dbo].[att_lst_OverTime] ADD  CONSTRAINT [DF_att_lst_OverTime_OperatorTime]  DEFAULT (getdate()) FOR [OperatorTime]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'主键' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'FID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'工号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'EMP_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'加班类型' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'fType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'加班日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'fDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'fStartTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否刷卡1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'IsSlotCard1'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'fEndTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否刷卡2' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'IsSlotCard2'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'加班时数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'overtime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'加班原因' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'fReason'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'备注' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'Remark'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批状态' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'ApproveStatus'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'Approver'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'ApproveTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'创建人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'OperatorName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'创建时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_OverTime', @level2type=N'COLUMN',@level2name=N'OperatorTime'
GO



select top 10 * from att_lst_OverTime
B183E136-F4A0-4161-8D5E-0001F2717885	A0038	超26天加班	2021-07-04 00:00:00.000	2021-07-04 08:00:00.000	NULL	2021-07-04 17:30:00.000	NULL	8.0	超26天加班。	同步OA	1	NULL	NULL	钟裕联	2021-08-13 10:08:10.000	NULL
9B95EC95-016F-461B-B62F-0002901C4D81	B9407	节日加班	2025-04-04 00:00:00.000	2025-04-04 08:00:00.000	NULL	2025-04-04 17:30:00.000	NULL	8.0	工作需要	同步OA	1	NULL	NULL	徐治红	2025-05-04 15:55:39.000	NULL
8DDBA2E5-61AF-4A5A-AFC7-00029F6150BD	A7437	节日加班	2025-10-02 00:00:00.000	2025-10-02 08:00:00.000	NULL	2025-10-02 17:30:00.000	NULL	8.0	节假日加班	同步OA	1	NULL	NULL	廖晓玲	2025-10-21 11:54:49.000	NULL
86699BC5-0D7D-4C1A-B6F7-00091F5DA6ED	B3847	超出满勤天数加班	2022-01-01 00:00:00.000	2022-01-01 08:00:00.000	NULL	2022-01-01 17:30:00.000	NULL	8.0	超出满勤天数加班。	同步OA	1	NULL	NULL	钟裕联	2022-02-15 12:03:45.000	NULL
E75A4003-AD8D-45E6-A76E-000DE224777A	C4990	超出满勤天数加班	2022-10-16 00:00:00.000	2022-10-16 08:00:00.000	NULL	2022-10-16 17:30:00.000	NULL	8.0	工作需要	同步OA	1	NULL	NULL	黄春梅	2022-11-10 11:59:08.000	NULL
C8BD147D-6824-40D1-B4A5-000E441914FA	D7185	节日加班	2025-10-06 00:00:00.000	2025-10-06 08:00:00.000	NULL	2025-10-06 17:30:00.000	NULL	8.0	中秋节因工作安排，申请加班	同步OA	1	NULL	NULL	张晓婷	2025-10-08 21:10:56.000	NULL
4E0D6E2A-0F67-4CAA-87E6-00110501E931	A2336	超出满勤天数加班	2023-07-30 00:00:00.000	2023-07-30 08:00:00.000	NULL	2023-07-30 17:30:00.000	NULL	8.0	因7月份货量大，产生额外加班，望各位领导批准，谢谢！	同步OA	1	NULL	NULL	黄文智	2023-08-17 12:18:34.000	NULL
31FC992E-999F-434E-B865-00126D57FE09	C7139	节日加班	2023-01-24 00:00:00.000	2023-01-24 08:00:00.000	NULL	2023-01-24 17:30:00.000	NULL	8.0	为确保仓库正常运行，需要员工加班	同步OA	1	NULL	NULL	张强	2023-01-28 12:57:51.000	NULL
C21FCE2E-0BB5-4611-80DD-0013610BB870	C9928	节日加班	2025-01-01 00:00:00.000	2025-01-01 08:00:00.000	NULL	2025-01-01 17:30:00.000	NULL	8.0	节日加班	同步OA	1	NULL	NULL	郎旭东	2025-01-14 14:55:59.000	NULL
3BB577BE-5DC1-4589-BE19-0016D8B3D08F	D1264	节日加班	2024-01-01 00:00:00.000	2024-01-01 08:00:00.000	NULL	2024-01-01 17:30:00.000	NULL	8.0	元旦节加班	同步OA	1	NULL	NULL	王静	2024-01-22 17:15:43.000	NULL


--加班作业 视图和 数据样本
CREATE VIEW [dbo].[v_att_lst_OverTime]
AS
SELECT  b.name, a.FID, a.EMP_ID,b.long_name,b.dutyName, a.fType, a.fDate, CONVERT(VARCHAR(20), a.fStartTime, 108) AS fStartTime, c.name AS IsSlotCard1, CONVERT(VARCHAR(20), 
               a.fEndTime, 108) AS fEndTime, d.name AS IsSlotCard2, a.overtime, a.fReason, a.Remark, (CASE WHEN ISNULL(ApproveStatus, '') 
               != '' THEN CASE WHEN a.ApproveStatus = 1 THEN '已审核' WHEN a.ApproveStatus = 0 THEN '' ELSE '' END ELSE '' END) AS ApproveStatus, a.Approver, 
               a.ApproveTime, a.OperatorName, a.OperatorTime,a.days
FROM     dbo.att_lst_OverTime AS a LEFT OUTER JOIN
               dbo.v_t_base_employee AS b ON a.EMP_ID = b.code LEFT OUTER JOIN
                   (SELECT  code, id, dictionary_id, name, value, description, sort, help_code, is_stop, add_user, add_time
                   FROM     dbo.v_data_base_dictionary_detail
                   WHERE   (code = 'YN')) AS c ON a.IsSlotCard1 = c.value LEFT OUTER JOIN
                   (SELECT  code, id, dictionary_id, name, value, description, sort, help_code, is_stop, add_user, add_time
                   FROM     dbo.v_data_base_dictionary_detail AS v_data_base_dictionary_detail_1
                   WHERE   (code = 'YN')) AS d ON a.IsSlotCard2 = d.value

GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
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
               Right = 292
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 207
               Left = 57
               Bottom = 399
               Right = 329
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 9
               Left = 349
               Bottom = 201
               Right = 565
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 9
               Left = 622
               Bottom = 201
               Right = 838
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_OverTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_OverTime'
GO

select top  10 * from v_att_lst_OverTime
候德超(离)	B183E136-F4A0-4161-8D5E-0001F2717885	A0038	桑园配送一组	提货驾驶员	超26天加班	2021-07-04 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	超26天加班。	同步OA	已审核	NULL	NULL	钟裕联	2021-08-13 10:08:10.000	NULL
代晓波	9B95EC95-016F-461B-B62F-0002901C4D81	B9407	重庆拆零组	补货员	节日加班	2025-04-04 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	工作需要	同步OA	已审核	NULL	NULL	徐治红	2025-05-04 15:55:39.000	NULL
易莎莎	8DDBA2E5-61AF-4A5A-AFC7-00029F6150BD	A7437	重庆信息组	信息员          	节日加班	2025-10-02 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	节假日加班	同步OA	已审核	NULL	NULL	廖晓玲	2025-10-21 11:54:49.000	NULL
吴正伟	86699BC5-0D7D-4C1A-B6F7-00091F5DA6ED	B3847	桑园配送一组	送货员              	超出满勤天数加班	2022-01-01 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	超出满勤天数加班。	同步OA	已审核	NULL	NULL	钟裕联	2022-02-15 12:03:45.000	NULL
NULL	E75A4003-AD8D-45E6-A76E-000DE224777A	C4990	NULL	NULL	超出满勤天数加班	2022-10-16 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	工作需要	同步OA	已审核	NULL	NULL	黄春梅	2022-11-10 11:59:08.000	NULL
杨荣粉	C8BD147D-6824-40D1-B4A5-000E441914FA	D7185	茶山客服组	客服员              	节日加班	2025-10-06 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	中秋节因工作安排，申请加班	同步OA	已审核	NULL	NULL	张晓婷	2025-10-08 21:10:56.000	NULL
NULL	4E0D6E2A-0F67-4CAA-87E6-00110501E931	A2336	NULL	NULL	超出满勤天数加班	2023-07-30 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	因7月份货量大，产生额外加班，望各位领导批准，谢谢！	同步OA	已审核	NULL	NULL	黄文智	2023-08-17 12:18:34.000	NULL
邵泽红	31FC992E-999F-434E-B865-00126D57FE09	C7139	山东仓储部	配货员              	节日加班	2023-01-24 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	为确保仓库正常运行，需要员工加班	同步OA	已审核	NULL	NULL	张强	2023-01-28 12:57:51.000	NULL
周琴(壹)	C21FCE2E-0BB5-4611-80DD-0013610BB870	C9928	四川拆零组	配货员              	节日加班	2025-01-01 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	节日加班	同步OA	已审核	NULL	NULL	郎旭东	2025-01-14 14:55:59.000	NULL
NULL	3BB577BE-5DC1-4589-BE19-0016D8B3D08F	D1264	NULL	NULL	节日加班	2024-01-01 00:00:00.000	08:00:00	NULL	17:30:00	NULL	8.0	元旦节加班	同步OA	已审核	NULL	NULL	王静	2024-01-22 17:15:43.000	NULL