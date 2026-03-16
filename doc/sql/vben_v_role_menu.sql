USE [SJHRsalarySystemDb]
GO

/****** Object:  View [dbo].[vben_v_role_menu]    Script Date: 2026/3/11 17:20:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE view  [dbo].[vben_v_role_menu]
as  
select a.id,a.role_id,a.menus_id menu_id,b.name entity_name,b.path url,b.component,b.meta, a.bar_items from  vben_t_sys_role_menus a
left join vben_menus_new b on a.menus_id=b.id
GO

