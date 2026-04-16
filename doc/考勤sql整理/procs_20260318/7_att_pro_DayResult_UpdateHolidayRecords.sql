USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_UpdateHolidayRecords]    Script Date: 2026/3/18 18:02:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
  过程名：dbo.att_pro_DayResult_UpdateHolidayRecords

  用途：
    - 将请假数据写入/覆盖到日结临时表：
      * 有薪假：attDay=1, attTime=8, attHoliday=1
      * 无薪假：attDay=0, attTime=0, attHoliday=1

  入参：
    - @attStartDate/@attEndDate：日结日期范围

  依赖：
    - 调用方必须已创建并填充 #t_att_lst_DayResult

  输出：
    - 直接更新 #t_att_lst_DayResult（attHoliday* 等字段）
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_UpdateHolidayRecords]
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  /************************************************************************
    7.更新请假记录
  *************************************************************************/
  --有薪假包括 年 婚 丧 出差，调休，产假，陪产假，工伤 , 育儿 , 探亲
  UPDATE	a 
  SET		
    a.attHolidayID=b.FID,
    a.attDay=1,
    a.attTime=8,
    a.attovertime30=0,
    a.attHoliday=1,
    attHolidayCategory=b.HC_ID
  FROM	
    #t_att_lst_DayResult a
    INNER JOIN dbo.att_lst_Holiday b ON a.EMP_ID = b.EMP_ID
    INNER JOIN dbo.att_lst_HolidayCategory c ON b.HC_ID = c.HC_ID AND c.HC_Paidleave = 1
  WHERE 
    a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate
    AND (b.HC_ID <> 'H10' OR DATEPART(WEEKDAY, a.attdate) <> 1);  --周日出差不算出勤  2024-03-01 zhanglinfu
 
  ---- --无薪假 年审假
  --病假
  --事假
  UPDATE a 
  SET 
    a.attHolidayID=b.FID,
    a.attDay=0,
    a.attTime=0,
    a.attovertime30=0,
    a.attHoliday=1,
    attHolidayCategory=b.HC_ID
  FROM 
    #t_att_lst_DayResult a,
    [dbo].[att_lst_Holiday] b 
  WHERE 
    a.EMP_ID=b.EMP_ID 
    AND (a.attdate BETWEEN b.HD_StartDate AND b.HD_EndDate)
    AND b.HC_ID IN (SELECT HC_ID FROM [dbo].[att_lst_HolidayCategory] WHERE HC_Paidleave=0);
	  
  PRINT '结束更新请假记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO


