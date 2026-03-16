# vben_t_sys_user 用户表

> 对应 DDL: [../sql/vben_t_sys_user.sql](../sql/vben_t_sys_user.sql)

## 表说明

系统用户表，存储登录账号及用户信息。支持内部/外部用户区分。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| username | varchar(100) | 是 | 用户名，登录账号 |
| password | varchar(100) | 是 | 密码 |
| employee_id | varchar(50) | 否 | 所属员工编号 |
| customer_no | varchar(50) | 否 | 客户编号（外部用户关联） |
| name | varchar(50) | 否 | 姓名 |
| effect_date | date | 否 | 生效日期 |
| expire_date | date | 否 | 失效日期 |
| status | smallint | 否 | 状态：0=正常，1=暂停，2=停用 |
| user_type | smallint | 否 | 用户类型：0=外部，1=内部，默认 1 |
| add_user | uniqueidentifier | 否 | 添加人 |
| add_time | datetime | 否 | 添加时间 |
| lock_state | smallint | 否 | 锁定状态 |
| unlock_time | datetime | 否 | 解锁时间 |

---

## 关联关系

- `vben_t_sys_user_role.user_id` → 本表 id
