CREATE view [dbo].[vben_v_user_role_menu_actions] 
as
select a.userid,a.name,b.* from vben_v_user_role_menus a right join 
vben_v_role_menu_actions b  on a.roleid=b.role_id  and a.id=b.menu_id
GO

