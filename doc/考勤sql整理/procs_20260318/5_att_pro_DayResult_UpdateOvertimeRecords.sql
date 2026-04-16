USE [SJHRsalarySystemDb]
GO

/****** Object:  StoredProcedure [dbo].[att_pro_DayResult_UpdateOvertimeRecords]    Script Date: 2026/3/18 18:00:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************
 Step5：更新加班记录下沉（内联自 refactor_split_update_overtime_records.sql）
**********************************************************************/

/* =========================================================
  过程名：dbo.att_pro_DayResult_UpdateOvertimeRecords

  用途：
    - 更新日结临时表的加班标记/状态：
      * 日常加班（attovertime15）
      * 假日加班（attovertime20）
      * 节日加班（attovertime30，含法定假日排班规则）

  入参：
    - @attStartDate/@attEndDate：日结日期范围

  依赖：
    - 调用方必须已创建并填充 #t_att_lst_DayResult

  输出：
    - 直接更新 #t_att_lst_DayResult（加班字段、attStatus、ST/ET 等）
========================================================= */
ALTER PROC [dbo].[att_pro_DayResult_UpdateOvertimeRecords]
(
  @attStartDate DATETIME,
  @attEndDate DATETIME
)
AS
BEGIN
  SET NOCOUNT ON;

  -- 日常加班（attovertime15）
  -- 触发条件：
  -- 1) 加班申请类型为“日常加班%”
  -- 2) 当天最早/最晚刷卡时长 >= 班次加班起算阈值（overtime_start_minutes，未配置按0）
  -- 结果：
  -- - 置 attStatus=5，并回填 ST1/ET1 作为加班时段
  UPDATE a 
  SET 
    a.attovertime15=1,
    a.attStatus=5,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '日常加班%'  
    LEFT JOIN (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE   
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE  
    a.attdate BETWEEN @attStartDate AND @attEndDate
    AND (
      d.sk1 IS NULL OR d.sk2 IS NULL
      OR DATEDIFF(mi,d.sk1,d.sk2) >= ISNULL(bc.overtime_start_minutes,0)
    );

  -- 假日加班（attovertime20）
  -- 触发条件与日常加班一致，但申请类型为“假日加班%”
  -- 结果：
  -- - 置 attStatus=6，并回填 ST1/ET1
  UPDATE a 
  SET 
    a.attovertime20=1,
    a.attStatus=6,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '假日加班%'  
    LEFT JOIN (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE   
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE  
    a.attdate BETWEEN @attStartDate AND @attEndDate
    AND (
      d.sk1 IS NULL OR d.sk2 IS NULL
      OR DATEDIFF(mi,d.sk1,d.sk2) >= ISNULL(bc.overtime_start_minutes,0)
    );

  -- 节日加班（attovertime30）
  -- 触发条件：
  -- 1) 加班申请类型为“节日加班%”
  -- 2) attdate 命中法定节假日表
  -- 3) 通过加班起算阈值过滤（或刷卡为空的保底路径）
  -- 4) 对指定特殊班次保留历史兼容判定
  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7,
    a.attDay=1,
    a.ST1=d.sk1 , 
    a.ET1=d.sk2
  FROM 
    #t_att_lst_DayResult a 
    LEFT JOIN dbo.att_lst_BC_set_code bc ON a.ShiftID=bc.FID
    JOIN [dbo].att_lst_OverTime b ON a.EMP_ID=b.EMP_ID  AND  a.attdate=b.fDate  AND  b.fType LIKE '节日加班%' 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate 
    LEFT JOIN (
      SELECT 
        a.EMP_ID,
        a.attdate, 
        MIN(c.sc) sk1,
        MAX(c.sc) sk2
      FROM  
        #t_att_lst_DayResult a, 
        (
          SELECT 
            EMP_ID,
            SlotCardDate,
            SlotCardTime,
            DATEADD(dd,DATEDIFF(dd,SlotCardTime,SlotCardDate),SlotCardTime) AS sc 
          FROM 
            dbo.att_lst_Cardrecord  
          WHERE 
            SlotCardDate BETWEEN @attStartDate AND @attEndDate 
        )c
      WHERE   
        a.EMP_ID=c.EMP_ID  
        AND a.attdate=c.SlotCardDate  
        AND a.attdate BETWEEN @attStartDate AND @attEndDate 
      GROUP BY  
        a.EMP_ID,a.attdate
    )d ON a.attdate=d.attdate AND a.EMP_ID=d.EMP_ID
  WHERE  
    a.attdate BETWEEN @attStartDate AND @attEndDate
    AND (
      d.sk1 IS NULL OR d.sk2 IS NULL
      OR DATEDIFF(mi,d.sk1,d.sk2) >= ISNULL(bc.overtime_start_minutes,0)
    )
    AND (a.ShiftID IN ('26342F6A-84A8-468F-9942-B7EF0D50CEE7','23B7F46A-63A7-4662-8F6F-D9B6F81902D5') OR (d.sk1 IS NOT NULL AND d.sk2 IS NOT NULL));

  -- 法定假日排班产生节日加班（规则兜底）
  -- 说明：
  -- - 当部门/岗位配置了“节日统计出勤天”规则时，法定节假日排班直接记节日加班；
  -- - 该分支不回填 ST/ET，主要用于状态标记与统计口径对齐。
  UPDATE a 
  SET 
    a.attovertime30=1,
    a.attStatus=7
  FROM 
    #t_att_lst_DayResult a 
    JOIN dbo.att_lst_StatutoryHoliday sh ON a.attDate=sh.Holidaydate
    JOIN [dbo].[att_lst_overtimeRules] r ON a.dpm_id=r.de_id AND a.ps_id=r.ps_id AND r.jieri='统计出勤天'
  WHERE  
    a.attdate BETWEEN @attStartDate AND @attEndDate
    AND a.ShiftID NOT IN ('00000000-0000-0000-0000-000000000000' );

  PRINT '结束更新加班记录：'+CONVERT(NVARCHAR(20),GETDATE(),120);
END
GO


