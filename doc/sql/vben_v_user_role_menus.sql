 ALTER view [dbo].[vben_v_user_role_menus]
 as
 select d.username,d.id userid,e.id roleid,e.name rolename, c.* from vben_t_sys_role_menus a,v_vben_t_sys_user_role b,vben_menus_new c ,vben_t_sys_user d,vben_role e
 where a.role_id=b.role_id  and c.id=a.menus_id and d.id=b.user_id and e.id=a.role_id
GO

