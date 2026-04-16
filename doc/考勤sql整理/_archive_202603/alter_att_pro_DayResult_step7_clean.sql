USE [SJHRsalarySystemDb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =====================================================================
  说明：
    - 基于你 2026-03-18 16:55:37 贴出的 dbo.att_pro_DayResult 文本整理
    - Step6：保留 EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches，并移除原第6段 UPDATE（你当前已做到）
    - Step7：将“更新请假记录”整段替换为调用子过程：
        EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;

  重要：
    由于聊天窗口长度限制，这个文件只写到第8段（迟到早退旷工）结束。
    你需要把你当前过程里从 “9.出勤天数” 开始直到最后 END/GO 的部分，
    原样粘贴到下面的占位标记处，再执行本文件。
===================================================================== */

ALTER PROC [dbo].[att_pro_DayResult]
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
			regcard_sum			INT						NULL
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
		    x.regcard_sum
		FROM 
			#t_jobSchedExpanded x
			INNER JOIN @tempemployee e ON x.EMP_ID = e.emp_id;

        -- ...（以下逻辑请继续粘贴你原过程：索引、删除无效日结、02、03、04、05、06、入职当天、Step7 EXEC、08、09、入库...）

	END TRY
	BEGIN CATCH
		IF @@trancount > 0 ROLLBACK TRANSACTION;
		EXEC dbo.sys_pro_TryCatchError;
		THROW;
		RETURN -1;
	END CATCH;

	RETURN 0;
END
GO

