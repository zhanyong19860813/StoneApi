USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[t_base_employee]    Script Date: 2026/3/20 12:07:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_base_employee](
	[id] [uniqueidentifier] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[first_name] [varchar](20) NOT NULL,
	[pinyin] [varchar](50) NULL,
	[code] [varchar](10) NULL,
	[idcard_no] [nvarchar](50) NULL,
	[passport_no] [varchar](50) NULL,
	[gender] [varchar](10) NULL,
	[brith_date] [date] NULL,
	[nation] [varchar](20) NULL,
	[mobile_no] [varchar](150) NULL,
	[phone_no] [varchar](150) NULL,
	[type] [nvarchar](50) NULL,
	[doc_no] [varchar](50) NULL,
	[dept_id] [uniqueidentifier] NULL,
	[duty_id] [uniqueidentifier] NULL,
	[frist_join_date] [date] NULL,
	[status] [int] NULL,
	[add_user] [nvarchar](50) NULL,
	[add_time] [datetime] NULL,
	[join_job_date] [date] NULL,
	[leave_time] [date] NULL,
	[regularworker_time] [date] NULL,
	[retire_time] [date] NULL,
	[technology_id] [char](10) NULL,
	[employee_photo] [varchar](150) NULL,
	[hiredt] [date] NULL,
	[username] [varchar](100) NULL,
	[password] [varchar](100) NULL,
	[EMP_NormalDate] [datetime] NULL,
	[EMP_Education] [nvarchar](50) NULL,
	[EMP_TechLevel] [nvarchar](50) NULL,
	[aliMail] [nvarchar](50) NULL,
	[Addr] [nvarchar](300) NULL,
	[IDCardType] [nvarchar](50) NULL,
	[IDCardStartDate] [datetime] NULL,
	[IDCardEndDate] [datetime] NULL,
	[IDCardLicence] [nvarchar](100) NULL,
	[NativePlace] [nvarchar](300) NULL,
	[RecruitingChannel] [nvarchar](50) NULL,
	[School] [nvarchar](300) NULL,
	[PoliticalStatus] [nvarchar](50) NULL,
	[MaritalStatus] [nvarchar](20) NULL,
	[Contact] [nvarchar](50) NULL,
	[ContactTel] [varchar](50) NULL,
	[ContactAddr] [nvarchar](300) NULL,
	[ContractType] [nvarchar](50) NULL,
	[ContractStartDate] [datetime] NULL,
	[ContractEndDate] [datetime] NULL,
	[ContractPeriod] [int] NULL,
	[Reference] [varchar](10) NULL,
	[GradeLevel] [char](1) NULL,
	[ModifyTime] [datetime] NULL,
	[ModifyName] [nvarchar](50) NULL,
	[comp_id] [uniqueidentifier] NULL,
	[dingtalk_flag] [uniqueidentifier] NULL,
	[Remake] [nvarchar](300) NULL,
	[EMP_TimeCard] [varchar](100) NULL,
	[OASuperior] [varchar](50) NULL,
	[isPartyMember] [int] NULL,
	[isVeteran] [int] NULL,
	[ishandicapped] [int] NULL,
	[isMartyr] [int] NULL,
	[specialequipment] [nvarchar](100) NULL,
	[specialequipmentDate] [datetime] NULL,
	[specialequipmentPlace] [nvarchar](100) NULL,
	[InitiationState] [int] NULL,
	[InitiationTime] [date] NULL,
	[RetirementTime] [date] NULL,
	[doorban_photo] [nvarchar](200) NULL,
	[isAllowEntry] [int] NULL,
	[rank_id] [uniqueidentifier] NULL,
	[ProbationStartDate] [date] NULL,
	[ProbationEndDate] [date] NULL,
	[ProbationPeriod] [int] NULL,
	[nowAddr] [nvarchar](300) NULL,
	[PartyA] [varchar](100) NULL,
	[Specialty] [varchar](80) NULL,
	[entryInformation] [varchar](800) NULL,
	[isLowIncomeAid] [int] NULL,
	[isMilitary] [int] NULL,
	[isSingleParent] [int] NULL,
 CONSTRAINT [PK_t_base_employee] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [unique_code_t_base_employee] UNIQUE NONCLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[t_base_employee] ADD  CONSTRAINT [DF_t_base_employee_id]  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[t_base_employee] ADD  CONSTRAINT [DF_t_base_employee_status]  DEFAULT ((0)) FOR [status]
GO

ALTER TABLE [dbo].[t_base_employee] ADD  CONSTRAINT [DF_t_base_employee_InitiationState]  DEFAULT ((0)) FOR [InitiationState]
GO

ALTER TABLE [dbo].[t_base_employee] ADD  DEFAULT ((0)) FOR [isAllowEntry]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'姓名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'姓' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'first_name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工编码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'code'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'身份证' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'idcard_no'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'护照编码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'passport_no'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'性别' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'gender'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'生日' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'brith_date'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'民族' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'nation'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'手机号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'mobile_no'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'电话号码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'phone_no'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工类型' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'社保编码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'doc_no'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'所属部门' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'dept_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'职务' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'duty_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'参加工作日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'frist_join_date'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工状态(1.在职；2.不在职，3.离职，4.离退休)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'status'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'进本单位日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'join_job_date'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'离职日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'leave_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'转正日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'regularworker_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'退休日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'retire_time'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'技术职称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'technology_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工照片' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'employee_photo'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'地址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'Addr'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'证件类型' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'IDCardType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'身份证号开始日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'IDCardStartDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'身份证号截止日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'IDCardEndDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'发证机关' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'IDCardLicence'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'籍贯' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'NativePlace'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'招聘渠道' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'RecruitingChannel'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'毕业院校' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'School'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'政治面貌' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'PoliticalStatus'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'婚姻状况' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'MaritalStatus'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'紧急联系人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'Contact'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'紧急联系人电话' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'ContactTel'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'紧急联系人地址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'ContactAddr'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'合同类型' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'ContractType'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'合同开始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'ContractStartDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'合同结束时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'ContractEndDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'合同期限' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'ContractPeriod'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'介绍人' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'Reference'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'职等' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'GradeLevel'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'现居地址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'nowAddr'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否低保家属；1 是，0 否' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'isLowIncomeAid'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否军人家属；1 是，0 否' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'isMilitary'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否单亲家庭；1 是，0 否' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee', @level2type=N'COLUMN',@level2name=N'isSingleParent'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'员工表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_base_employee'
GO


USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_new]    Script Date: 2026/3/19 16:29:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER PROC [dbo].[att_pro_DayResult_new]
(
	@emp_list NVARCHAR(4000),	--工号串，或者部门id 
	@DayResultType NVARCHAR(10),--判断是按照工号查询还是 还是部门id 查询（0 表示按工号日结，1表示按部门日结）
	@attStartDate DATETIME,		--日结开始日期
	@attEndDate DATETIME,		--日结结束日期
	@op NVARCHAR(200)			--操作人
)
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON;
	BEGIN TRY

		DECLARE
			@op_emp_id NVARCHAR(20),
			@op_name NVARCHAR(30),
			@attMonth NVARCHAR(6), --日结月份
			@attDays INT, ---日结月份有多少天
			@AbsenteeismTime INT	--旷工时间,超过多少分钟为旷工


		SET @attMonth = CONVERT(NVARCHAR(6), @attStartDate, 112) 
		SET @attDays = DAY(DATEADD(MONTH, 1, @attMonth + '01 ') - 1)
		SET @AbsenteeismTime = 60

		IF(MONTH(@attStartDate) <> MONTH(@attEndDate))
			SET @attEndDate = DATEADD(MONTH, 1, @attMonth + '01 ') - 1;
		
		PRINT '1：' + CONVERT(NVARCHAR(20),GETDATE(),120)
  
		/***************************************************************************
									确定人员范围
		****************************************************************************/
		SELECT 
			@op_emp_id = code, 
			@op_name = 
				CASE 
					WHEN name = '张郁葱' 
					THEN '系统管理员' 
					ELSE name 
				END  
		FROM 
			dbo.t_base_employee 
		WHERE 
			(code = @op OR name LIKE '%'+@op+'%') 
			AND status=0;


		DECLARE @tempemployee table( 
			emp_id		CHAR(10)		NULL,
			dpm_id		NVARCHAR(50)	NULL,
			ps_id		NVARCHAR(50)	NULL
		)

		PRINT '开始时间：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		/* 纯重构：人员范围计算下沉到子过程，不改原逻辑 */
		INSERT INTO @tempemployee (emp_id, dpm_id, ps_id)
		EXEC dbo.att_pro_DayResult_GetEmployees
			@emp_list = @emp_list,
			@DayResultType = @DayResultType,
			@attMonth = @attMonth,
			@op_emp_id = @op_emp_id;

		PRINT '3：' + CONVERT(NVARCHAR(20),GETDATE(),120)
 
		/************************************************************************
			2.根据条件查询排班表，生成日结初始记录
		*************************************************************************/
		--声明临时表
		PRINT '插入临时表：'+CONVERT(NVARCHAR(20),GETDATE(),120);

		CREATE TABLE #t_att_lst_DayResult 
		(
			FID					UNIQUEIDENTIFIER		PRIMARY KEY,
			EMP_ID				CHAR(10)				NULL,
			dpm_id				NVARCHAR(50)			NULL,
			ps_id				NVARCHAR(50)			NULL,
			attDate				DATE					NULL,
			isHoliday			BIT						NULL,
			ShiftID				UNIQUEIDENTIFIER		NULL,
			attStatus			NVARCHAR(50)			NULL,
			attTime				NUMERIC(18,2)			NULL,
			attDay				NUMERIC(18,1)			NULL,
			attHolidayID		UNIQUEIDENTIFIER		NULL,
			attLate				NUMERIC(18,0)			NULL,
			attEarly			NUMERIC(18,0)			NULL,
			attAbsenteeism		NUMERIC(18,0)			NULL,
			attHoliday			NUMERIC(18,0)			NULL,
			attHolidayCategory	NVARCHAR(200)			NULL,
			attovertime15		NUMERIC(18,1)			NULL,
			attovertime20		NUMERIC(18,1)			NULL,
			attovertime30		NUMERIC(18,1)			NULL,
			BCST1				DATETIME				NULL,
			begin_time_tag1		INT						NULL,
			BCET1				DATETIME				NULL,
			end_time_tag1		INT						NULL,
			ST1					DATETIME				NULL,
			ET1					DATETIME				NULL,
			BCST2				DATETIME				NULL,
			begin_time_tag2		INT						NULL,
			BCET2				DATETIME				NULL,
			end_time_tag2		INT						NULL,
			ST2					DATETIME				NULL,
			ET2					DATETIME				NULL,
			errorMessage		NVARCHAR(200)			NULL,
			approval			INT						NULL,
			approvaler			NVARCHAR(50)			NULL,
			approvalTime		DATETIME				NULL,
			ModifyTime			DATETIME				NULL,
			OperatorName		NVARCHAR(50)			NULL,
			OperationTime		DATETIME				NULL,
			regcard_sum			INT						NULL,
			ApprovalType         nvarchar(50)           null,
			DateType         nvarchar(50)           null,
			AttendancePerformance         nvarchar(50)           null,
			OvertimeType         nvarchar(50)           null,
			ExceptionType         nvarchar(50)           null,
		);
		  
		

		/* 纯重构：排班 UNPIVOT 展开下沉到子过程，不改原逻辑 */
		IF OBJECT_ID('tempdb..#t_jobSchedExpanded') IS NOT NULL
			DROP TABLE #t_jobSchedExpanded;

		CREATE TABLE #t_jobSchedExpanded
		(
			EMP_ID CHAR(10) NOT NULL,
			attDate DATETIME NOT NULL,
			ShiftID UNIQUEIDENTIFIER NULL,
			attTime NUMERIC(18,2) NULL,
			attDay NUMERIC(18,1) NULL,
			attLate NUMERIC(18,0) NULL,
			attEarly NUMERIC(18,0) NULL,
			attAbsenteeism NUMERIC(18,0) NULL,
			regcard_sum INT NULL
		);




		EXEC dbo.att_pro_DayResult_ExpandJobScheduling
			@attMonth = @attMonth,
			@attDays = @attDays,
			@attStartDate = @attStartDate,
			@attEndDate = @attEndDate;

		--排班表 列转行，插入插入日结果表（纯重构：数据来自 #t_jobSchedExpanded）
		INSERT INTO  #t_att_lst_DayResult
		(
		    FID,
		    EMP_ID,
		    dpm_id,
		    ps_id,
		    attDate,
		    isHoliday,
		    ShiftID,
		    attStatus,
		    attTime,
		    attDay,
		    attHolidayID,
		    attLate,
		    attEarly,
		    attAbsenteeism,
		    attHoliday,
		    attHolidayCategory,
		    attovertime15,
		    attovertime20,
		    attovertime30,
		    BCST1,
		    begin_time_tag1,
		    BCET1,
		    end_time_tag1,
		    ST1,
		    ET1,
		    BCST2,
		    begin_time_tag2,
		    BCET2,
		    end_time_tag2,
		    ST2,
		    ET2,
		    errorMessage,
		    approval,
		    approvaler,
		    approvalTime,
		    ModifyTime,
		    OperatorName,
		    OperationTime,
		    regcard_sum
		)
		SELECT 
			NEWID() FID,
			x.EMP_ID,
		    e.dpm_id,
		    e.ps_id,
			x.attDate,
			NULL isHoliday,
			x.ShiftID,
			0 attStatus,
			x.attTime,
			x.attDay,
			CAST(NULL AS UNIQUEIDENTIFIER) attHolidayID,
			x.attLate,
			x.attEarly,
			x.attAbsenteeism,
			0 attHoliday,
			CAST( NULL AS NVARCHAR(50)) attHolidayCategory,
			0 attovertime15,
			0 attovertime20,
			0 attovertime30,
			CAST(NULL AS DATETIME) BCST1,
			NULL begin_time_tag1,
			CAST(NULL AS DATETIME) BCET1,
			NULL end_time_tag1 ,
			CAST(NULL AS DATETIME) ST1 ,
			CAST(NULL AS DATETIME) ET1 ,
			CAST(NULL AS DATETIME) BCST2 ,
			NULL begin_time_tag2 ,
			CAST(NULL AS DATETIME) BCET2 ,
			NULL end_time_tag2 ,
			CAST(NULL AS DATETIME) ST2 ,
			CAST(NULL AS DATETIME) ET2 ,
		    CAST( NULL AS NVARCHAR(2000)) errorMessage ,
            CAST( NULL AS NVARCHAR(200)) approval ,
			'' approvaler ,
			NULL approvalTime ,
			GETDATE() ModifyTime ,
			@op_name OperatorName ,
			GETDATE() OperationTime ,
		    x.regcard_sum   --漏打卡次数
		FROM 
			#t_jobSchedExpanded x
			INNER JOIN @tempemployee e ON x.EMP_ID = e.emp_id;

		/****** Object:  Index [index_attdate]    Script Date: 2022/8/18 11:22:23 ******/
		CREATE NONCLUSTERED INDEX index_t_att_lst_DayResult ON #t_att_lst_DayResult 
		(
			[attdate] ASC,
			[EMP_ID] ASC, 
			[ShiftID] ASC,
			[attStatus] ASC
		)WITH (
			PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
			DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
		) ON [PRIMARY];
 
		PRINT '给临时表创建索引：'+CONVERT(NVARCHAR(20),GETDATE(),120)



		--给 考勤计算算


		

		----删除当月入职日期之前，或者离职日期之后的无效日结果
		DELETE a 
		FROM 
			#t_att_lst_DayResult a,dbo.t_base_employee b 
		WHERE 
			a.EMP_ID=b.code 
			AND (a.attdate>b.leave_time OR a.attdate<b.frist_join_date )
			AND a.attdate BETWEEN @attStartDate AND @attEndDate;
	

		--排除原来已审核的	  日结果 
		DELETE a
		FROM 
			#t_att_lst_DayResult a
			LEFT JOIN dbo.att_lst_DayResult b ON a.EMP_ID=b.EMP_ID AND a.attDate=b.attdate AND b.attdate BETWEEN @attStartDate AND @attEndDate
			LEFT JOIN dbo.DingTalk_Lst_Process p ON b.PushAbsenteeism = p.BusinessId
		WHERE  
			ISNULL(b.approval,0)=1 OR p.Status IN ('NEW','RUNNING');--2023-11-08 有旷工流程正在进行的记录不日结

		 

		/************************************************************************
			3.更新出勤状态
		*************************************************************************/
		--休息班
		 
		----删除当月入职日期之前，或者离职日期之后的无效日结果
		DELETE a 
		FROM  
			dbo.att_lst_DayResult a
			INNER JOIN dbo.t_base_employee b ON a.EMP_ID = b.code 
		WHERE 
			(a.attdate > b.leave_time OR a.attdate < b.frist_join_date)
			AND ISNULL(a.approval,0)=0;



			  --生成 审批类型 

		  --update  #t_att_lst_DayResult set ApprovalType ='审批类型'

		  -- begin 更新 审批类型  所有请假都放进去 ApprovalType   
		  	--有薪假包括 年 婚 丧 出差，调休，产假，陪产假，工伤 , 育儿 , 探亲
		UPDATE	a 
		SET		
			a.attHolidayID=b.FID,
			a.attDay=1,
			a.attTime=8,
			a.attovertime30=0,
			a.attHoliday=1,
			attHolidayCategory=b.HC_ID,
            ApprovalType= c.HC_Name
		FROM	
			#t_att_lst_DayResult a
			INNER JOIN dbo.att_lst_Holiday b ON a.EMP_ID = b.EMP_ID
			INNER JOIN dbo.att_lst_HolidayCategory c ON b.HC_ID = c.HC_ID 
			--AND c.HC_Paidleave = 1
		WHERE 
			a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate
			--AND (b.HC_ID <> 'H10' OR DATEPART(WEEKDAY, a.attdate) <> 1)  --周日出差不算出勤  2024-03-01 zhanglinfu
		 -- end 更新 审批类型  所有请假都放进去 ApprovalType   

		/*********************************************************************************
			更新最终的日结果到正式表
		*********************************************************************************/

		INSERT INTO dbo.att_lst_DayResult
        ( 
			FID ,
			EMP_ID ,
			dpm_id,
			ps_id,
			attdate ,
			isHoliday ,
			ShiftID ,
			attStatus ,
			attTime ,
			attDay ,
			attHolidayID ,
			attLate ,
			attEarly ,
			attAbsenteeism ,
			attHoliday ,
			attHolidayCategory ,
			attovertime15 ,
			attovertime20 ,
			attovertime30 ,
			BCST1 ,
			begin_time_tag1 ,
			BCET1 ,
			end_time_tag1 ,
			ST1 ,
			ET1 ,
			BCST2 ,
			begin_time_tag2 ,
			BCET2 ,
			end_time_tag2 ,
			ST2 ,
			ET2 ,
			errorMessage,
			approval ,
			approvaler ,
			approvalTime ,
			ModifyTime ,
			OperatorName ,
			OperationTime,
			regcard_sum,
			ApprovalType         ,
			DateType        ,
			AttendancePerformance   ,
			OvertimeType         ,
			ExceptionType      
        )
		SELECT 
			NEWID() FID ,
			EMP_ID ,
			dpm_id,
			ps_id,
			attdate ,
            isHoliday ,
			ShiftID ,
			attStatus ,
			attTime ,
			attDay ,
			attHolidayID ,
			attLate ,
			attEarly ,
			attAbsenteeism ,
			attHoliday ,
            attHolidayCategory ,
			attovertime15 ,
			attovertime20 ,
			attovertime30 ,
			BCST1 ,
			begin_time_tag1 ,
			BCET1 ,
			end_time_tag1 ,
			ST1 ,
			ET1 ,
			BCST2 ,
			begin_time_tag2 ,
			BCET2 ,
			end_time_tag2 ,
			ST2 ,
			ET2 ,
			errorMessage,
			''approval ,
			''approvaler ,
			NULL approvalTime ,
			GETDATE() ModifyTime ,
			@op_name  ,
			GETDATE() OperationTime,
			regcard_sum ,
			ApprovalType         ,
			DateType        ,
			AttendancePerformance   ,
			OvertimeType         ,
			ExceptionType    
		FROM 
			#t_att_lst_DayResult;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@trancount > 0 ROLLBACK TRANSACTION;

		--写错误日志
		EXEC dbo.sys_pro_TryCatchError;

		THROW;
		RETURN -1;
	END CATCH;

	RETURN 0;
