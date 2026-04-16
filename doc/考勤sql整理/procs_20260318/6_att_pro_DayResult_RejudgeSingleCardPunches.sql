USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_RejudgeSingleCardPunches]    Script Date: 2026/3/18 18:01:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
  过程名：dbo.att_pro_DayResult_RejudgeSingleCardPunches

  用途：
    - 当班次内刷卡只有一次/或两次刷卡间隔很小（<=3分钟）时，
      重新判定该刷卡归属（上班卡/下班卡），避免 ST/ET 归属错误

  依赖：
    - 调用方必须已创建并填充 #t_att_lst_DayResult（含 BCST/BCET 与时间 tag、ST/ET）

  输出：
    - 直接更新 #t_att_lst_DayResult（ST1/ET1/ST2/ET2）
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_RejudgeSingleCardPunches]
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE a 
  SET 
    a.ST1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))< ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ST1 ELSE NULL END,
    a.ET1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))>= ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ET1 ELSE NULL END,
    a.ST2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))< ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ST2 ELSE NULL END,
    a.ET2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))>= ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ET2 ELSE NULL END
  FROM #t_att_lst_DayResult a,
  (
    SELECT 
      EMP_ID,attdate,
      DATEADD(dd,DATEDIFF(dd,BCST1,attdate)+ISNULL(begin_time_tag1,0),BCST1) AS BC1,
      DATEADD(dd,DATEDIFF(dd,BCET1,attdate)+ISNULL(end_time_tag1,0),BCeT1) AS BC2,
      DATEADD(dd,DATEDIFF(dd,BCST2,attdate)+ISNULL(begin_time_tag2,0),BCST2) AS BC3,
      DATEADD(dd,DATEDIFF(dd,BCET2,attdate)+ISNULL(end_time_tag2,0),BCET2) AS BC4,
      st1,et1,st2,ET2
    FROM #t_att_lst_DayResult 
    WHERE ABS(DATEDIFF(mi,ST1,ET1))<=3 AND ST1 IS NOT NULL AND ET1 IS NOT NULL  
  ) b
  WHERE a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.ST1 IS NOT NULL AND a.ET1 IS NOT NULL AND a.BCST1 IS NOT NULL;
END
GO


