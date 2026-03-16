# vben_form_desinger 表单设计器配置表

> 对应 DDL: [../sql/vben_form_desinger.sql](../sql/vben_form_desinger.sql)

## 表说明

存储表单设计器生成的完整 schema，供列表设计器里配置的按钮（如「新增」「编辑」）点击时弹出表单使用。与 `vben_entitylist_desinger` 设计风格一致。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| code | nvarchar(50) | 是 | 表单编码，唯一。列表设计器按钮通过此字段引用，如 `company_add`、`company_edit` |
| title | nvarchar(200) | 否 | 表单标题，弹窗显示用 |
| schema_json | nvarchar(max) | 是 | 表单设计器完整输出，格式：`{ layout: { cols, layoutType }, schema: [...], tabs?: [...] }` |
| list_code | nvarchar(50) | 否 | 所属列表 code，便于在列表设计器里筛选「该列表可用表单」。空表示通用 |
| created_at | datetime | 否 | 创建时间 |
| updated_at | datetime | 否 | 更新时间 |

---

## schema_json 格式说明

与表单设计器导出的 JSON 一致：

```json
{
  "layout": {
    "cols": 2,
    "layoutType": "formOnly"
  },
  "schema": [
    {
      "fieldName": "name",
      "label": "名称",
      "component": "Input",
      "componentProps": { "placeholder": "请输入" }
    }
  ],
  "tabs": []
}
```

- `layoutType = "formTabsTable"` 时，`tabs` 为页签+表格配置
- `layoutType = "formOnly"` 时，`tabs` 可为空

---

## 与列表设计器的关联

列表 schema 的 `toolbar.actions` 中，新增/编辑等按钮可配置：

```json
{
  "key": "add",
  "label": "新增",
  "action": "openModal",
  "formSchemaCode": "company_add"
}
```

运行时根据 `formSchemaCode` 查询本表获取 `schema_json`，渲染弹窗表单。

---

## 与 vben_form_schema 的区别

- **vben_form_schema**：旧版实体驱动，关联 `vben_entity_list`，字段存 `vben_form_schema_field`，结构更拆分
- **vben_form_desinger**：设计器驱动，存完整 JSON，与列表设计器、表单设计器配合，配置即用
