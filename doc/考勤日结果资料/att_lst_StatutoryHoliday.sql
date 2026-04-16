


 USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[att_lst_StatutoryHoliday]    Script Date: 2026/3/20 14:16:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[att_lst_StatutoryHoliday](
	[FID] [uniqueidentifier] NOT NULL,
	[Holidaydate] [date] NULL,
	[explain] [varchar](10) NULL,
	[IsHoliday] [bit] NULL,
	[OperatorName] [char](10) NULL,
	[OperationTime] [datetime] NULL,
 CONSTRAINT [PK_att_lst_StatutoryHoliday] PRIMARY KEY CLUSTERED 
(
	[FID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_StatutoryHoliday] ADD  CONSTRAINT [DF_att_lst_StatutoryHoliday_FID]  DEFAULT (newid()) FOR [FID]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'主键' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_StatutoryHoliday', @level2type=N'COLUMN',@level2name=N'FID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'假别日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_StatutoryHoliday', @level2type=N'COLUMN',@level2name=N'Holidaydate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'说明' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_StatutoryHoliday', @level2type=N'COLUMN',@level2name=N'explain'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否法定假日' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_StatutoryHoliday', @level2type=N'COLUMN',@level2name=N'IsHoliday'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'操作人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_StatutoryHoliday', @level2type=N'COLUMN',@level2name=N'OperatorName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'操作时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_StatutoryHoliday', @level2type=N'COLUMN',@level2name=N'OperationTime'
GO



 --数据样本
select  top  15 * from  att_lst_StatutoryHoliday order by OperationTime desc

38AFBDF6-C131-4756-A351-8832C01B7E3D	2025-10-06	中秋节	1	李文静    	2024-12-30 09:45:22.000
25892824-C7CE-4DED-8789-B845259A3529	2025-10-03	国庆节	1	李文静    	2024-12-30 09:44:29.000
68076162-D0A2-4521-BA81-0F9C3579EC3F	2025-10-02	国庆节	1	李文静    	2024-12-30 09:44:14.000
8129FC94-A8A3-4C54-9B05-CD67F59F10D5	2025-10-01	国庆节	1	李文静    	2024-12-30 09:43:58.000
7AB5EA90-6DAE-4C00-A6DA-EBC3419BCDBA	2025-05-31	端午节	1	李文静    	2024-12-30 09:08:48.000
8BE9E714-5C0C-435E-8C15-E61E46775EBC	2025-05-02	劳动节	1	李文静    	2024-12-30 09:07:38.000
71293C2C-C2D9-4007-8219-FFE6B60D489A	2025-05-01	劳动节	1	李文静    	2024-12-30 09:07:10.000
4934EA0F-6C8D-4705-852C-8472E75A808D	2025-04-04	清明	1	李文静    	2024-12-30 09:06:24.000
DB2D6AF2-42D7-41C4-9F78-112B423EB4FD	2025-01-31	春节	1	李文静    	2024-12-30 09:05:33.000
0CF0D976-8074-45A2-A56C-6D7E1B5BAD7B	2025-01-30	春节	1	李文静    	2024-12-30 09:05:20.000
B13DABD0-B5E5-474B-8881-8CD3AF12EB53	2025-01-29	春节	1	李文静    	2024-12-30 09:04:39.000
05A609FB-2ACD-4DA3-8EA2-9689A6825BC8	2025-01-28	除夕	1	李文静    	2024-12-30 09:04:15.000
C0837D27-A93A-4695-BE21-BD2DEF85E942	2025-01-01	元旦	1	李文静    	2024-12-30 09:03:44.000
117F18F3-02B2-4B56-A5D2-7967E0177DB7	2024-10-03	国庆节	1	李文静    	2023-12-26 11:07:42.000
F53419A8-AB95-4FEE-A8FD-ADA035CBEF9F	2024-10-02	国庆节	1	李文静    	2023-12-26 11:07:25.000


--视图 和数据样本
ALTER VIEW [dbo].[v_att_lst_StatutoryHoliday]
AS
    SELECT  a.FID ,
            CONVERT(CHAR(10), a.Holidaydate) Holidaydate ,
            a.explain ,
            a.IsHoliday ,
            b.name AS IsHolidayName ,
            a.OperatorName ,
            a.OperationTime ,
            DATENAME(YEAR, Holidaydate) HolidaydateYear
    FROM    att_lst_StatutoryHoliday a
            JOIN v_data_base_dictionary_detail b ON b.code = 'YN'
                                                    AND a.IsHoliday = b.value; 





GO

select * from v_att_lst_StatutoryHoliday
select  top 5 * from v_att_lst_StatutoryHoliday order by OperationTime desc
38AFBDF6-C131-4756-A351-8832C01B7E3D	2025-10-06	中秋节	1	是	李文静    	2024-12-30 09:45:22.000	2025
25892824-C7CE-4DED-8789-B845259A3529	2025-10-03	国庆节	1	是	李文静    	2024-12-30 09:44:29.000	2025
68076162-D0A2-4521-BA81-0F9C3579EC3F	2025-10-02	国庆节	1	是	李文静    	2024-12-30 09:44:14.000	2025
8129FC94-A8A3-4C54-9B05-CD67F59F10D5	2025-10-01	国庆节	1	是	李文静    	2024-12-30 09:43:58.000	2025
7AB5EA90-6DAE-4C00-A6DA-EBC3419BCDBA	2025-05-31	端午节	1	是	李文静    	2024-12-30 09:08:48.000	2025