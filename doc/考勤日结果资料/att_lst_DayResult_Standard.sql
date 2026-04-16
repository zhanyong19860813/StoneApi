USE [SJHRsalarySystemDb]
GO

/*
  表名：att_lst_DayResult_Standard
  说明：理论考勤日结果表（标准化结构），按 ReadMe 字段设计
  参考：理论考勤日结果.xlsx、考勤基本表结构说明.md
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.att_lst_DayResult_Standard','U') IS NOT NULL
  DROP TABLE [dbo].[att_lst_DayResult_Standard];
GO

CREATE TABLE [dbo].[att_lst_DayResult_Standard](
  [FID]                [uniqueidentifier] NOT NULL,
  [EMP_ID]             [nvarchar](50)     NULL,
  [EmpName]            [nvarchar](50)     NULL,
  [DeptID]             [uniqueidentifier] NULL,
  [DeptName]           [nvarchar](200)    NULL,
  [DutyID]             [uniqueidentifier] NULL,
  [DutyName]           [nvarchar](100)    NULL,
  [AttDate]            [date]             NULL,
  [WeekDay]            [nvarchar](10)     NULL,
  [ShiftType]          [nvarchar](200)    NULL,
  [IsShouldAttend]     [bit]              NULL,
  [ShouldStartTime]    [datetime]         NULL,
  [ShouldEndTime]      [datetime]         NULL,
  [ShouldAttHours]     [numeric](18,2)    NULL,
  [IsFlexShift]        [bit]              NULL,
  [PunchInTime]        [datetime]         NULL,
  [PunchOutTime]       [datetime]         NULL,
  [PunchCount]         [int]              NULL,
  [PunchMethod]        [nvarchar](50)     NULL,
  [IsMissingPunch]     [bit]              NULL,
  [HasApproval]        [bit]              NULL,
  [ApprovalType]       [nvarchar](100)    NULL,
  [ApprovalStatus]     [nvarchar](50)     NULL,
  [ModifyTime]         [datetime]         NULL,
  [OperatorName]       [nvarchar](50)     NULL,
  CONSTRAINT [PK_att_lst_DayResult_Standard] PRIMARY KEY CLUSTERED ([FID] ASC)
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[att_lst_DayResult_Standard] ADD CONSTRAINT [DF_DayResult_Standard_FID] DEFAULT (newid()) FOR [FID]
GO
ALTER TABLE [dbo].[att_lst_DayResult_Standard] ADD CONSTRAINT [DF_DayResult_Standard_ModifyTime] DEFAULT (getdate()) FOR [ModifyTime]
GO

-- 人员信息
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工编号，人员信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'EMP_ID'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工姓名，人员信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'EmpName'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'部门ID，人员信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'DeptID'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'部门名称，人员信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'DeptName'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'岗位ID，人员信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'DutyID'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'岗位名称，人员信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'DutyName'

-- 日期信息
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'日期，日期信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'AttDate'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'星期几，日期信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'WeekDay'

-- 班次信息
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班次类型，班次信息（暂忽略）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'ShiftType'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否应出勤，班次信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'IsShouldAttend'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'应上班时间，班次信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'ShouldStartTime'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'应下班时间，班次信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'ShouldEndTime'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'应出勤工时，班次信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'ShouldAttHours'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否弹性班，班次信息（暂留空）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'IsFlexShift'

-- 打卡信息
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'上班打卡时间，打卡信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'PunchInTime'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'下班打卡时间，打卡信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'PunchOutTime'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'打卡次数，打卡信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'PunchCount'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'打卡方式，打卡信息（默认人脸）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'PunchMethod'

-- 异常/审批信息
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否缺卡，异常/审批信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'IsMissingPunch'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否有审批单，异常/审批信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'HasApproval'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批类型，异常/审批信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'ApprovalType'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'审批状态，异常/审批信息' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'att_lst_DayResult_Standard', @level2type=N'COLUMN',@level2name=N'ApprovalStatus'
GO
