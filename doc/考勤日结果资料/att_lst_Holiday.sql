

--请假记录表结构 和数据样本

CREATE TABLE [dbo].[att_lst_Holiday](
	[FID] [uniqueidentifier] NOT NULL,
	[HD_ID] [nvarchar](50) NULL,
	[HC_ID] [nvarchar](50) NULL,
	[EMP_ID] [nvarchar](50) NULL,
	[HD_StartDate] [datetime] NULL,
	[HD_StartTime] [datetime] NULL,
	[HD_EndDate] [datetime] NULL,
	[HD_EndTime] [datetime] NULL,
	[HD_Days] [numeric](18, 1) NULL,
	[HD_Reason] [nvarchar](1000) NULL,
	[HD_Remark] [nvarchar](500) NULL,
	[HD_WageDate] [datetime] NULL,
	[HD_MakeDate] [datetime] NULL,
	[HD_OperatorName] [nvarchar](50) NULL,
	[HD_CheckDate] [datetime] NULL,
	[HD_WGID] [nvarchar](50) NULL,
	[HD_Img] [nvarchar](800) NULL,
 CONSTRAINT [PK_att_lst_Holiday] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'记录编号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'假别代号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HC_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'工号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'EMP_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_StartDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_StartTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_EndDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_EndTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'请假天数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_Days'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'请假事由' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_Reason'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'工资日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_WageDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'录入日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_MakeDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'录入人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_OperatorName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'结算日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_CheckDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'工资单号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_Holiday', @level2type=N'COLUMN',@level2name=N'HD_WGID'
GO

select top 10 * from att_lst_Holiday order by HD_StartDate  desc
AA36A684-7D93-44DA-8B59-5E13788A5BEA	202511151036000471838	H01	B9676	2026-05-01 00:00:00.000	NULL	2026-05-14 00:00:00.000	NULL	14.0	事假	同步钉钉	2026-05-25 00:00:00.000	2025-11-19 18:30:09.000	赵倩	NULL	NULL	[]
541E89D9-9BEB-49D0-91BF-AA1F4AC9F846	HR001-202511250078	H06       	B5345	2026-05-01 00:00:00.000	NULL	2026-05-27 00:00:00.000	NULL	27.0	产假	同步OA	2026-05-25 00:00:00.000	2025-11-28 08:15:37.000	李文静	NULL	NULL	NULL
C14EE19B-3386-45B7-8F1F-0C98EBACB4DE	202510281658000598190	H06	B0019	2026-04-01 00:00:00.000	NULL	2026-04-27 00:00:00.000	NULL	27.0	怀孕生娃	同步钉钉	2026-04-25 00:00:00.000	2025-11-03 12:30:08.000	杨通章	NULL	NULL	["http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251028165856-B0019-1.jpg","http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251028165856-B0019-2.jpg","http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251028165856-B0019-3.jpg","http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251028165857-B0019-4.jpg","http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251028165858-B0019-5.jpg"]
D5C37E7E-320F-48B4-8251-3D32F8F318DA	202510312114000074791	H06	D2055	2026-04-01 00:00:00.000	NULL	2026-04-07 00:00:00.000	NULL	7.0	因怀孕到了孕晚期 需请假回去休息，特向领导申请办理请假手续，望领导批准
	同步钉钉	2026-04-25 00:00:00.000	2025-11-03 12:30:08.000	余小艳	NULL	NULL	["http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251031211407-D2055-1.jpg"]
B8393D62-36F2-4382-BAA0-7B9F9F7987A6	202511151036000471838	H01	B9676	2026-04-01 00:00:00.000	NULL	2026-04-30 00:00:00.000	NULL	30.0	事假	同步钉钉	2026-04-25 00:00:00.000	2025-11-19 18:30:09.000	赵倩	NULL	NULL	[]
45843E9A-3A1D-48F8-8791-E51DE6F55593	202510091440000058225	H06	D1086	2026-04-01 00:00:00.000	NULL	2026-04-26 00:00:00.000	NULL	26.0	剖腹产	同步钉钉	2026-04-25 00:00:00.000	2025-10-15 12:30:08.000	杨通章	NULL	NULL	["http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251009144004-D1086-1.jpg"]
BBF41F85-F477-474C-9CEC-E5BC98D29785	HR001-202511250078	H06       	B5345	2026-04-01 00:00:00.000	NULL	2026-04-30 00:00:00.000	NULL	30.0	产假	同步OA	2026-04-25 00:00:00.000	2025-11-28 08:15:37.000	李文静	NULL	NULL	NULL
B7475FD4-D8F4-4C37-8B77-50E2D60530CD	202510091440000058225	H06	D1086	2026-03-28 00:00:00.000	NULL	2026-03-31 00:00:00.000	NULL	4.0	剖腹产	同步钉钉	2026-03-25 00:00:00.000	2025-10-15 12:30:08.000	杨通章	NULL	NULL	["http://m.hrm.timeexpress.com.cn/HRMFiles/PersonnelManagement/holidayImg/20251009144004-D1086-1.jpg"]
CD02B73E-965E-65D2-429E-29EA5B1345EC	HRM01-202603190001	H09       	A8425     	2026-03-03 00:00:00.000	NULL	2026-03-03 00:00:00.000	NULL	1.0	事假	NULL	2026-03-25 00:00:00.000	2026-03-19 17:41:20.000	詹勇	NULL	NULL	NULL
022BB1BC-AAB7-423A-D22C-1FC72041EE7B	HRM01-202603190002	H13       	A8425     	2026-03-02 00:00:00.000	NULL	2026-03-02 00:00:00.000	NULL	1.0	事假	NULL	2026-03-25 00:00:00.000	2026-03-19 17:41:20.000	詹勇	NULL	NULL	NULL


--请假记录 视图和数据样本

CREATE VIEW [dbo].[v_att_lst_Holiday]
AS
SELECT  h.FID, h.HD_ID, h.HC_ID, h.EMP_ID, emp.name, d.long_name, dt.name AS duty_name, h.HD_StartDate, CONVERT(VARCHAR, h.HD_StartTime, 108) 
               AS HD_StartTime, h.HD_EndDate, CONVERT(VARCHAR, h.HD_EndTime, 108) AS HD_EndTime, h.HD_Days, hc.HC_Unit, hc.HC_Name, h.HD_Reason, 
               h.HD_WageDate, h.HD_MakeDate, h.HD_OperatorName, h.HD_CheckDate, h.HD_WGID,h.HD_Remark
FROM     dbo.att_lst_Holiday AS h LEFT OUTER JOIN
               dbo.att_lst_HolidayCategory AS hc ON h.HC_ID = hc.HC_ID LEFT OUTER JOIN
               dbo.t_base_employee AS emp ON h.EMP_ID = emp.code LEFT OUTER JOIN
               dbo.t_base_department AS d ON emp.dept_id = d.id LEFT OUTER JOIN
               dbo.t_base_duty AS dt ON emp.duty_id = dt.id




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
         Begin Table = "h"
            Begin Extent = 
               Top = 9
               Left = 57
               Bottom = 201
               Right = 328
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "hc"
            Begin Extent = 
               Top = 9
               Left = 714
               Bottom = 201
               Right = 960
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "emp"
            Begin Extent = 
               Top = 9
               Left = 385
               Bottom = 201
               Right = 657
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 9
               Left = 1017
               Bottom = 201
               Right = 1307
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dt"
            Begin Extent = 
               Top = 207
               Left = 57
               Bottom = 399
               Right = 259
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
      Begin ColumnWidths = 21
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
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 1000
         Width = 10' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_Holiday'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'00
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_Holiday'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_att_lst_Holiday'
GO
select top  10 * from v_att_lst_Holiday order by HD_StartDate desc 
AA36A684-7D93-44DA-8B59-5E13788A5BEA	202511151036000471838	H01	B9676	成陆洋	重庆信息组	信息员          	2026-05-01 00:00:00.000	NULL	2026-05-14 00:00:00.000	NULL	14.0	天         	事假	事假	2026-05-25 00:00:00.000	2025-11-19 18:30:09.000	赵倩	NULL	NULL	同步钉钉
541E89D9-9BEB-49D0-91BF-AA1F4AC9F846	HR001-202511250078	H06       	B5345	黄丹曼	茶山人事行政部	招聘专员	2026-05-01 00:00:00.000	NULL	2026-05-27 00:00:00.000	NULL	27.0	天         	产假	产假	2026-05-25 00:00:00.000	2025-11-28 08:15:37.000	李文静	NULL	NULL	同步OA
45843E9A-3A1D-48F8-8791-E51DE6F55593	202510091440000058225	H06	D1086	刘小梅	茶山拆零四区	配货员              	2026-04-01 00:00:00.000	NULL	2026-04-26 00:00:00.000	NULL	26.0	天         	产假	剖腹产	2026-04-25 00:00:00.000	2025-10-15 12:30:08.000	杨通章	NULL	NULL	同步钉钉
BBF41F85-F477-474C-9CEC-E5BC98D29785	HR001-202511250078	H06       	B5345	黄丹曼	茶山人事行政部	招聘专员	2026-04-01 00:00:00.000	NULL	2026-04-30 00:00:00.000	NULL	30.0	天         	产假	产假	2026-04-25 00:00:00.000	2025-11-28 08:15:37.000	李文静	NULL	NULL	同步OA
B8393D62-36F2-4382-BAA0-7B9F9F7987A6	202511151036000471838	H01	B9676	成陆洋	重庆信息组	信息员          	2026-04-01 00:00:00.000	NULL	2026-04-30 00:00:00.000	NULL	30.0	天         	事假	事假	2026-04-25 00:00:00.000	2025-11-19 18:30:09.000	赵倩	NULL	NULL	同步钉钉
C14EE19B-3386-45B7-8F1F-0C98EBACB4DE	202510281658000598190	H06	B0019	徐美莲	茶山拆零四区	配货员              	2026-04-01 00:00:00.000	NULL	2026-04-27 00:00:00.000	NULL	27.0	天         	产假	怀孕生娃	2026-04-25 00:00:00.000	2025-11-03 12:30:08.000	杨通章	NULL	NULL	同步钉钉
D5C37E7E-320F-48B4-8251-3D32F8F318DA	202510312114000074791	H06	D2055	吉会	贵州收货组	收货员              	2026-04-01 00:00:00.000	NULL	2026-04-07 00:00:00.000	NULL	7.0	天         	产假	因怀孕到了孕晚期 需请假回去休息，特向领导申请办理请假手续，望领导批准
	2026-04-25 00:00:00.000	2025-11-03 12:30:08.000	余小艳	NULL	NULL	同步钉钉
B7475FD4-D8F4-4C37-8B77-50E2D60530CD	202510091440000058225	H06	D1086	刘小梅	茶山拆零四区	配货员              	2026-03-28 00:00:00.000	NULL	2026-03-31 00:00:00.000	NULL	4.0	天         	产假	剖腹产	2026-03-25 00:00:00.000	2025-10-15 12:30:08.000	杨通章	NULL	NULL	同步钉钉
CD02B73E-965E-65D2-429E-29EA5B1345EC	HRM01-202603190001	H09       	A8425     	詹勇	信息研发部	经理                	2026-03-03 00:00:00.000	NULL	2026-03-03 00:00:00.000	NULL	1.0	天         	陪产假	事假	2026-03-25 00:00:00.000	2026-03-19 17:41:20.000	詹勇	NULL	NULL	NULL
022BB1BC-AAB7-423A-D22C-1FC72041EE7B	HRM01-202603190002	H13       	A8425     	詹勇	信息研发部	经理                	2026-03-02 00:00:00.000	NULL	2026-03-02 00:00:00.000	NULL	1.0	天         	探亲假	事假	2026-03-25 00:00:00.000	2026-03-19 17:41:20.000	詹勇	NULL	NULL	NULL