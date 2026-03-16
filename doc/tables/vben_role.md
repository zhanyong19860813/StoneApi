# vben_role 角色表

> 对应 DDL: [../sql/vben_role.sql](../sql/vben_role.sql)

## 表说明

系统角色定义表，支持树形结构（通过 parent_id）。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键 |
| name | nvarchar(100) | 否 | 角色名称 |
| parent_id | uniqueidentifier | 否 | 父角色 ID，NULL 表示顶级角色 |
| datatype | nvarchar(10) | 否 | **待定**，暂无明确用途 |
| createtime | datetime | 否 | 创建时间，默认 getdate() |
| createUser | nvarchar(20) | 否 | 创建人 |

---

## 关联关系

- `parent_id` → `vben_role.id`（自关联，树形角色）
- `vben_t_sys_user_role.role_id` → 本表 id
- `vben_t_sys_role_menus.role_id` → 本表 id
- `vben_t_sys_role_menu_actions.role_id` → 本表 id
