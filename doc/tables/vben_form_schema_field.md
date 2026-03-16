# vben_form_schema_field 表单字段定义表

> 对应 DDL: [../sql/vben_form_schema_field.sql](../sql/vben_form_schema_field.sql)

## 表说明

定义表单（vben_form_schema）中的具体字段，包括组件类型、校验规则、布局等。与 vben_form_schema 配合，用于动态生成新增/编辑弹窗的表单内容。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| entitylistid | uniqueidentifier | 是 | 所属实体 ID |
| form_schema_id | uniqueidentifier | 是 | 所属表单 ID |
| field_name | nvarchar(100) | 是 | 字段名 |
| label | nvarchar(200) | 否 | 字段标签 |
| component | nvarchar(50) | 否 | 表单组件类型，如 Input、Select、DatePicker |
| component_props | nvarchar(max) | 否 | 组件属性，JSON 格式 |
| rules | nvarchar(max) | 否 | 校验规则，JSON 格式 |
| default_value | nvarchar(500) | 否 | 默认值 |
| sort | int | 否 | 排序，默认 0 |
| cols | int | 否 | 占据栅格列数，默认 1 |
| visible | bit | 否 | 是否可见，默认 1 |
| required | bit | 否 | 是否必填，默认 0 |
| remark | nvarchar(500) | 否 | 备注 |
| created_at | datetime | 否 | 创建时间，默认 getdate() |

---

## 关联关系

- `entitylistid` → `vben_entity_list.id`
- `form_schema_id` → `vben_form_schema.id`
