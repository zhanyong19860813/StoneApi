# vben_entity_column 实体列定义表

> 对应 DDL: [../sql/vben_entity_column.sql](../sql/vben_entity_column.sql)

## 表说明

定义实体（vben_entity_list）拥有哪些列，用于动态列表的表格列配置和表单字段配置。同一列可配置在列表中显示、在表单中编辑，或两者兼有。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| entity_list_id | uniqueidentifier | 是 | 所属实体 ID |
| field | varchar(50) | 是 | 字段名，对应数据表列名 |
| title | varchar(100) | 否 | 列/字段显示标题 |
| used_in_list | bit | 否 | 是否在列表中展示，默认 1 |
| used_in_form | bit | 否 | 是否在表单中展示，默认 0 |
| column_type | varchar(20) | 否 | 列类型（如 text、date、number） |
| width | int | 否 | 列宽 |
| sortable | bit | 否 | 是否可排序 |
| list_order | int | 否 | 列表中的显示顺序 |
| form_component | varchar(50) | 否 | 表单中使用的组件类型 |
| form_order | int | 否 | 表单中的显示顺序 |
| status | int | 否 | 状态，默认 1 |

---

## 关联关系

- `entity_list_id` → `vben_entity_list.id`
