

att_lst_Cardrecord   --刷卡资料表  就是原始刷卡记录 
v_att_lst_Cardrecord --刷卡资料视图 就是原始刷卡记录  视图

att_lst_BC_set_code  -- 班次信息主表
att_lst_time_interval --班次信息明细表  pb_code_fid 字段 是 att_lst_BC_set_code 表的fid 外键，   如果有两段 班次这里就应该有两条数据  比如 
1.上午8:30- 12:30 一条数据   2.下午13:30 -5:30一条数据


att_lst_JobScheduling--排班表 就是 某个人 某天排什么班次

v_att_lst_JobScheduling--排班视图 就是 某个人 某天排什么班次

att_lst_DayResult      --考勤日结果表
v_att_lst_DayResult --考勤日结果视图


--生成考勤日结果存储过程  描述 根据  班次设定，排班  刷卡资料 计算 考勤日结果。
att_pro_DayResult



