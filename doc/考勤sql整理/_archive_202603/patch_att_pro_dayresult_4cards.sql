/* =========================================================
  Clone script: 生成一个“新名字”的日结存储过程（不改原过程）
  Target DB   : SJHRsalarySystemDb

  What this script does:
    - 从数据库读取原过程 dbo.att_pro_DayResult 的定义
    - 复制成一个新过程 dbo.att_pro_DayResult_4cards（原逻辑完整保留）
    - 在新过程“末尾(RETURN 0 前)”追加后处理：
        1) 把时间段2（sec_num=2）的迟到/早退分钟数累加到 attLate/attEarly（更新正式表 dbo.att_lst_DayResult）
        2) 在不覆盖原 errorMessage 的前提下，追加四次卡事实描述（缺第几次卡、每次卡迟到/早退分钟数）

  Notes:
    - 追加逻辑只更新本次日结范围内（@attStartDate..@attEndDate）且在 @tempemployee 人员集合内的数据。
    - 该脚本不会改动 dbo.att_pro_DayResult 原过程。
========================================================= */

USE [SJHRsalarySystemDb];
GO

DECLARE @srcProc sysname = N'dbo.att_pro_DayResult';
DECLARE @dstProc sysname = N'dbo.att_pro_DayResult_4cards';

DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@srcProc));
IF @sql IS NULL
BEGIN
  THROW 50000, '找不到源存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;
END

/* 1) 先删除目标过程（避免重名） */
IF OBJECT_ID(@dstProc, 'P') IS NOT NULL
BEGIN
  EXEC (N'DROP PROC ' + @dstProc + N';');
END

/* 2) 复制：仅替换过程名（尽量兼容不同写法） */
SET @sql = REPLACE(@sql, N'CREATE PROC [dbo].[att_pro_DayResult]', N'CREATE PROC [dbo].[att_pro_DayResult_4cards]');
SET @sql = REPLACE(@sql, N'CREATE PROC dbo.att_pro_DayResult',       N'CREATE PROC dbo.att_pro_DayResult_4cards');
SET @sql = REPLACE(@sql, N'CREATE PROC att_pro_DayResult',            N'CREATE PROC att_pro_DayResult_4cards');

/* 3) 在 RETURN 0; 之前插入“末尾追加逻辑”（不修改原核心计算流程） */
DECLARE @needleReturn nvarchar(max) = N'
	RETURN 0;
END';

