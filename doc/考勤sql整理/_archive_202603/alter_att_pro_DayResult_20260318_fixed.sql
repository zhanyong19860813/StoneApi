USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult]    Script Date: 2026/3/18 17:19:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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

		/***********************************************************
			* 02.获取职务调动时所设置的计薪职务
		***********************************************************/

		UPDATE a 
		SET 
			a.dpm_id = b.EWM_bfDepartment,
			a.ps_id = b.EWM_bfPost
		FROM 
			#t_att_lst_DayResult a
			LEFT JOIN dbo.RS_Func_EmpWorkMove(@attStartDate,DATEADD(DAY,1,@attEndDate)) b 
				ON a.EMP_ID = b.EMP_ID AND a.attdate >= ISNULL(b.BeginDate,@attStartDate) AND  a.attdate < ISNULL(b.EndDate,@attEndDate)
		WHERE 
			b.EWM_bfDepartment IS NOT NULL;

		/************************************************************************
			3.更新出勤状态
		*************************************************************************/
		--休息班
		UPDATE a 
		SET 
			a.attStatus=99
		FROM  
			#t_att_lst_DayResult a
		WHERE 
			a.ShiftID='00000000-0000-0000-0000-000000000000';

		--法定假日
		UPDATE a 
		SET 
			a.attStatus=4
		FROM  
			#t_att_lst_DayResult a,[dbo].[att_lst_StatutoryHoliday] b
		WHERE 
			a.attdate=b.Holidaydate;
	  
		--班次设定时间段（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_UpdateShiftIntervals;

		PRINT '更新出勤状态：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		/************************************************************************
			4.更新刷卡记录
		*************************************************************************/

		--更新刷卡记录（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_UpdateCardRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
	
		/* 更新加班记录（纯重构：下沉到子过程） */
		EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;

		-- 单次刷卡归属重判（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;

		/**
			6.如果班次内只打了一次卡，则要重新验证该次卡 是属于上班卡还是下班卡
			增加三分钟以内的刷卡记录合并为一次刷卡
		_____________________________________________________________________*/
	 
		-- Step6原始UPDATE已删除：改由 dbo.att_pro_DayResult_RejudgeSingleCardPunches 负责

		PRINT '重新更新入职当天的上班卡：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		/**4.入职当天的上班卡，默认是班次设定的上班卡，因为通常是很难打到卡，容易出现第一天上班是旷工的情况*/ 
		UPDATE a 
		SET 
			a.ST1=DATEADD(dd,DATEDIFF(dd,a.BCST1,b.frist_join_date),a.BCST1) ,
			a.ST2=a.BCST2
		FROM 
			#t_att_lst_DayResult a,
			dbo.t_base_employee b ,
			dbo.att_lst_time_interval c
		WHERE 
			a.EMP_ID=b.code AND a.attdate=b.frist_join_date 
			AND a.ShiftID=c.pb_code_fid AND c.sec_num=1 AND c.begin_time_slot_card=1
			AND a.attdate BETWEEN @attStartDate AND @attEndDate 
			AND (a.ST1 IS NULL OR a.ST1>DATEADD(dd,DATEDIFF(dd,a.BCST1,b.frist_join_date),a.BCST1));

		/************************************************************************
			7.更新请假记录
		*************************************************************************/
		-- 更新请假记录（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
	  
	    PRINT '结束更新请假记录：'+CONVERT(NVARCHAR(20),GETDATE(),120)
	  

		/************************************************************************
			8.迟到早退旷工
		*************************************************************************/
		--迟到
		UPDATE a 
		SET 
			a.attLate=DATEDIFF(mi,DATEADD(dd,DATEDIFF(dd,a.BCST1,a.attdate)+a.begin_time_tag1,a.BCST1),a.ST1),
			a.attStatus=1
		FROM 
			#t_att_lst_DayResult a ,
			dbo.att_lst_time_interval c
		WHERE 
			1=1 AND a.ShiftID=c.pb_code_fid AND c.sec_num=1 AND c.begin_time_slot_card=1
			AND a.ST1 IS NOT NULL AND a.BCST1 IS NOT NULL
			AND DATEADD(dd,DATEDIFF(dd,a.BCST1,a.attdate)+a.begin_time_tag1,a.BCST1)<a.st1
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );

  
		--早退 
		UPDATE a 
		SET 
			a.attEarly=DATEDIFF(mi,a.ET1,DATEADD(dd,DATEDIFF(dd,a.BCET1,a.attdate)+a.end_time_tag1 ,a.BCET1)),
			a.attStatus=2
		FROM 
			#t_att_lst_DayResult a ,
			dbo.att_lst_time_interval c
		WHERE 
			1=1 AND a.ShiftID=c.pb_code_fid AND c.sec_num=1 AND c.end_time_slot_card=1
			AND a.ET1 IS NOT NULL AND a.BCET1 IS NOT NULL
			AND DATEADD(dd,DATEDIFF(dd,a.BCET1,a.attdate)+a.end_time_tag1 ,a.BCET1)>a.et1
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );
  
		--旷工，errormessage 
		UPDATE a 
		SET 
			a.attAbsenteeism=1 ,
			a.attLate=0,
			a.attEarly=0,
			a.attStatus=3,
			a.attovertime30=0,
			a.errorMessage = 
				CASE 
					WHEN ISNULL(a.ST1,0) = 0 AND ISNULL(a.ET1,0) <> 0 THEN '漏打卡' 
					WHEN ISNULL(a.ST1,0) <> 0 AND ISNULL(a.ET1,0) = 0  THEN '漏打卡' 
					WHEN ISNULL(a.ST1,0) = 0 AND ISNULL(a.ET1,0) = 0  THEN '没有刷卡记录' 
					WHEN ISNULL(a.ST1,0) <> 0 AND ISNULL(a.ET1,0) <> 0  THEN '迟到或者早退时间超过60分钟' 
					ELSE '' 
				END
		FROM 
			#t_att_lst_DayResult a,
			dbo.att_lst_time_interval b
		WHERE 
			a.attdate BETWEEN @attStartDate AND @attEndDate 
			AND a.ShiftID=b.pb_code_fid AND b.sec_num=1 
			AND (
				(b.begin_time_slot_card=1 AND a.ST1 IS NULL) 
				OR ( b.end_time_slot_card=1 AND a.ET1 IS NULL) 
				OR a.attLate > @AbsenteeismTime OR a.attEarly > @AbsenteeismTime  
			)
			AND ISNULL(a.attHoliday,0)=0
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );

		--刷卡未排班的情况，状态值等于 8  
		UPDATE a 
		SET 
			a.attStatus=8
		FROM 
			#t_att_lst_DayResult a 
		WHERE 
			(a.ST1 IS NOT NULL and a.ET1 IS NOT NULL )
			AND a.ShiftID IN ('00000000-0000-0000-0000-000000000000' )
			AND (a.attStatus=99 OR attStatus=4);

		PRINT '结束迟到早退旷工：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		/************************************************************************
			9.出勤天数
			...只有有排班，并且没有旷工 就算出勤天，另外假日加班，节日加班都算出勤天，
			没排班
		*************************************************************************/
		UPDATE a 
		SET 
			a.attDay=1
		FROM 
			#t_att_lst_DayResult a
		WHERE 
			a.attdate BETWEEN @attStartDate AND @attEndDate 
			AND a.attAbsenteeism=0 
			AND a.ShiftID <> '00000000-0000-0000-0000-000000000000';

		--班次不存在
		UPDATE a 
		SET 
			a.attStatus=8,
			a.attDay=0
		FROM  
			#t_att_lst_DayResult a 
			LEFT JOIN dbo.att_lst_BC_set_code b ON a.ShiftID=b.FID
		WHERE 
			a.FID IS NOT NULL 
			AND a.ShiftID <> '00000000-0000-0000-0000-000000000000' 
			AND b.FID IS NULL;

		---请了无薪假也不能算出勤天数
 		UPDATE a 
		SET  
			a.attDay=0 
		FROM 
			#t_att_lst_DayResult a,
			[dbo].[att_lst_Holiday] b 
		WHERE 
			a.EMP_ID=b.EMP_ID 
			AND (a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate)
			AND b.HC_ID IN (SELECT HC_ID FROM [dbo].[att_lst_HolidayCategory] WHERE HC_Paidleave=0);
  
		PRINT '结束出勤天数统计：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		--更新漏打卡签卡次数
		UPDATE t
		SET    
			regcard_sum = y.regcard_sum
		FROM   
			#t_att_lst_DayResult t ,
            ( 
				SELECT    
					c.EMP_ID ,
                    c.attDate ,
                    COUNT(1) regcard_sum
				FROM      
					( 
						SELECT    
							a.EMP_ID ,
                            a.attDate
                        FROM      
							#t_att_lst_DayResult a
                            JOIN dbo.att_lst_Cardrecord b ON a.EMP_ID = b.EMP_ID
								AND ( 
									a.ST1 = DATEADD(dd,DATEDIFF(dd,b.SlotCardTime,b.SlotCardDate),b.SlotCardTime)
									OR a.ET1 = DATEADD(dd,DATEDIFF(dd,b.SlotCardTime,b.SlotCardDate),b.SlotCardTime)
								) AND b.CardReason = '漏打卡' AND ISNULL(b.AppState,'') = 1 
								AND a.attStatus <> 99  --休息状态不更新签卡次数
                          GROUP BY  a.EMP_ID ,
                                    a.attDate ,
                                    b.SlotCardDate ,
                                    b.SlotCardTime
                        ) c
				GROUP BY  c.EMP_ID ,
                        c.attDate
			) y
		WHERE 
			t.EMP_ID = y.EMP_ID
			AND t.attDate = y.attDate
            AND t.attDate BETWEEN @attStartDate AND @attEndDate
			AND t.ShiftID NOT IN (SELECT pb_code_fid FROM dbo.att_lst_time_interval WHERE begin_time_slot_card=0 and end_time_slot_card=0);  --排除固定班次
  

		BEGIN TRANSACTION;

		/************************************************************************
				1.删除已存在的日结记录(已审核的日结果 不再删除)
		*************************************************************************/
		DELETE a 
		FROM 
			dbo.att_lst_DayResult a
			LEFT JOIN dbo.DingTalk_Lst_Process p ON a.PushAbsenteeism = p.BusinessId
		WHERE 
			a.attdate >= @attStartDate AND a.attdate <= @attEndDate
			AND EXISTS(SELECT 1 FROM @tempemployee emp WHERE emp.emp_id = a.EMP_ID)
			AND ISNULL(a.approval,0) = 0 AND (p.Status IS NULL OR p.Status NOT IN ('NEW','RUNNING'));--2023-11-08 有旷工流程正在进行的记录不日结
	 
		----删除当月入职日期之前，或者离职日期之后的无效日结果
		DELETE a 
		FROM  
			dbo.att_lst_DayResult a
			INNER JOIN dbo.t_base_employee b ON a.EMP_ID = b.code 
		WHERE 
			(a.attdate > b.leave_time OR a.attdate < b.frist_join_date)
			AND ISNULL(a.approval,0)=0;

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
			regcard_sum
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
			regcard_sum 
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

