/* =========================================================
  修复脚本：修复 refactor6 误替换导致的 dbo.att_pro_DayResult 逻辑缺失

  现象：
    - “单次刷卡归属重判”的 EXEC 被插到了“02.获取职务调动...”后面
    - 导致 3/4/5 节（出勤状态/刷卡/加班）整块丢失或未执行
    - 表现为 ST1/ET1 等为空，最终大量/全部旷工

  修复思路：
    - 用 OBJECT_DEFINITION 抓取当前 dbo.att_pro_DayResult
    - 定位从“02.获取职务调动...”注释到“PRINT '重新更新入职当天...'”之间的错误块
    - 用正确的块替换（恢复：02 更新职务调动 + 3 出勤状态 + 4 刷卡 + 5 加班 + 6 重判）

  注意：
    - 这是“结构修复”，不引入新业务逻辑
========================================================= */

USE [SJHRsalarySystemDb];
GO

DECLARE @proc sysname = N'dbo.att_pro_DayResult';
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(@proc));

IF @sql IS NULL
BEGIN
  THROW 50000, '找不到存储过程 dbo.att_pro_DayResult（或没有权限读取定义）', 1;
END

DECLARE @start int = CHARINDEX(N'/***********************************************************', @sql);
DECLARE @start2 int = 0;
DECLARE @endAnchor int = 0;

-- 更精确：从“02.获取职务调动...”这块开始（避免在注释中写出块注释起始符）
SET @start2 = CHARINDEX(N'02.获取职务调动时所设置的计薪职务', @sql);
IF @start2 > 0
BEGIN
  -- 回溯到这一段注释块的起始（注释块以斜杠+星号开头）
  DECLARE @rev nvarchar(max) = REVERSE(LEFT(@sql, @start2));
  DECLARE @revPos int = CHARINDEX(REVERSE(N'/***********************************************************'), @rev);
  IF @revPos > 0
    SET @start = @start2 - @revPos + 1;
END

SET @endAnchor = CHARINDEX(N'PRINT ''重新更新入职当天的上班卡：''', @sql);

IF @start = 0 OR @endAnchor = 0 OR @endAnchor <= @start
BEGIN
  THROW 50001, '修复失败：未定位到替换区间（02.职务调动 -> 入职当天PRINT）。', 1;
END

DECLARE @replacement nvarchar(max) = N'
		-- 02.获取职务调动时所设置的计薪职务

		UPDATE a 
		SET 
			a.dpm_id = b.EWM_bfDepartment,
			a.ps_id = b.EWM_bfPost
		FROM 
			#t_att_lst_DayResult a
			LEFT JOIN dbo.RS_Func_EmpWorkMove(@attStartDate,DATEADD(DAY,1,@attEndDate)) b 
				ON a.EMP_ID = b.EMP_ID AND a.attdate >= ISNULL(b.BeginDate,@attStartDate) AND  a.attdate < ISNULL(b.EndDate,@attEndDate)
		WHERE 
			b.EWM_bfDepartment IS NOT NULL
	 

		-- 3.更新出勤状态
		--休息班
		UPDATE a 
		SET 
			a.attStatus=99
		FROM  
			#t_att_lst_DayResult a
		WHERE 
			a.ShiftID=''00000000-0000-0000-0000-000000000000'';

		--法定假日
		UPDATE a 
		SET 
			a.attStatus=4
		FROM  
			#t_att_lst_DayResult a,[dbo].[att_lst_StatutoryHoliday] b
		WHERE 
			a.attdate=b.Holidaydate;

		-- 班次设定时间段（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_UpdateShiftIntervals;

		PRINT ''更新出勤状态：''+CONVERT(NVARCHAR(20),GETDATE(),120);

		-- 4.更新刷卡记录（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_UpdateCardRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;

		-- 5.更新加班记录（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_UpdateOvertimeRecords @attStartDate=@attStartDate, @attEndDate=@attEndDate;

		-- 6.单次刷卡归属重判（纯重构：下沉到子过程）
		EXEC dbo.att_pro_DayResult_RejudgeSingleCardPunches;

';

SET @sql = STUFF(@sql, @start, @endAnchor - @start, @replacement);

/* 兜底：去掉残留块注释符，避免 113 缺失 */ 
SET @sql = REPLACE(@sql, N'/*', N'--');
SET @sql = REPLACE(@sql, N'*/', N'');
SET @sql = REPLACE(@sql, N'CREATE PROC', N'ALTER PROC');

EXEC sp_executesql @sql;

PRINT 'Repair done: dbo.att_pro_DayResult block 02~06 restored.';
GO