DECLARE @append nvarchar(max) = N'

	/* =========================================================
	  [追加逻辑] 四次卡：补充时间段2迟到/早退 & 追加事实描述
	  - 不改原过程的核心计算，只对已生成的 dbo.att_lst_DayResult 做后处理
	========================================================= */

	/* 3.1 累加时间段2（sec_num=2）的迟到分钟数到 attLate（第三次卡：ST2 vs BCST2） */
	UPDATE dr
	SET dr.attLate = ISNULL(dr.attLate, 0) + DATEDIFF(mi,
			DATEADD(dd, DATEDIFF(dd, dr.BCST2, dr.attdate) + ISNULL(dr.begin_time_tag2, 0), dr.BCST2),
			dr.ST2
		)
	FROM dbo.att_lst_DayResult dr
	JOIN @tempemployee te ON dr.EMP_ID = te.emp_id
	JOIN dbo.att_lst_time_interval c
		ON dr.ShiftID = c.pb_code_fid AND c.sec_num = 2
	WHERE
		dr.attdate BETWEEN @attStartDate AND @attEndDate
		AND c.begin_time_slot_card = 1
		AND dr.ShiftID <> ''00000000-0000-0000-0000-000000000000''
		AND dr.ST2 IS NOT NULL AND dr.BCST2 IS NOT NULL
		AND DATEADD(dd, DATEDIFF(dd, dr.BCST2, dr.attdate) + ISNULL(dr.begin_time_tag2, 0), dr.BCST2) < dr.ST2;

	/* 3.2 累加时间段2（sec_num=2）的早退分钟数到 attEarly（第四次卡：ET2 vs BCET2） */
	UPDATE dr
	SET dr.attEarly = ISNULL(dr.attEarly, 0) + DATEDIFF(mi,
			dr.ET2,
			DATEADD(dd, DATEDIFF(dd, dr.BCET2, dr.attdate) + ISNULL(dr.end_time_tag2, 0), dr.BCET2)
		)
	FROM dbo.att_lst_DayResult dr
	JOIN @tempemployee te ON dr.EMP_ID = te.emp_id
	JOIN dbo.att_lst_time_interval c
		ON dr.ShiftID = c.pb_code_fid AND c.sec_num = 2
	WHERE
		dr.attdate BETWEEN @attStartDate AND @attEndDate
		AND c.end_time_slot_card = 1
		AND dr.ShiftID <> ''00000000-0000-0000-0000-000000000000''
		AND dr.ET2 IS NOT NULL AND dr.BCET2 IS NOT NULL
		AND DATEADD(dd, DATEDIFF(dd, dr.BCET2, dr.attdate) + ISNULL(dr.end_time_tag2, 0), dr.BCET2) > dr.ET2;

	/* 3.3 追加事实描述到 errorMessage（不覆盖原文案） */
	UPDATE dr
	SET dr.errorMessage =
		CASE
			WHEN ISNULL(descs.att_desc, N'''') = N'''' THEN dr.errorMessage
			WHEN ISNULL(dr.errorMessage, N'''') = N'''' THEN descs.att_desc
			ELSE dr.errorMessage + N''|'' + descs.att_desc
		END
	FROM dbo.att_lst_DayResult dr
	JOIN @tempemployee te ON dr.EMP_ID = te.emp_id
	CROSS APPLY (
		SELECT
			STUFF(
				COALESCE(
					CASE WHEN dr.ST1 IS NULL THEN N''|缺第一次卡'' ELSE N'''' END +
					CASE WHEN dr.ET1 IS NULL THEN N''|缺第二次卡'' ELSE N'''' END +
					CASE WHEN dr.ST2 IS NULL THEN N''|缺第三次卡'' ELSE N'''' END +
					CASE WHEN dr.ET2 IS NULL THEN N''|缺第四次卡'' ELSE N'''' END +

					CASE WHEN dr.ST1 IS NOT NULL AND dr.BCST1 IS NOT NULL
							AND dr.ST1 > DATEADD(dd, DATEDIFF(dd, dr.BCST1, dr.attdate) + ISNULL(dr.begin_time_tag1, 0), dr.BCST1)
						THEN N''|第一次卡迟到'' + CONVERT(nvarchar(10),
							DATEDIFF(mi,
								DATEADD(dd, DATEDIFF(dd, dr.BCST1, dr.attdate) + ISNULL(dr.begin_time_tag1, 0), dr.BCST1),
								dr.ST1
							)
						) + N''分钟''
						ELSE N'''' END +

					CASE WHEN dr.ET1 IS NOT NULL AND dr.BCET1 IS NOT NULL
							AND dr.ET1 < DATEADD(dd, DATEDIFF(dd, dr.BCET1, dr.attdate) + ISNULL(dr.end_time_tag1, 0), dr.BCET1)
						THEN N''|第二次卡早退'' + CONVERT(nvarchar(10),
							DATEDIFF(mi,
								dr.ET1,
								DATEADD(dd, DATEDIFF(dd, dr.BCET1, dr.attdate) + ISNULL(dr.end_time_tag1, 0), dr.BCET1)
							)
						) + N''分钟''
						ELSE N'''' END +

					CASE WHEN dr.ST2 IS NOT NULL AND dr.BCST2 IS NOT NULL
							AND dr.ST2 > DATEADD(dd, DATEDIFF(dd, dr.BCST2, dr.attdate) + ISNULL(dr.begin_time_tag2, 0), dr.BCST2)
						THEN N''|第三次卡迟到'' + CONVERT(nvarchar(10),
							DATEDIFF(mi,
								DATEADD(dd, DATEDIFF(dd, dr.BCST2, dr.attdate) + ISNULL(dr.begin_time_tag2, 0), dr.BCST2),
								dr.ST2
							)
						) + N''分钟''
						ELSE N'''' END +

					CASE WHEN dr.ET2 IS NOT NULL AND dr.BCET2 IS NOT NULL
							AND dr.ET2 < DATEADD(dd, DATEDIFF(dd, dr.BCET2, dr.attdate) + ISNULL(dr.end_time_tag2, 0), dr.BCET2)
						THEN N''|第四次卡早退'' + CONVERT(nvarchar(10),
							DATEDIFF(mi,
								dr.ET2,
								DATEADD(dd, DATEDIFF(dd, dr.BCET2, dr.attdate) + ISNULL(dr.end_time_tag2, 0), dr.BCET2)
							)
						) + N''分钟''
						ELSE N'''' END
				, N'''')
			, 1, 1, N'''') AS att_desc
	) descs
	WHERE
		dr.attdate BETWEEN @attStartDate AND @attEndDate;

';

IF CHARINDEX(@needleReturn, @sql) = 0
BEGIN
  THROW 50001, '生成失败：未找到过程末尾的 RETURN 0; / END 片段，无法插入追加逻辑。', 1;
END

SET @sql = REPLACE(@sql, @needleReturn, @append + @needleReturn);

/* 4) 创建新过程 */
EXEC sp_executesql @sql;
PRINT 'Created new proc dbo.att_pro_DayResult_4cards (original kept).';
GO
