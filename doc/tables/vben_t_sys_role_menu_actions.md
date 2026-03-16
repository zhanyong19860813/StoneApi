# vben_t_sys_role_menu_actions 角色菜单按钮权限表

> 对应 DDL: [../sql/vben_t_sys_role_menu_actions.sql](../sql/vben_t_sys_role_menu_actions.sql)

## 表说明

定义某角色在某菜单下拥有哪些按钮权限。与 `vben_menu_actions` 配合使用，实现细粒度按钮级权限控制。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| role_id | uniqueidentifier | 是 | 角色 ID |
| menu_action_id | uniqueidentifier | 是 | 菜单按钮 ID（vben_menu_actions） |
| menu_id | uniqueidentifier | 是 | 菜单 ID，冗余便于查询 |
| status | int | 否 | 状态，默认 1 |
| add_time | datetime | 否 | 添加时间，默认 getdate() |

---

## 关联关系

- `role_id` → `vben_role.id`
- `menu_action_id` → `vben_menu_actions.id`
- `menu_id` → `vben_menus_new.id`
