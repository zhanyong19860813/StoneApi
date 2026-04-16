USE [SJHRsalarySystemDb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
  v_att_lst_DayResult.sql
  用途：日结结果展示视图（用于页面查询/导出）

  本视图重点：
  - 输出总状态 + 分段状态（attStatus1/2/3）；
  - 计划时间与实际刷卡时间统一输出为 [前一天/当天/次日-HH:MM]；
  - 当原始时间为空时，展示字段保持 NULL，避免误读；
  - 保留旷工流程状态、月审状态等业务展示字段。
*/
ALTER VIEW [dbo].[v_att_lst_DayResult]
AS
SELECT  dr.FID, 
		dr.EMP_ID, 
		dr.attdate, 
		DATENAME(WEEKDAY, dr.attdate) AS weekday, 
		dr.isHoliday, 
		dr.ShiftID, 
		dr.attStatus,           
		CONVERT(VARCHAR(10), dr.ET1 - dr.ST1, 108) AS attTime, 
		dr.attDay, 
		dr.attHolidayID, 
		dr.attLate, 
		dr.attEarly, 
        dr.attAbsenteeism, 
		dr.attHoliday, 
		dr.attovertime15, 
		dr.attovertime20, 
		dr.attovertime30, 
		dr.begin_time_tag1, 
        dr.end_time_tag1, 
		dr.begin_time_tag2, 
		dr.end_time_tag2, 
		CASE ISNULL(dr.begin_time_tag1, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END AS planBeginDayFlag1,
		CASE ISNULL(dr.end_time_tag1, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END AS planEndDayFlag1,
		CASE ISNULL(dr.begin_time_tag2, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END AS planBeginDayFlag2,
		CASE ISNULL(dr.end_time_tag2, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END AS planEndDayFlag2,
		CASE ISNULL(dr.begin_time_tag3, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END AS planBeginDayFlag3,
		CASE ISNULL(dr.end_time_tag3, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END AS planEndDayFlag3,
        CASE WHEN dr.approval = 1 THEN '已审核' ELSE '' END AS approval, 
		dr.approvaler, 
		dr.approvalTime, 
		dr.ModifyTime, 
        emp.name, 
		duty.name AS dutyName, 
		dep.long_name, 
		emp.frist_join_date, 
		bc.code_name, 
        (CASE WHEN dr.attHolidayID IS NULL THEN s.name ELSE hc.HC_Name END) AS attStatusName, 
		CASE WHEN dr.BCST1 IS NOT NULL THEN N'[' + (CASE ISNULL(dr.begin_time_tag1, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.BCST1, 108) + N']' ELSE NULL END AS BCST1, 
		CASE WHEN dr.BCET1 IS NOT NULL THEN N'[' + (CASE ISNULL(dr.end_time_tag1, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.BCET1, 108) + N']' ELSE NULL END AS BCET1, 
		CASE WHEN dr.ST1 IS NOT NULL THEN N'[' + (CASE WHEN CAST(dr.ST1 AS DATE) < dr.attdate THEN N'前一天' WHEN CAST(dr.ST1 AS DATE) > dr.attdate THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.ST1, 108) + N']' ELSE NULL END AS ST1, 
		CASE WHEN dr.ET1 IS NOT NULL THEN N'[' + (CASE WHEN CAST(dr.ET1 AS DATE) < dr.attdate THEN N'前一天' WHEN CAST(dr.ET1 AS DATE) > dr.attdate THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.ET1, 108) + N']' ELSE NULL END AS ET1, 
		CASE WHEN dr.BCST2 IS NOT NULL THEN N'[' + (CASE ISNULL(dr.begin_time_tag2, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.BCST2, 108) + N']' ELSE NULL END AS BCST2, 
		CASE WHEN dr.BCET2 IS NOT NULL THEN N'[' + (CASE ISNULL(dr.end_time_tag2, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.BCET2, 108) + N']' ELSE NULL END AS BCET2, 
		CASE WHEN dr.ST2 IS NOT NULL THEN N'[' + (CASE WHEN CAST(dr.ST2 AS DATE) < dr.attdate THEN N'前一天' WHEN CAST(dr.ST2 AS DATE) > dr.attdate THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.ST2, 108) + N']' ELSE NULL END AS ST2, 
		CASE WHEN dr.ET2 IS NOT NULL THEN N'[' + (CASE WHEN CAST(dr.ET2 AS DATE) < dr.attdate THEN N'前一天' WHEN CAST(dr.ET2 AS DATE) > dr.attdate THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.ET2, 108) + N']' ELSE NULL END AS ET2, 
		CASE WHEN dr.BCST3 IS NOT NULL THEN N'[' + (CASE ISNULL(dr.begin_time_tag3, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.BCST3, 108) + N']' ELSE NULL END AS BCST3, 
		CASE WHEN dr.BCET3 IS NOT NULL THEN N'[' + (CASE ISNULL(dr.end_time_tag3, 0) WHEN -1 THEN N'前一天' WHEN 1 THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.BCET3, 108) + N']' ELSE NULL END AS BCET3, 
		CASE WHEN dr.ST3 IS NOT NULL THEN N'[' + (CASE WHEN CAST(dr.ST3 AS DATE) < dr.attdate THEN N'前一天' WHEN CAST(dr.ST3 AS DATE) > dr.attdate THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.ST3, 108) + N']' ELSE NULL END AS ST3, 
		CASE WHEN dr.ET3 IS NOT NULL THEN N'[' + (CASE WHEN CAST(dr.ET3 AS DATE) < dr.attdate THEN N'前一天' WHEN CAST(dr.ET3 AS DATE) > dr.attdate THEN N'次日' ELSE N'当天' END) + N'-' + CONVERT(NVARCHAR(5), dr.ET3, 108) + N']' ELSE NULL END AS ET3, 
		dr.attStatus1, 
		dr.attStatus2, 
		dr.attStatus3, 
		CASE dr.attStatus1 WHEN 0 THEN N'正常' WHEN 1 THEN N'迟到' WHEN 2 THEN N'早退' WHEN 3 THEN N'漏打卡' ELSE NULL END AS attStatus1Name, 
		CASE dr.attStatus2 WHEN 0 THEN N'正常' WHEN 1 THEN N'迟到' WHEN 2 THEN N'早退' WHEN 3 THEN N'漏打卡' ELSE NULL END AS attStatus2Name, 
		CASE dr.attStatus3 WHEN 0 THEN N'正常' WHEN 1 THEN N'迟到' WHEN 2 THEN N'早退' WHEN 3 THEN N'漏打卡' ELSE NULL END AS attStatus3Name, 
		dr.OperatorName, 
		dr.OperationTime, 
		dep.id dept_id, 
		dr.errorMessage, 
        dep.SJCode AS dpm_id, 
		dr.ps_id, 
		disp.DispatchCompany AS labor, 
		emp.type, 
		dr.cancel, 
		dr.cancelTime,
		mr.approveStatus,
		CASE WHEN mr.approveStatus=1 THEN '已审核' ELSE '未审核' END AS monthApprove,
		p.Status PushAbsenteeism,--旷工流程状态
		CASE 
			WHEN p.Status='NEW' THEN '刚创建' 
			WHEN p.Status='RUNNING' THEN '运行中' 
			WHEN p.Status='TERMINATED' THEN '被终止' 
			WHEN p.Status='COMPLETED' THEN '完成' 
			WHEN p.Status='CANCELED' THEN '取消' 
			ELSE '未推送'
		END AS PushAbsenteeismStatus,
		dr.ApprovalType,
		dr.DateType,
		dr.AttendancePerformance,
		dr.OvertimeType,
		dr.ExceptionType
FROM 
	dbo.att_lst_DayResult AS dr WITH (NOLOCK) 
	LEFT OUTER JOIN dbo.t_base_employee AS emp ON dr.EMP_ID = emp.code 
	LEFT OUTER JOIN dbo.t_base_department AS dep ON dr.dpm_id = dep.SJCode 
	LEFT OUTER JOIN dbo.t_base_duty AS duty ON dr.ps_id = duty.SJID 
	LEFT OUTER JOIN dbo.att_lst_Holiday AS h ON dr.attHolidayID = h.FID 
	LEFT OUTER JOIN dbo.att_lst_HolidayCategory AS hc ON h.HC_ID = hc.HC_ID
	LEFT OUTER JOIN dbo.att_lst_BC_set_code AS bc ON dr.ShiftID = bc.FID 
	LEFT OUTER JOIN dbo.t_base_dictionary_detail AS s ON dr.attStatus = s.value AND s.dictionary_id = 'B6896025-19EC-4A0F-9528-FA49B026F398'--数据字典：出勤状态
	LEFT OUTER JOIN dbo.t_employee_dispatch AS disp ON emp.code = disp.EMP_ID
	LEFT JOIN  dbo.att_lst_MonthResult mr ON dr.EMP_ID=mr.EMP_ID AND  LEFT( REPLACE(dr.attdate,'-',''),6) =mr.Fmonth
	LEFT JOIN dbo.DingTalk_Lst_Process p ON dr.PushAbsenteeism = p.BusinessId
GO
