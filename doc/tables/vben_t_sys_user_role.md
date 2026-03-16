# vben_t_sys_user_role 用户角色关系表

> 对应 DDL: [../sql/vben_t_sys_user_role.sql](../sql/vben_t_sys_user_role.sql)

## 表说明

用户与角色的多对多关系表，一个用户可拥有多个角色。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| user_id | uniqueidentifier | 否 | 用户 ID |
| role_id | uniqueidentifier | 否 | 角色 ID |
| add_user | uniqueidentifier | 否 | 添加人 |
| add_time | datetime | 否 | 添加时间，默认 getdate() |

---

## 关联关系

- `user_id` → `vben_t_sys_user.id`
- `role_id` → `vben_role.id`

---

## 相关视图

- `v_vben_t_sys_user_role`：本表关联用户、角色，扩展出 user_name、role_name 等字段
