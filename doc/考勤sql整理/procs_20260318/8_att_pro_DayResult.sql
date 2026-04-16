USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult]    Script Date: 2026/3/18 18:02:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
  att_pro_DayResult（主日结过程）
  用途：按人员/部门 + 日期范围，计算并落地每日考勤结果。

  当前实现要点：
  - 先生成日结临时明细，再按规则计算迟到、早退、漏打卡、旷工与加班；
  - 段状态（attStatus1/2/3）保持“段内真实异常”，总状态（attStatus）表达全日最终结论；
  - 迟到/早退/旷工阈值优先取班次配置，未配置时回退默认值；
  - 该过程单次按月份边界执行，跨月请由调用方分月调用。
*/

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
			@DefaultLateAllowMinutes INT,      --默认迟到允许值（分）
			@DefaultEarlyAllowMinutes INT,     --默认早退允许值（分）
			@DefaultAbsenteeismMinutes INT     --默认旷工阈值（分）


		SET @attMonth = CONVERT(NVARCHAR(6), @attStartDate, 112) 
		SET @attDays = DAY(DATEADD(MONTH, 1, @attMonth + '01 ') - 1)
		SET @DefaultLateAllowMinutes = 0
		SET @DefaultEarlyAllowMinutes = 0
		SET @DefaultAbsenteeismMinutes = 60

		IF(MONTH(@attStartDate) <> MONTH(@attEndDate))
			SET @attEndDate = DATEADD(MONTH, 1, @attMonth + '01 ') - 1;
		
		PRINT '1：' + CONVERT(NVARCHAR(20),GETDATE(),120)
  
		/***************************************************************************
			1. 操作员解析 + 日结人员范围
			- 由 att_pro_DayResult_GetEmployees 按 @DayResultType 解析工号列表或部门，写入 @tempemployee。
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
			2. 排班展开 → 生成日结临时表 #t_att_lst_DayResult
			说明：
			- 先由子过程按 JS_Month 把 JobScheduling 的 Day1~Day31 列转行到 #t_jobSchedExpanded；
			- 再与人员范围 @tempemployee 关联，写入每人每天的初始行（BCST/ST 等均为空，待后续步骤填充）；
			- attStatus 初值 0；regcard_sum 来自排班展开逻辑中的漏打卡计数（若有）。
		*************************************************************************/
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
			BCST3				DATETIME				NULL,
			begin_time_tag3		INT						NULL,
			BCET3				DATETIME				NULL,
			end_time_tag3		INT						NULL,
			ST3					DATETIME				NULL,
			ET3					DATETIME				NULL,
			attStatus1			INT					NULL,
			attStatus2			INT					NULL,
			attStatus3			INT					NULL,
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
		    BCST3,
		    begin_time_tag3,
		    BCET3,
		    end_time_tag3,
		    ST3,
		    ET3,
		    attStatus1,
		    attStatus2,
		    attStatus3,
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
			CAST(NULL AS DATETIME) BCST3 ,
			NULL begin_time_tag3 ,
			CAST(NULL AS DATETIME) BCET3 ,
			NULL end_time_tag3 ,
			CAST(NULL AS DATETIME) ST3 ,
			CAST(NULL AS DATETIME) ET3 ,
			NULL attStatus1 ,
			NULL attStatus2 ,
			NULL attStatus3 ,
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

		-- 临时表：剔除入职前、离职后的日期行（与员工档案日期对齐）
		DELETE a 
		FROM 
			#t_att_lst_DayResult a,dbo.t_base_employee b 
		WHERE 
			a.EMP_ID=b.code 
			AND (a.attdate>b.leave_time OR a.attdate<b.frist_join_date )
			AND a.attdate BETWEEN @attStartDate AND @attEndDate;
	

		-- 已审核日结果、或旷工推送流程进行中的记录：不参与本次重算（避免覆盖审批/流程数据）
		DELETE a
		FROM 
			#t_att_lst_DayResult a
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
			LEFT JOIN dbo.att_lst_DayResult b ON a.EMP_ID=b.EMP_ID AND a.attDate=b.attdate AND b.attdate BETWEEN @attStartDate AND @attEndDate
			LEFT JOIN dbo.DingTalk_Lst_Process p ON b.PushAbsenteeism = p.BusinessId
		WHERE  
			ISNULL(b.approval,0)=1 OR p.Status IN ('NEW','RUNNING');--2023-11-08 有旷工流程正在进行的记录不日结

		/***********************************************************
			02. 职务调动：按调动区间回填计薪用部门/岗位（dpm_id、ps_id）
			与 t_base_employee 快照不同，此处取 RS_Func_EmpWorkMove 在区间内的记录。
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
			3. 出勤状态预处理（在刷卡配对之前）
			顺序：休息班 → 法定假日 → 班次时段（BCST/BCET、时间标签写入临时表）
		*************************************************************************/
		-- 休息班：全零 GUID，不参与正常考勤计算
		UPDATE a 
		SET 
			a.attStatus=99
		FROM  
			#t_att_lst_DayResult a
		WHERE 
			a.ShiftID='00000000-0000-0000-0000-000000000000';

		-- 法定假日：先标 attStatus=4（后续刷卡/请假等可能再调整）
		UPDATE a 
		SET 
			a.attStatus=4
		FROM  
			#t_att_lst_DayResult a,[dbo].[att_lst_StatutoryHoliday] b
		WHERE 
			a.attdate=b.Holidaydate;
	  
		-- 从 att_lst_time_interval 写入计划上下班时间及时段标签（支持跨天多段）
		EXEC dbo.att_pro_DayResult_UpdateShiftIntervals;

		PRINT '更新出勤状态：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		/************************************************************************
			4~6. 刷卡配对、加班下沉、单卡重判
			- UpdateCardRecords：按有效窗口把 att_lst_Cardrecord 落到 ST1~ST3 / ET1~ET3；
			- UpdateOvertimeRecords：有加班申请且满足班次 overtime_start_minutes 时写加班标记与状态；
			- RejudgeSingleCardPunches：仅打一次卡时重判归属上班或下班（含短时合并逻辑在子过程内）。
		*************************************************************************/

		EXEC dbo.att_pro_DayResult_UpdateCardRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
	
		EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;

		EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;

		-- （原 Step6 大段 UPDATE 已迁入 RejudgeSingleCardPunches，见上文说明）

		PRINT '重新更新入职当天的上班卡：'+CONVERT(NVARCHAR(20),GETDATE(),120)

		-- 入职当日：若无上班打卡或打卡晚于计划，将 ST1 视为“按计划上班”（避免首日必旷工）
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
			7. 请假：与 att_lst_Holiday 等关联，影响出勤天、假期类别等（逻辑在子过程）
		*************************************************************************/
		EXEC dbo.att_pro_DayResult_UpdateHolidayRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;
	  
	    PRINT '结束更新请假记录：'+CONVERT(NVARCHAR(20),GETDATE(),120)
	  

		/************************************************************************
			8. 迟到、早退、旷工（核心计算）
			约定：
			- 阈值取自 att_lst_BC_set_code；为 NULL 时迟到/早退用 @DefaultLateAllowMinutes/@DefaultEarlyAllowMinutes，
			  旷工用 @DefaultAbsenteeismMinutes（与迟到+早退分钟数之和比较）；
			- 段状态 attStatus1/2/3：表示该段真实异常（正常0/迟到1/早退2/漏打卡3），不因“合计达旷工阈值”而改成旷工；
			- 总状态 attStatus：本段 UPDATE 按顺序执行，后执行的语句会覆盖前面的 attStatus（如先迟到后早退则显示早退）；
			- 第2、3段“迟到”仅写对应段状态；attLate 字段主要由第1段上班迟到与第1段下班早退等语句维护（与历史逻辑一致）。
		*************************************************************************/
		-- 初始化段状态：存在对应 sec_num 时段则置 0（正常），后续迟到/早退/旷工再覆盖
		UPDATE a SET a.attStatus1=0
		FROM #t_att_lst_DayResult a
		WHERE a.attdate BETWEEN @attStartDate AND @attEndDate
			AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000')
			AND a.attStatus NOT IN (99,4)
			AND EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=1);

		UPDATE a SET a.attStatus2=0
		FROM #t_att_lst_DayResult a
		WHERE a.attdate BETWEEN @attStartDate AND @attEndDate
			AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000')
			AND a.attStatus NOT IN (99,4)
			AND EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=2);

		UPDATE a SET a.attStatus3=0
		FROM #t_att_lst_DayResult a
		WHERE a.attdate BETWEEN @attStartDate AND @attEndDate
			AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000')
			AND a.attStatus NOT IN (99,4)
			AND EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=3);

		-- 迟到：第1段上班卡；实际打卡晚于「计划上班时间+ begin_time_tag1」且超出 late_allow 则 attLate=相差分钟，attStatus/attStatus1=1
		UPDATE a 
		SET 
			a.attLate=DATEDIFF(mi,DATEADD(dd,DATEDIFF(dd,a.BCST1,a.attdate)+a.begin_time_tag1,a.BCST1),a.ST1),
			a.attStatus=1,
			a.attStatus1=1
		FROM 
			#t_att_lst_DayResult a
			JOIN dbo.att_lst_time_interval c ON a.ShiftID=c.pb_code_fid
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			c.sec_num=1 AND c.begin_time_slot_card=1
			AND a.ST1 IS NOT NULL AND a.BCST1 IS NOT NULL
			AND DATEDIFF(mi,DATEADD(dd,DATEDIFF(dd,a.BCST1,a.attdate)+a.begin_time_tag1,a.BCST1),a.ST1) > ISNULL(bc.late_allow_minutes,@DefaultLateAllowMinutes)
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );

		-- 迟到：第2段上班卡（四次卡下午上班）；不写 attLate，仅 attStatus=1 且 attStatus2=1
		UPDATE a 
		SET 
			a.attStatus=1,
			a.attStatus2=1
		FROM 
			#t_att_lst_DayResult a
			JOIN dbo.att_lst_time_interval c ON a.ShiftID=c.pb_code_fid
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			c.sec_num=2 AND c.begin_time_slot_card=1
			AND a.ST2 IS NOT NULL AND a.BCST2 IS NOT NULL
			AND DATEDIFF(mi,DATEADD(dd,DATEDIFF(dd,a.BCST2,a.attdate)+ISNULL(a.begin_time_tag2,0),a.BCST2),a.ST2) > ISNULL(bc.late_allow_minutes,@DefaultLateAllowMinutes)
			AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000' );

  
		-- 早退：第1段下班卡；实际打卡早于「计划下班+ end_time_tag1」且超出 early_allow 则计 attEarly，attStatus/attStatus1=2
		UPDATE a 
		SET 
			a.attEarly=DATEDIFF(mi,a.ET1,DATEADD(dd,DATEDIFF(dd,a.BCET1,a.attdate)+a.end_time_tag1 ,a.BCET1)),
			a.attStatus=2,
			a.attStatus1=2
		FROM 
			#t_att_lst_DayResult a
			JOIN dbo.att_lst_time_interval c ON a.ShiftID=c.pb_code_fid
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			c.sec_num=1 AND c.end_time_slot_card=1
			AND a.ET1 IS NOT NULL AND a.BCET1 IS NOT NULL
			AND DATEDIFF(mi,a.ET1,DATEADD(dd,DATEDIFF(dd,a.BCET1,a.attdate)+a.end_time_tag1 ,a.BCET1)) > ISNULL(bc.early_allow_minutes,@DefaultEarlyAllowMinutes)
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );

		-- 早退：第2段下班卡；写 attEarly（与第1段共用字段累加场景需注意执行顺序），attStatus=2，attStatus2=2
		UPDATE a 
		SET 
			a.attEarly=DATEDIFF(mi,a.ET2,DATEADD(dd,DATEDIFF(dd,a.BCET2,a.attdate)+a.end_time_tag2,a.BCET2)),
			a.attStatus=2,
			a.attStatus2=2
		FROM 
			#t_att_lst_DayResult a
			JOIN dbo.att_lst_time_interval c ON a.ShiftID=c.pb_code_fid
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			c.sec_num=2 AND c.end_time_slot_card=1
			AND a.ET2 IS NOT NULL AND a.BCET2 IS NOT NULL
			AND DATEDIFF(mi,a.ET2,DATEADD(dd,DATEDIFF(dd,a.BCET2,a.attdate)+a.end_time_tag2,a.BCET2)) > ISNULL(bc.early_allow_minutes,@DefaultEarlyAllowMinutes)
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );

		-- 迟到：第3段上班卡（六次卡第三段）；不写 attLate，仅 attStatus=1 且 attStatus3=1
		UPDATE a 
		SET 
			a.attStatus=1,
			a.attStatus3=1
		FROM 
			#t_att_lst_DayResult a
			JOIN dbo.att_lst_time_interval c ON a.ShiftID=c.pb_code_fid
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			c.sec_num=3 AND c.begin_time_slot_card=1
			AND a.ST3 IS NOT NULL AND a.BCST3 IS NOT NULL
			AND DATEDIFF(mi,DATEADD(dd,DATEDIFF(dd,a.BCST3,a.attdate)+ISNULL(a.begin_time_tag3,0),a.BCST3),a.ST3) > ISNULL(bc.late_allow_minutes,@DefaultLateAllowMinutes)
			AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000' );

		-- 早退：第3段下班卡；写 attEarly，attStatus=2，attStatus3=2
		UPDATE a 
		SET 
			a.attEarly=DATEDIFF(mi,a.ET3,DATEADD(dd,DATEDIFF(dd,a.BCET3,a.attdate)+a.end_time_tag3,a.BCET3)),
			a.attStatus=2,
			a.attStatus3=2
		FROM 
			#t_att_lst_DayResult a
			JOIN dbo.att_lst_time_interval c ON a.ShiftID=c.pb_code_fid
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			c.sec_num=3 AND c.end_time_slot_card=1
			AND a.ET3 IS NOT NULL AND a.BCET3 IS NOT NULL
			AND DATEDIFF(mi,a.ET3,DATEADD(dd,DATEDIFF(dd,a.BCET3,a.attdate)+a.end_time_tag3,a.BCET3)) > ISNULL(bc.early_allow_minutes,@DefaultEarlyAllowMinutes)
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' );
  
		-- 旷工 attStatus=3：任一须刷卡点缺失，或 (attLate+attEarly) 超过 absenteeism_start_minutes
		-- 清零迟到早退分钟、清节日加班标记；errorMessage 区分无卡、漏卡、超阈值等；段状态仅对缺卡段置 3
		UPDATE a 
		SET 
			a.attAbsenteeism=1 ,
			a.attLate=0,
			a.attEarly=0,
			a.attStatus=3,
			a.attovertime30=0,
			a.attStatus1 = CASE 
				WHEN EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=1 AND t.begin_time_slot_card=1 AND a.ST1 IS NULL) THEN 3
				WHEN EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=1 AND t.end_time_slot_card=1 AND a.ET1 IS NULL) THEN 3
				ELSE a.attStatus1
			END,
			a.attStatus2 = CASE 
				WHEN EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=2 AND t.begin_time_slot_card=1 AND a.ST2 IS NULL) THEN 3
				WHEN EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=2 AND t.end_time_slot_card=1 AND a.ET2 IS NULL) THEN 3
				ELSE a.attStatus2
			END,
			a.attStatus3 = CASE 
				WHEN EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=3 AND t.begin_time_slot_card=1 AND a.ST3 IS NULL) THEN 3
				WHEN EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=3 AND t.end_time_slot_card=1 AND a.ET3 IS NULL) THEN 3
				ELSE a.attStatus3
			END,
			a.errorMessage = 
				CASE 
					WHEN a.ST1 IS NULL AND a.ET1 IS NULL 
						AND (a.BCST2 IS NULL OR (a.ST2 IS NULL AND a.ET2 IS NULL))
						AND (a.BCST3 IS NULL OR (a.ST3 IS NULL AND a.ET3 IS NULL)) THEN N'没有刷卡记录'
					WHEN a.ST1 IS NULL AND a.ET1 IS NOT NULL THEN N'漏打卡'
					WHEN a.ST1 IS NOT NULL AND a.ET1 IS NULL THEN N'漏打卡'
					WHEN a.BCST2 IS NOT NULL AND (a.ST2 IS NULL OR a.ET2 IS NULL) THEN N'漏打卡'
					WHEN a.BCST3 IS NOT NULL AND (a.ST3 IS NULL OR a.ET3 IS NULL) THEN N'漏打卡'
					WHEN a.ST1 IS NOT NULL AND a.ET1 IS NOT NULL 
						AND (a.BCST2 IS NULL OR (a.ST2 IS NOT NULL AND a.ET2 IS NOT NULL))
						AND (a.BCST3 IS NULL OR (a.ST3 IS NOT NULL AND a.ET3 IS NOT NULL)) THEN N'迟到或者早退超过旷工阈值'
					ELSE N'漏打卡'
				END
		FROM 
			#t_att_lst_DayResult a
			LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
		WHERE 
			a.attdate BETWEEN @attStartDate AND @attEndDate 
			AND a.ShiftID NOT  IN ('00000000-0000-0000-0000-000000000000' )
			AND ISNULL(a.attHoliday,0)=0
			AND (
				EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=1 AND t.begin_time_slot_card=1 AND a.ST1 IS NULL)
				OR EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=1 AND t.end_time_slot_card=1 AND a.ET1 IS NULL)
				OR EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=2 AND t.begin_time_slot_card=1 AND a.ST2 IS NULL)
				OR EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=2 AND t.end_time_slot_card=1 AND a.ET2 IS NULL)
				OR EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=3 AND t.begin_time_slot_card=1 AND a.ST3 IS NULL)
				OR EXISTS (SELECT 1 FROM dbo.att_lst_time_interval t WHERE t.pb_code_fid=a.ShiftID AND t.sec_num=3 AND t.end_time_slot_card=1 AND a.ET3 IS NULL)
				OR (ISNULL(a.attLate,0)+ISNULL(a.attEarly,0)) > ISNULL(bc.absenteeism_start_minutes,@DefaultAbsenteeismMinutes)
			);

		-- 有刷卡但排班为休息/法定假日：标 attStatus=8（异常刷卡）
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
			9. 出勤天数 attDay
			- 有排班、未旷工 → attDay=1（后续请假等可能再改）；
			- ShiftID 在 BC 主表不存在 → attStatus=8 且 attDay=0；
			- 无薪假覆盖日期 → attDay=0。
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

		-- 排班引用了不存在的班次 FID
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

		-- 无薪假期间不计出勤天
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

		-- 统计已审核的「漏打卡」补签次数：与日结果 ST1/ET1 匹配的刷卡且 CardReason='漏打卡'
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
			10. 落库：删除旧记录（未审核且无进行中的旷工流程）后整批插入
		*************************************************************************/
		DELETE a 
		FROM 
			dbo.att_lst_DayResult a
			LEFT JOIN dbo.DingTalk_Lst_Process p ON a.PushAbsenteeism = p.BusinessId
		WHERE 
			a.attdate >= @attStartDate AND a.attdate <= @attEndDate
			AND EXISTS(SELECT 1 FROM @tempemployee emp WHERE emp.emp_id = a.EMP_ID)
			AND ISNULL(a.approval,0) = 0 AND (p.Status IS NULL OR p.Status NOT IN ('NEW','RUNNING'));--2023-11-08 有旷工流程正在进行的记录不日结
	 
		-- 正式表：同样剔除入职前、离职后（仅未审核记录）
		DELETE a 
		FROM  
			dbo.att_lst_DayResult a
			INNER JOIN dbo.t_base_employee b ON a.EMP_ID = b.code 
		WHERE 
			(a.attdate > b.leave_time OR a.attdate < b.frist_join_date)
			AND ISNULL(a.approval,0)=0;

		/*********************************************************************************
			将 #t_att_lst_DayResult 写入 dbo.att_lst_DayResult（新 FID，审批字段清空待后续流程）
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
			BCST3 ,
			begin_time_tag3 ,
			BCET3 ,
			end_time_tag3 ,
			ST3 ,
			ET3 ,
			attStatus1 ,
			attStatus2 ,
			attStatus3 ,
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
			BCST3 ,
			begin_time_tag3 ,
			BCET3 ,
			end_time_tag3 ,
			ST3 ,
			ET3 ,
			attStatus1 ,
			attStatus2 ,
			attStatus3 ,
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


