



CREATE VIEW [dbo].[v_att_lst_JobScheduling]
AS
SELECT
	e.name,
	e.dept_id,
	e.dpm_id,
	e.long_name,
	e.dutyName,
	e.frist_join_date,
	e.EMP_OutDate leave_time,
	CONVERT(NVARCHAR(10),ISNULL(dpc.FulldaysValue,xm.Chuqin))+' / '+CONVERT(NVARCHAR(10),xm.Chuqin)+' / '+CONVERT(NVARCHAR(10),xm.XX) AS FulldaysValue,
	m.* 
FROM 
	dbo.att_lst_JobScheduling m
	INNER JOIN dbo.v_t_base_employee e ON m.EMP_ID=e.code
	LEFT JOIN dbo.GZ_Dept_POST_FullDays_Config dpc ON m.JS_Month=dpc.WG_Month AND e.dpm_id=dpc.DeptCode AND e.ps_id=dpc.PostID
	LEFT JOIN (
		SELECT 
			up.EMP_ID,
			up.JS_Month, 
			SUM(CASE WHEN ISNULL(ShiftID ,'00000000-0000-0000-0000-000000000000')='00000000-0000-0000-0000-000000000000' THEN 1 ELSE 0 END) AS XX,
			SUM(CASE WHEN ISNULL(ShiftID ,'00000000-0000-0000-0000-000000000000')='00000000-0000-0000-0000-000000000000' THEN 0 ELSE 1 END) AS Chuqin
		FROM 
			dbo.att_lst_JobScheduling
			UNPIVOT(ShiftID FOR scoure 
				IN(Day1_ID,Day2_ID,Day3_ID,Day4_ID,Day5_ID,Day6_ID,Day7_ID,Day8_ID,Day9_ID,Day10_ID,
					Day11_ID,Day12_ID,Day13_ID,Day14_ID,Day15_ID,Day16_ID,Day17_ID,Day18_ID,Day19_ID,Day20_ID,
					Day21_ID,Day22_ID,Day23_ID,Day24_ID,Day25_ID,Day26_ID,Day27_ID,Day28_ID,Day29_ID,Day30_ID,Day31_ID)
			)AS up
		WHERE  
			REPLACE(REPLACE(up.scoure,'Day',''),'_ID','')<=DAY(DATEADD(MONTH,1,RTRIM(JS_Month)+ '01')-1)
		GROUP BY 
			up.EMP_ID,up.JS_Month
	) xm ON m.EMP_ID=xm.EMP_ID AND m.JS_Month=xm.JS_Month
GO


