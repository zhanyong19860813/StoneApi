/*
  v_att_lst_Cardrecord.sql
  用途：刷卡明细展示视图（联表员工、部门、岗位与审批状态）

  说明：
  - AppState 仅在存在补卡原因时展示审核状态；
  - SlotCardTime 输出为 HH:mm:ss，便于列表展示；
  - 该视图偏展示用途，不承载日结计算逻辑。
*/
CREATE VIEW  [dbo].[v_att_lst_Cardrecord]

 AS  -- 

SELECT a.FID,a.EMP_ID,(CASE WHEN ISNULL(CardReason,'')!='' THEN CASE WHEN a.AppState=1 THEN '已审核' WHEN a.AppState=0 THEN '审批中' ELSE '' END
						ELSE '' END ) AS AppState,
a.SlotCardDate,CONVERT(VARCHAR(100), a.SlotCardTime, 108) AS SlotCardTime,a.AttendanceCard,a.OperatorName,
a.IsOk,a.CardReason,a.Logo,a.Attendance,a.ReginsterCause,a.entry,a.EntryTime,a.OperationTime,a.ArchiveLogo,
b.name,b.EMP_NormalDate,b.frist_join_date,dept.long_name longdeptname,duty.name dutyName,b.leave_time EMP_OutDate,dept.long_name,dept.SJCode dpm_id
FROM att_lst_Cardrecord a
LEFT JOIN t_base_employee b ON a.emp_id=b.code
LEFT JOIN dbo.t_base_department dept ON b.dept_id=dept.id
LEFT JOIN dbo.t_base_duty duty ON b.duty_id=duty.id





GO