USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_ExpandJobScheduling]    Script Date: 2026/3/18 17:58:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
  过程名：dbo.att_pro_DayResult_ExpandJobScheduling

  用途：
    - 将月排班表 dbo.att_lst_JobScheduling 的 Day1_ID~Day31_ID 列转行
    - 写入调用方临时表 #t_jobSchedExpanded，供主过程插入日结初始记录

  入参：
    - @attMonth：排班月份（yyyymm）
    - @attDays：该月天数（1~31）
    - @attStartDate/@attEndDate：本次日结日期范围（同月内）

  依赖：
    - 调用方必须预先创建 #t_jobSchedExpanded（子过程只负责 INSERT）

  输出：
    - 向 #t_jobSchedExpanded 插入：EMP_ID, attDate, ShiftID 及默认统计字段
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_ExpandJobScheduling]
(
  @attMonth NVARCHAR(6),
  @attDays INT,
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH UnpivotedData AS
  (
    SELECT
      up.EMP_ID,
      up.JS_Month,
      REPLACE(REPLACE(up.scoure,'Day',''),'_ID','') AS attDate,
      ShiftID
    FROM dbo.att_lst_JobScheduling
    UNPIVOT
    (
      ShiftID FOR scoure IN
      (
        Day1_ID,Day2_ID,Day3_ID,Day4_ID,Day5_ID,Day6_ID,Day7_ID,Day8_ID,Day9_ID,Day10_ID,
        Day11_ID,Day12_ID,Day13_ID,Day14_ID,Day15_ID,Day16_ID,Day17_ID,Day18_ID,Day19_ID,Day20_ID,
        Day21_ID,Day22_ID,Day23_ID,Day24_ID,Day25_ID,Day26_ID,Day27_ID,Day28_ID,Day29_ID,Day30_ID,Day31_ID
      )
    ) AS up
    WHERE
      JS_Month = @attMonth
      AND REPLACE(REPLACE(up.scoure,'Day',''),'_ID','') <= @attDays
  ),
  FilteredData AS
  (
    SELECT
      EMP_ID,
      CONVERT(DATETIME, RTRIM(JS_Month) + RIGHT('0' + attDate, 2)) AS attDate,
      ShiftID
    FROM UnpivotedData
    WHERE
      attDate BETWEEN DAY(@attStartDate) AND DAY(@attEndDate)
  )
  INSERT INTO #t_jobSchedExpanded
  (
    EMP_ID, attDate, ShiftID,
    attTime, attDay, attLate, attEarly, attAbsenteeism, regcard_sum
  )
  SELECT
    EMP_ID, attDate, ShiftID,
    0, 0, 0, 0, 0, 0
  FROM FilteredData;
END
GO


