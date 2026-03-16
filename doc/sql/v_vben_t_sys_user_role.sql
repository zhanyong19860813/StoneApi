CREATE VIEW [dbo].[v_vben_t_sys_user_role] as 
SELECT
    ur.id,
	user_id,
	role_id,
	u.name as user_name,
	u.username AS user_code,
	r.name as role_name,
	u.employee_id 
FROM 
	vben_t_sys_user_role ur,
	vben_t_sys_user u,
	vben_role r
WHERE
	ur.user_id=u.id 
	AND ur.role_id=r.id
GO
