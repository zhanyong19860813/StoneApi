-- ============================================================
-- 为 vben_menu_actions 增加 form_code、requires_selection 字段
-- 用于「按钮 + 表单设计器」：点击按钮时按 form_code 加载表单弹窗
-- ============================================================

-- 1. 表 vben_menu_actions 增加字段
ALTER TABLE [dbo].[vben_menu_actions]
ADD 
  [form_code] [nvarchar](100) NULL,           -- 表单设计器编码，对应 vben_form_desinger.code
  [requires_selection] [bit] NULL DEFAULT 0;  -- 是否需勾选行（编辑场景传 selectedRows[0]）
GO

-- 2. 更新视图（依赖顺序：先删子视图，再删父视图，再创建父视图，再创建子视图）
IF OBJECT_ID('dbo.vben_v_user_role_menu_actions', 'V') IS NOT NULL
  DROP VIEW [dbo].[vben_v_user_role_menu_actions];
GO

IF OBJECT_ID('dbo.vben_v_role_menu_actions', 'V') IS NOT NULL
  DROP VIEW [dbo].[vben_v_role_menu_actions];
GO

CREATE VIEW [dbo].[vben_v_role_menu_actions]
AS
SELECT 
  a.id, a.role_id, a.menu_action_id,
  b.menu_id, b.action_key, b.label, b.button_type,
  b.action, b.confirm_text, b.sort, b.status,
  b.form_code, b.requires_selection
FROM vben_t_sys_role_menu_actions a
LEFT JOIN [dbo].[vben_menu_actions] b ON a.menu_action_id = b.id;
GO

CREATE VIEW [dbo].[vben_v_user_role_menu_actions] 
AS
SELECT a.userid, a.name, b.* 
FROM vben_v_user_role_menus a 
RIGHT JOIN vben_v_role_menu_actions b ON a.roleid = b.role_id AND a.id = b.menu_id;
GO

-- 说明：
-- 列表 schema 的 toolbar.actions 可含 form_code、requiresSelection（来自菜单或列表设计器）
