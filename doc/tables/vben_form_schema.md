# vben_form_schema 表单定义表

> 对应 DDL: [../sql/vben_form_schema.sql](../sql/vben_form_schema.sql)

## 表说明

定义实体的表单配置。动态列表点击「新增」等按钮弹出的表单，根据本表及 `vben_form_schema_field` 生成。一个实体可有多个表单（如新增表单、编辑表单）。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| entitylistid | uniqueidentifier | 是 | 所属实体 ID |
| form_code | nvarchar(100) | 是 | 表单编码，如 `add`、`edit` |
| form_name | nvarchar(200) | 否 | 表单显示名称 |
| cols | int | 否 | 表单列数（栅格布局），默认 4 |
| remark | nvarchar(500) | 否 | 备注 |
| created_at | datetime | 否 | 创建时间，默认 getdate() |

---

## 关联关系

- `entitylistid` → `vben_entity_list.id`
- `vben_form_schema_field.form_schema_id` → 本表 id
- `vben_form_schema_field.entitylistid` → 本表 entitylistid

---

## 说明

- 字段命名使用 `entitylistid`，与 `vben_entity_column` 的 `entity_list_id` 命名风格不同，均指 `vben_entity_list.id`