END
GO




--数据样本

select top  10 * from t_base_employee
C7ECFDDC-7168-C2D8-FA68-00012127F151	刘瑞(壹)(速聘)(离)	刘瑞	NULL	D0553	450803198704106616	NULL	0	1987-04-10	汉	18024704380		派遣工	NULL	3D6BF1CB-1615-4047-802E-D802CAEDB6EF	7245D0C0-5355-4D0B-903B-5E65C46485AA	2023-07-02	1	辜浩鑫	2023-07-01 15:38:33.740	NULL	2023-07-08	NULL	NULL	NULL	../../images/employeePhotos/D0553.jpg	NULL	NULL	NULL	2023-07-02 00:00:00.000	中专	NULL	NULL	广西贵港市港南区桥圩镇长塘村林塘屯16号	身份证	2017-04-10 00:00:00.000	2037-04-10 00:00:00.000	贵港市公安局港南分局	广西贵港市	中介市场				母亲	18176578737			NULL	NULL	3		O	2023-07-11 17:40:01.120	辜浩鑫	3CB339DE-AC6E-4FF3-95B2-D2672B04A81C	NULL				0	0	0	0		NULL		0	NULL	NULL	../../images/employeePhotos/D0553.jpg	0	NULL	NULL	NULL	6	NULL	NULL	NULL	NULL	NULL	NULL	NULL
11CA63B3-5E7D-0030-6587-0005D36845FF	张桥丽(离)	张桥丽	NULL	B6373	431127200211296028	NULL	1	2002-11-29	汉	19927612829		实习生	NULL	C4A1B213-974F-49A8-90E2-61701429D252	93DF5510-8892-4AF4-8A24-36FC0B28B08A	2019-06-28	1	何琳琳	2019-06-27 14:14:16.187	NULL	2020-04-14	NULL	NULL	NULL	../../images/employeePhotos/B6373.jpg	NULL	NULL	NULL	2019-08-01 00:00:00.000	中专	NULL	NULL	湖南省蓝山县塔峰镇排下村2组	身份证	2017-05-31 00:00:00.000	2022-05-31 00:00:00.000	蓝山县公安局	湖南省蓝山县	校园招聘	广东省经济贸易职业技术学校	群众		父女	19927629369		三方协议	NULL	NULL	3		L	2025-09-08 16:46:21.953	陈伟刚	3CB339DE-AC6E-4FF3-95B2-D2672B04A81C	NULL			NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	1	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
A761D4C9-5FC3-47D5-4B32-000833888125	唐阿明(离)	唐阿明	NULL	C1887	430523200201054354	NULL	0	2002-01-05	汉	13528668967		合同工	NULL	D0A219F7-A809-4DE1-AD97-8761A831626F	9CC4FBD6-4E5E-44CB-9B80-A4DCE8C56E5A	2021-03-08	1	陈伟刚	2021-03-08 09:45:50.733	NULL	2024-05-17	NULL	NULL	NULL	../../images/employeePhotos/C1887.jpg	NULL	NULL	NULL	2021-05-01 00:00:00.000	初中	NULL	tangaming@timeexpress.com.cn	湖南省邵阳县五峰铺镇东山村田中组	身份证	2021-12-28 00:00:00.000	2031-12-28 00:00:00.000	邵阳县公安局	湖南省邵阳县	直接招聘				蒋小兰	13712596702		固定期限合同	2022-01-01 00:00:00.000	2024-12-31 00:00:00.000	3		L	2024-05-18 16:30:02.767	辜浩鑫	80DFF6C4-952C-4FF0-A899-040FAF82C074	NULL			A6923	0	0	0	0		NULL		0	NULL	NULL	~/HRMFiles/JieLink/FaceImg/340b125b-45a1-4bf0-98e9-c7df3bed6f58.jpg	0	NULL	NULL	NULL	6		NULL	NULL	NULL	NULL	NULL	NULL
3F74284C-D03C-0DAA-71B2-000A42833680	潘龙(壹)(离)	潘龙	NULL	D2993	22010419860227063X	NULL	0	1986-02-27	汉	18343145257		合同工	NULL	4F758858-EB64-4E7E-81C0-18B6D509EC89	9082059E-E0F3-4971-97C1-050C0E208588	2024-04-10	1	骆比木牛	2024-04-09 15:17:22.093	NULL	2024-04-17	NULL	NULL	NULL	../../images/employeePhotos/D2993.jpg	NULL	NULL	NULL	NULL	初中	NULL	NULL	长春市朝阳区繁荣路6栋1门214号	身份证	2021-01-04 00:00:00.000	2041-01-04 00:00:00.000	长春市公安局朝阳分局	长春市	以前员工				父：潘志和	13578787778	长春市朝阳区繁荣路6栋1门214号	固定期限合同	2024-04-10 00:00:00.000	2027-04-09 00:00:00.000	3		L	2024-07-25 08:55:47.437	骆比木牛	4C467C32-5539-4AE7-81DC-47EF7D4005F8	NULL				0	0	0	0		NULL		0	NULL	NULL	../../images/employeePhotos/D2993.jpg	0	NULL	2024-04-10	2024-10-09	6	长春市朝阳区繁荣路6栋1门214号	惠州市时捷物流有限公司	NULL	NULL	NULL	NULL	NULL
DCB15E07-E632-410A-B5A9-000A6A8000D6	周莉(离)	周莉	zl	B0902     	430424200106188267	NULL	1	2001-06-18	汉	15989682096		合同工	NULL	035CB64D-2135-4994-883D-70D9562AFA1B	93DF5510-8892-4AF4-8A24-36FC0B28B08A	2018-08-31	1	00000000-0000-0000-0000-000000000000	2018-08-30 12:10:02.137	NULL	2019-03-14	NULL	NULL	NULL	../../images/employeePhotos/B0902.jpg	NULL	B0902     	430424200106188267	2018-10-01 00:00:00.000	初中      		NULL	湖南省衡东县石滩乡莲花村6组	身份证	2015-06-04 00:00:00.000	2020-06-04 00:00:00.000	衡东县公安局	湖南省衡东县	内部介绍	NULL	NULL	未婚	周诗全	18216039393	湖南省衡东县石滩乡莲花村6组	固定期限合同	2018-08-31 00:00:00.000	2021-08-30 00:00:00.000	3	A0453	NULL	2023-03-13 17:11:58.547	蔡亚岚	NULL	NULL	NULL		NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
A365CBD6-6DC1-2118-4BCE-000B14800C1B	白四铁(外)(离)	白四铁	NULL	C1766	430721196912191311	NULL	0	1969-12-19	汉	15575884581		业务外包	NULL	A8CCE0C4-918D-4898-A3F5-B389289B4617	94846540-FAB6-4482-AF3E-724DFBC58F6D	2021-03-01	1	高建仪	2021-03-01 14:15:55.190	NULL	2021-04-26	NULL	NULL	NULL	../../images/employeePhotos/C1766.jpg	NULL	NULL	NULL	NULL	高中	NULL	NULL	湖南省安乡县黄山头镇白家村10020号	身份证	2010-10-18 00:00:00.000	2030-10-18 00:00:00.000	安乡县公安局	湖南省安乡县	直接招聘				白洋	18673769381		三方协议	NULL	NULL	3		L	2023-03-13 17:11:58.547	高建仪	9C45AC84-1CFE-4F53-9CAC-E7FDB11610C8	NULL				NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
C247091B-3657-9304-97E3-000C431F4E24	胡晓燕(聚杰)(离)	胡晓燕	NULL	C6560	340122198107016925	NULL	1	1981-07-01	汉	15077921683		派遣工	NULL	2888A812-7383-4381-8661-DBD30CFF4757	7245D0C0-5355-4D0B-903B-5E65C46485AA	2022-05-01	1	刘兰兰	2022-05-09 15:31:46.927	NULL	2023-01-31	NULL	NULL	NULL	../../images/employeePhotos/C6560.jpg	NULL	NULL	NULL	2022-07-01 00:00:00.000	初中	NULL	NULL	安徽省肥西县严店乡油坊村栗树岗	身份证	2013-05-21 00:00:00.000	2033-05-21 00:00:00.000	肥西县公安局	安徽省合肥市	中介市场				马锋	15056254341		其他	2022-05-01 00:00:00.000	2023-04-30 00:00:00.000	1		O	2023-03-13 17:11:58.547	杨杰(伍)	0E5CACBA-775E-436F-A8F3-AF93CE8806C1	NULL				NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
0CAB7C38-D5D0-49DF-805F-000DDDC4EA11	徐威(离)	徐威	NULL	C4537	500238199109082193	NULL	0	1991-09-08	汉	15276105660		合同工	NULL	33D53033-7215-411F-8E3F-091E18AF08A7	C03914BF-4B78-44D3-9D50-B9FBD363A256	2021-10-09	1	蒋定芳	2021-10-08 15:03:47.607	NULL	2025-08-09	NULL	NULL	NULL	../../images/employeePhotos/C4537.jpg	NULL	NULL	NULL	2021-10-09 00:00:00.000	高中	NULL	NULL	重庆市巫溪县古路镇白家村3组41号附1号	身份证	2021-02-19 00:00:00.000	2041-02-19 00:00:00.000	巫溪县公安局	重庆市	以前员工		群众	已婚	姚支秀	13413037005		固定期限合同	2024-10-09 00:00:00.000	2027-10-08 00:00:00.000	3		L	2025-08-09 11:30:09.077	谢飞	4C467C32-5539-4AE7-81DC-47EF7D4005F8	NULL				NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	惠州市时捷物流有限公司	NULL	NULL	NULL	NULL	NULL
7B336589-A2F5-9E15-D318-000E8663D4F9	滕明胜(速聘)(离)	滕明胜	NULL	D3820	42282520060525081X	NULL	0	2006-05-25	土家	18171570284		派遣工	NULL	31FCE715-F4A3-45F6-88AA-84EDF6B0A19C	7245D0C0-5355-4D0B-903B-5E65C46485AA	2024-06-05	1	辜浩鑫	2024-06-04 15:21:45.743	NULL	2024-06-06	NULL	NULL	NULL	../../images/employeePhotos/D3820.jpg	NULL	NULL	NULL	NULL	初中	NULL	NULL	湖北省宣恩县李家河镇二虎寨村6组352号	身份证	2021-03-19 00:00:00.000	2026-03-19 00:00:00.000	宣恩县公安局	湖北省宣恩县	中介市场				驻:吴书径	19902638067			NULL	NULL	3		N	2024-06-06 17:40:10.647	辜浩鑫	3CB339DE-AC6E-4FF3-95B2-D2672B04A81C	NULL				0	0	0	0		NULL		0	NULL	NULL	../../images/employeePhotos/D3820.jpg	0	NULL	NULL	NULL	6		广东茶山时捷物流有限公司	NULL	NULL	NULL	NULL	NULL
FD647CC5-DCF0-47A2-8481-0011F9A94E47	王永刚(离)	王永刚	WYG	AA00593465	412702198004035573	NULL	0	1980-04-03			NULL		NULL	54E2083B-BC1E-4A47-9F6C-AFFE4A3C8E87	3E5524DC-D418-4301-B261-5835407D275B	2005-12-31	1	00000000-0000-0000-0000-000000000000	2018-08-02 19:47:15.487	NULL	2006-01-02	NULL	NULL	NULL	../../images/employeePhotos/AA00593465.jpg	NULL	AA00593465	412702198004035573	NULL	初中      	NULL	NULL		身份证	NULL	NULL					NULL	未婚					NULL	NULL	NULL		NULL	2023-03-13 17:11:58.547	人众同步	NULL	C16C24CA-2451-4DF2-AA50-AF0188B2B4B3	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL

