

USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_VacationDay]    Script Date: 2026/3/20 14:22:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
--年假管理表结构
CREATE TABLE [dbo].[att_lst_VacationDay](
	[FID] [uniqueidentifier] NOT NULL,
	[EMP_ID] [char](10) NULL,
	[FYear] [char](10) NULL,
	[ThisVacationDay] [numeric](18, 1) NULL,
	[UserDay] [numeric](18, 1) NULL,
	[RemainDay] [numeric](18, 1) NULL,
	[LastRemainDay] [numeric](18, 1) NULL,
	[ModifyTime] [datetime] NULL,
	[InitVcationDay] [int] NULL,
	[InitUsedDay] [int] NULL,
	[ActualVcationDay] [numeric](18, 1) NULL,
	[AdvanceUsedDay] [numeric](18, 1) NULL,
	[RemainVcationDay] [numeric](18, 1) NULL,
	[UpTime] [datetime] NULL,
 CONSTRAINT [PK_att_lst_VacationDay] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_VacationDay] ADD  CONSTRAINT [DF_att_lst_VacationDay_FID]  DEFAULT (newid()) FOR [FID]
GO

ALTER TABLE [dbo].[att_lst_VacationDay] ADD  CONSTRAINT [DF_att_lst_VacationDay_ModifyTime]  DEFAULT (getdate()) FOR [ModifyTime]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'主键' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'FID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'工号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'EMP_ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'年份' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'FYear'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'今年年假天数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'ThisVacationDay'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'已休年假天数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'UserDay'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'剩余年假天数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'RemainDay'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'上年年假天数' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_VacationDay', @level2type=N'COLUMN',@level2name=N'LastRemainDay'
GO




--年假管理表和数据样本
select top 10  * from att_lst_VacationDay
1C49B2C1-04CF-4EB5-AAF5-000276CDA3B7	A1060     	2022      	5.0	5.0	0.0	NULL	2023-01-09 17:21:17.590	NULL	NULL	NULL	NULL	NULL	NULL
3CBE1936-B49B-494A-9BA1-0003C235C652	A2148     	2019      	5.0	NULL	NULL	NULL	2018-12-25 11:31:16.593	NULL	NULL	NULL	NULL	NULL	NULL
4544F268-5691-4F19-88AE-0007AD668826	B5880     	2020      	3.0	NULL	NULL	NULL	2021-01-18 10:26:51.697	NULL	NULL	NULL	NULL	NULL	NULL
F738C8DA-7218-456F-85FB-000EA3C10052	B3610     	2020      	4.0	4.0	0.0	NULL	2021-01-18 10:26:51.697	NULL	NULL	NULL	NULL	NULL	NULL
3FBAD480-A683-4F82-93BA-000F7A1822EB	D1619     	2026      	5.0	NULL	4.0	NULL	2026-03-19 17:43:21.180	NULL	NULL	1.0	0.0	1.0	2026-03-19 17:43:21.583
F0517C1A-782B-4F8E-B771-000FB57F0C6B	A0366     	2020      	5.0	NULL	NULL	NULL	2021-01-18 10:26:51.697	NULL	NULL	NULL	NULL	NULL	NULL
03CAB372-4C64-400C-922F-0011872789CA	C4908     	2025      	5.0	5.0	0.0	NULL	2025-12-02 00:00:02.280	NULL	NULL	4.0	1.0	0.0	2025-12-02 00:00:06.660
BC95D067-F0B5-411B-A600-001275C3EBE5	A5196     	2018      	7.0	2.0	5.0	NULL	2019-12-28 11:00:19.127	NULL	NULL	NULL	NULL	NULL	NULL
77278E17-366A-4FC7-8066-0015CA335032	A4471     	2021      	5.0	5.0	0.0	NULL	2022-01-15 09:07:09.763	NULL	NULL	NULL	NULL	NULL	NULL
030B79F2-A4E2-461C-940F-00166A13C3BE	B4522     	2024      	5.0	5.0	0.0	NULL	2025-01-20 17:05:54.913	NULL	NULL	5.0	0.0	0.0	2025-01-20 17:05:56.627


--年假管理视图和数据样本

select top 10  * from  v_att_lst_VacationDay
CREATE VIEW [dbo].[v_att_lst_VacationDay]
AS
    SELECT  a.* ,
            b.dept_id ,
            d.name AS long_name ,
            b.name ,
            du.name AS dutyName ,
            d.SJCode ,
            b.frist_join_date ,
            b.type AS EmpType ,
            b.status AS EmpStatus ,
            CASE WHEN b.status = 0 THEN '在职'
                 ELSE '离职'
            END EmpStatusName
    FROM    att_lst_VacationDay a
            LEFT JOIN t_base_employee b ON a.EMP_ID = b.code
            LEFT JOIN dbo.t_base_department d ON d.id = b.dept_id
            LEFT JOIN dbo.t_base_duty du ON du.id = b.duty_id;

GO
3284DF0A-6373-43FA-BCF3-0028C5A118C8	C9306     	2024      	3.0	3.0	0.0	NULL	2025-01-20 17:05:54.913	NULL	NULL	3.0	0.0	0.0	2025-01-20 17:05:56.627	035CB64D-2135-4994-883D-70D9562AFA1B	茶山拆零一区	黄红云(离)	配货员              	0102070401	2023-03-25	合同工	1	离职
29EAEAB3-2EC4-43A3-AEB7-0028F1AB008F	A0343     	2022      	5.0	NULL	5.0	NULL	2023-01-09 17:21:17.590	NULL	NULL	NULL	NULL	NULL	NULL	2B5FBB47-4830-493D-9EC7-746BF903862A	桑园配货二组	吴志卫	前移式叉车司机      	2006	2013-02-20	合同工	0	在职
263B58F7-D574-48B5-B43F-002C6BC2616B	C0515     	2022      	5.0	NULL	5.0	NULL	2023-01-09 17:21:17.590	NULL	NULL	NULL	NULL	NULL	NULL	627D3750-12CC-45DB-BF13-89F5CC945CF5	惠州退货部	黄广标(外)	退货员              	130304	2020-09-04	业务外包	0	在职
820D668B-5E72-4930-8533-0032537B64E4	B7958     	2020      	1.0	NULL	NULL	NULL	2020-12-05 01:00:01.310	NULL	NULL	NULL	NULL	NULL	NULL	B4BE9556-761D-46F3-8235-9DDD006D4873	江西南昌拆零配货组	熊芳(离)	配货员              	090101	2019-09-01	合同工	1	离职
ED26D6BE-0FC4-4897-A81B-003A83A2865F	A1090     	2023      	5.0	5.0	0.0	NULL	2024-01-08 14:08:31.007	NULL	NULL	NULL	NULL	NULL	NULL	423B8428-E2B0-4150-A6B7-B99CBCA88585	江门现场督察组	梁焕华	复核员              	150107	2015-09-15	合同工	0	在职
79B0B74C-A70B-48AB-9D6B-003D84D4BC00	A5591     	2018      	6.0	NULL	NULL	NULL	2019-01-21 18:14:35.937	NULL	NULL	NULL	NULL	NULL	NULL	F8708CB4-77FB-4651-8C3E-FF38D2952992	佛山宅配组	汪志伟（外）(离)	驾驶员              	030302              	2017-08-23	承运商	1	离职
07261D27-8523-4946-AFAF-00401B09B533	C5819     	2025      	5.0	5.0	0.0	NULL	2025-12-02 00:00:02.280	NULL	NULL	4.0	1.0	0.0	2025-12-02 00:00:06.660	6778C93F-CA09-43BB-A592-7CD4CE9EBD42	贵州拆零组	刘宗香	配货员              	120204	2022-03-03	合同工	0	在职
27CCC135-8C33-4E31-B3EB-0041E4578227	A2767     	2018      	9.0	NULL	NULL	NULL	2019-12-28 11:00:19.127	NULL	NULL	NULL	NULL	NULL	NULL	035CB64D-2135-4994-883D-70D9562AFA1B	茶山拆零一区	罗寿益(离)	补货员	0102070401	2017-02-17	合同工	1	离职
D57BF811-C13F-4249-89B6-004F3A05D3F0	C0360     	2022      	5.0	5.0	0.0	NULL	2023-01-09 17:21:17.590	NULL	NULL	NULL	NULL	NULL	NULL	F1C29D2C-292E-4E66-8A69-57BE7AFE1164	茶山安全机务部	叶智超	安全管理员	01080601	2020-08-14	合同工	0	在职
973F3043-DB20-4402-A6CF-004FF151DE7D	A0339     	2021      	5.0	NULL	NULL	NULL	2022-01-15 09:07:09.763	NULL	NULL	NULL	NULL	NULL	NULL	5B524E51-BF1F-4738-9665-4CAFEFD76500	茶山配送二组	赵芬莲(外)	送货员              	0108050102	2013-01-29	承运商	0	在职