 create view [dbo].[vben_v_user_menu]
 as  
 select a.id uid,a.username,d.* from vben_t_sys_user a 
left join  vben_t_sys_user_role b on a.id=b.user_id
left join  vben_t_sys_role_menus  c on b.role_id=c.role_id
left join  vben_menus_new  d  on c.menus_id=d.id
GO
