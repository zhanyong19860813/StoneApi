

 

select top 10 id,code 工号,name 姓名,long_name 部门,longdeptname 部门全路径,dutyId 岗位id,dutyName 岗位名称  from v_t_base_employee
0CAB7C38-D5D0-49DF-805F-000DDDC4EA11	C4537	徐威(离)	惠州集货组	东莞总部->惠州时捷->惠州仓储部->惠州集货部->惠州集货组	C03914BF-4B78-44D3-9D50-B9FBD363A256	集筐员              
0D0A05C4-646D-45F1-2408-0013F85FF48A	D7751	汪卓斌(速聘)(离)	茶山整件分拣口一组	东莞总部->茶山时捷->茶山仓储部->茶山整件配货部->茶山整件分拣口区->茶山整件分拣口一组	7245D0C0-5355-4D0B-903B-5E65C46485AA	分拣员
B3316AAD-35D7-A121-E142-002AF9B7B10B	D9640	王熙(航辉)(离)	江门整件侧向拣选区	东莞总部->江门时捷->江门仓储部->江门整件配货部->江门整件侧向拣选区	93DF5510-8892-4AF4-8A24-36FC0B28B08A	配货员              
9A917B82-CA4F-72A0-7DAC-002D4CAA3394	D9538	朱志红(壹)(航辉)(离)	江门整件分拣口区	东莞总部->江门时捷->江门仓储部->江门整件配货部->江门整件分拣口区	7245D0C0-5355-4D0B-903B-5E65C46485AA	分拣员
BFED2F2B-937F-0814-DF02-003967D356A5	D8558	雷雄(壹)(外)	江门配送一组	东莞总部->江门时捷->江门配送部->江门配送一组	EEC97BD6-51FA-4E7F-85C2-ACC44AAD86F2	驾驶员              
A00C75EA-D7B9-DB60-F31C-003E2B546F1D	E0928	文能欠(中鑫)(离)	贵州拆零组	东莞总部->贵州时捷->贵州仓储部->贵州拆零组	93DF5510-8892-4AF4-8A24-36FC0B28B08A	配货员              
EA0C1218-A686-1EA1-5E92-005221BB39C1	D7646	吴品色	茶山集货组	东莞总部->茶山时捷->茶山仓储部->茶山集货部->茶山集货组	C03914BF-4B78-44D3-9D50-B9FBD363A256	集筐员              
B8F1AC93-C71B-5E23-C9CE-005FBF298236	D9740	万安才(泰邦)(外)(离)	安徽配送四组	东莞总部->北京捷联->安徽捷联->安徽捷联配送部->安徽配送四组	EEC97BD6-51FA-4E7F-85C2-ACC44AAD86F2	驾驶员              
CB9B91CC-16AC-4164-A338-0061BA3E97F0	B4194     	陈境活	揭阳收理退组	东莞总部->揭阳时捷->揭阳仓储部->揭阳收理退组	6CCDA9C4-338E-43D3-AF5D-E1567F425F75	班长                
F92A3573-0E2F-7870-8F6B-006C4E882AE0	C6852	钱贵珍(离)	山东仓储部	东莞总部->山东时捷->山东仓储部	93DF5510-8892-4AF4-8A24-36FC0B28B08A	配货员              

ALTER VIEW [dbo].[v_t_base_employee]
AS

	SELECT  a.id ,
        a.code ,
        a.name ,
		a.first_name,
        b.path ,
        a.brith_date ,
        b.name AS long_name ,
        dept.name AS longdeptname ,
        d.name AS typeName ,
        zhi.id AS dutyId ,
        zhi.name AS dutyName,
		r.id AS rank_id,
		r.[name] AS rank_name,
        CONVERT(VARCHAR(10), a.frist_join_date, 120) frist_join_date ,
        a.status ,
        a.gender ,
        CASE a.gender
          WHEN 1 THEN '女'
          ELSE '男'
        END gendername ,
        DATEDIFF(yy, a.brith_date, GETDATE()) AS age ,
        a.dept_id ,
        b.parent_id dept_parent_id ,
        a.hiredt ,
        f.sort AS sort ,
        e.office_tel ,
        a.regularworker_time ,
        CASE WHEN DATEADD(d, 90, a.leave_time) >= GETDATE() THEN 1
             ELSE 0
        END leave_status ,
        a.code AS EMP_ID ,
        zhi.SJID AS ps_id ,
        b.SJCode AS dpm_id ,
		b.SJCode,
        b.SJPCode AS Dpm_parent ,
        a.leave_time AS EMP_OutDate ,
        a.EMP_NormalDate ,
        a.EMP_Education ,
        a.EMP_TechLevel ,
        a.idcard_no ,
        a.type ,
        truck.EMP_TrkID AS emp_trkid ,
		truck.CarrierNumber AS TRK_ID,
        a.add_time
		,a.comp_id,
		a.ModifyTime,
		a.ModifyName,
		m.Name comp_name,
		m.SimpleName comp_simpleName,
		a.OASuperior,
	    b.manager dept_manager,
		CASE
           WHEN ISNULL(a.OASuperior, '') <> '' THEN
               a.OASuperior
           ELSE
               SUBSTRING(b.manager, 1, 5)
       END AS Superior,
		n.name AS OASuperiorName,
		a.InitiationState,
		a.InitiationTime,
		a.RetirementTime,
		a.Specialty,
		a.entryInformation
FROM    dbo.t_base_employee AS a
        LEFT OUTER JOIN dbo.ufn_get_dept_children('1F8DD5B1-EA39-4A55-9F3B-173D9FA22859')
        AS dept ON dept.id = a.dept_id
        LEFT OUTER JOIN ( SELECT    id ,
                                    name ,
                                    SJID
                          FROM      dbo.t_base_duty
                        ) AS zhi ON zhi.id = a.duty_id
        LEFT OUTER JOIN ( SELECT    id ,
                                    parent_id ,
                                    name ,
                                    path ,
                                    SJCode ,
                                    SJPCode,
									manager
                          FROM      dbo.t_base_department
                        ) AS b ON a.dept_id = b.id
        LEFT OUTER JOIN ( SELECT    name ,
                                    value
                          FROM      dbo.v_data_base_dictionary_detail
                          WHERE     ( code = 'hr_yuangongleixing' )
                        ) AS d ON a.type = d.value
        LEFT OUTER JOIN dbo.t_employee_human AS e ON a.id = e.eid
        LEFT JOIN t_base_post f ON a.dept_id = f.department_id
                                   AND a.duty_id = f.duty_id
        LEFT JOIN dbo.t_employee_truck truck ON a.code = truck.EMP_ID
		LEFT JOIN t_base_company m ON a.comp_id=m.FID
		LEFT JOIN t_base_employee n ON a.OASuperior=n.code
		LEFT JOIN t_base_rank r ON a.rank_id=r.id
WHERE   ( a.status = 0
          OR DATEADD(d, 360, a.leave_time) >= GETDATE()
		  OR a.code='D1660'
        ) ; 

GO