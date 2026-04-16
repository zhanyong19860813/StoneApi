/* =========================================================
  纯重构（不改业务逻辑）- 第七段：更新请假记录

  目标：
    1) 新增过程：dbo.att_pro_DayResult_UpdateHolidayRecords
       - 输入：@attStartDate, @attEndDate
       - 行为：搬迁主过程第 7 节“更新请假记录”两段 UPDATE + 结尾 PRINT
       - 输出：直接更新调用方已有的临时表 #t_att_lst_DayResult

  说明：
    - 子过程依赖外层存在 #t_att_lst_DayResult（外层创建，嵌套 EXEC 可见）
========================================================= */

USE [SJHRsalarySystemDb];
GO

CREATE OR ALTER PROC dbo.att_pro_DayResult_UpdateHolidayRecords
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

