/* =========================================================
  纯重构（不改业务逻辑）- 第六段：单次刷卡归属重判（含 3 分钟合并）

  目标：
    1) 新增过程：dbo.att_pro_DayResult_RejudgeSingleCardPunches
       - 行为：完整搬迁主过程第 6 节的 UPDATE（ST1/ET1、ST2/ET2 归属重判）
       - 输入输出：直接更新调用方已有的临时表 #t_att_lst_DayResult

    2) 改造过程：dbo.att_pro_DayResult
       - 将原第 6 节（注释块到 UPDATE 结束）替换为 EXEC 调用

  说明：
    - 子过程依赖外层存在 #t_att_lst_DayResult（外层创建，嵌套 EXEC 可见）
    - 本脚本通过 OBJECT_DEFINITION + 定位起止标记 + STUFF 替换，避免整段文本严格匹配
========================================================= */

USE [SJHRsalarySystemDb];
GO

/* =========================================================
  1) 新增：dbo.att_pro_DayResult_RejudgeSingleCardPunches
========================================================= */
CREATE OR ALTER PROC dbo.att_pro_DayResult_RejudgeSingleCardPunches
AS
BEGIN
  SET NOCOUNT ON;

  /**
    6.如果班次内只打了一次卡，则要重新验证该次卡 是属于上班卡还是下班卡
    增加三分钟以内的刷卡记录合并为一次刷卡
  _____________________________________________________________________*/
	 
  UPDATE a 
  SET 
    a.ST1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))< ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ST1 ELSE NULL END,
    a.ET1= CASE WHEN ABS(DATEDIFF(mi,b.BC1,b.ST1))>= ABS(DATEDIFF(mi,b.BC2,b.ST1)) THEN a.ET1 ELSE NULL END,
    a.ST2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))< ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ST2 ELSE NULL END,
    a.ET2= CASE WHEN ABS(DATEDIFF(mi,b.BC3,b.ST2))>= ABS(DATEDIFF(mi,b.BC4,b.ST2)) THEN a.ET2 ELSE NULL END
   FROM
    #t_att_lst_DayResult a,
    (
      SELECT 
        EMP_ID,attdate,
        DATEADD(dd,DATEDIFF(dd,BCST1,attdate)+ISNULL(begin_time_tag1,0),BCST1) AS BC1,
        DATEADD(dd,DATEDIFF(dd,BCET1,attdate)+ISNULL(end_time_tag1,0),BCeT1) AS BC2,
        DATEADD(dd,DATEDIFF(dd,BCST2,attdate)+ISNULL(begin_time_tag2,0),BCST2) AS BC3,
        DATEADD(dd,DATEDIFF(dd,BCET2,attdate)+ISNULL(end_time_tag2,0),BCET2) AS BC4,
        st1,
        et1,
        st2,
        ET2
      FROM 
        #t_att_lst_DayResult 
      WHERE 
        ABS(DATEDIFF(mi,ST1,ET1))<=3 AND ST1 IS NOT NULL AND ET1 IS NOT NULL  
    ) b
  WHERE 
    a.EMP_ID=b.EMP_ID AND a.attdate=b.attdate
    AND a.ST1 IS NOT NULL AND a.ET1 IS NOT NULL AND a.BCST1 IS NOT NULL;
END
GO

/* =========================================================
  2) 手工接入说明（强烈建议手工插入，避免自动替换误伤）

  在 dbo.att_pro_DayResult 里，把下面这一行：

      EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;

  放在“更新刷卡记录 + 更新加班记录”之后，
  且放在打印入职当天修正之前（PRINT '重新更新入职当天的上班卡：...' 之前）。
========================================================= */

