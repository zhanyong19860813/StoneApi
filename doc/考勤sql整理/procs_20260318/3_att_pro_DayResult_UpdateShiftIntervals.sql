USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_UpdateShiftIntervals]    Script Date: 2026/3/18 17:59:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
  过程名：dbo.att_pro_DayResult_UpdateShiftIntervals

  用途：
    - 根据 dbo.att_lst_time_interval（sec_num=1/2/3）补齐班次时间段
    - 更新 #t_att_lst_DayResult 的 BCST  BCET* 及 begin_time_tag end_time_tag 

  依赖：
    - 调用方必须已创建并填充 #t_att_lst_DayResult
     
  输出：
    - 直接更新 #t_att_lst_DayResult
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_UpdateShiftIntervals]
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE a
  SET
    a.attStatus=0,
    a.BCST1=b.begin_time,
    a.BCET1=b.end_time,
    a.begin_time_tag1=ISNULL(b.begin_time_tag,0),
    a.end_time_tag1=ISNULL(b.end_time_tag,0)
  FROM #t_att_lst_DayResult a,[dbo].att_lst_time_interval b
  WHERE a.ShiftID=b.pb_code_fid AND b.sec_num=1;

  UPDATE a
  SET
    a.attStatus=0,
    a.BCST2=b.begin_time,
    a.BCET2=b.end_time,
    a.begin_time_tag2=ISNULL(b.begin_time_tag,0),
    a.end_time_tag2=ISNULL(b.end_time_tag,0)
  FROM #t_att_lst_DayResult a,[dbo].att_lst_time_interval b
  WHERE a.ShiftID=b.pb_code_fid AND b.sec_num=2;

  UPDATE a
  SET
    a.attStatus=0,
    a.BCST3=b.begin_time,
    a.BCET3=b.end_time,
    a.begin_time_tag3=ISNULL(b.begin_time_tag,0),
    a.end_time_tag3=ISNULL(b.end_time_tag,0)
  FROM #t_att_lst_DayResult a,[dbo].att_lst_time_interval b
  WHERE a.ShiftID=b.pb_code_fid AND b.sec_num=3;
END
GO


