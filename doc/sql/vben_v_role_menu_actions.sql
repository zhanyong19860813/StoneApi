CREATE view  [dbo].[vben_v_role_menu_actions]
as 
select a.id,a.role_id,a.menu_action_id  ,b.menu_id,b.action_key,b.label,b.button_type,
b.action,b.confirm_text,b.sort,b.status from vben_t_sys_role_menu_actions a 
left join [dbo].[vben_menu_actions] b on a.menu_action_id=b.id
GO

