# vben_t_sys_role_menus 角色菜单表

> 对应 DDL: [../sql/vben_t_sys_role_menus.sql](../sql/vben_t_sys_role_menus.sql)

## 表说明

定义角色与菜单的关联关系，即某角色拥有哪些菜单访问权限。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| role_id | uniqueidentifier | 否 | 角色 ID |
| menus_id | uniqueidentifier | 否 | 菜单 ID |
| bar_items | varchar(350) | 否 | **已废弃**。按钮权限请使用 `vben_t_sys_role_menu_actions` 表 |
| operate_range_type | varchar(200) | 否 | 数据范围类型 |
| dept_range | varchar(4000) | 否 | 部门范围 |
| define_condition | varchar(1000) | 否 | 自定义条件 |
| add_user | uniqueidentifier | 否 | 添加人 |
| add_time | datetime | 否 | 添加时间 |

---

## 关联关系

- `role_id` → `vben_role.id`
- `menus_id` → `vben_menus_new.id`

---

## 说明

- **bar_items**：早期设计中将按钮与菜单放在同一表，后拆分为 `vben_menu_actions` 与 `vben_t_sys_role_menu_actions`，此字段已冗余，新功能请勿使用。
