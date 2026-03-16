# vben_entity_list 实体定义表

> 对应 DDL: [../sql/vben_entity_list.sql](../sql/vben_entity_list.sql)

## 表说明

用于描述一个业务实体，动态生成列表时根据此表配置渲染表格。一个实体对应前端一个动态列表页面。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| entity_name | varchar(50) | 是 | 实体唯一标识，如 `Company`、`Order` |
| title | varchar(100) | 否 | 实体显示标题 |
| tableName | varchar(100) | 否 | 对应的数据库表名 |
| primaryKey | varchar(50) | 否 | 主键字段名，默认 `FID` |
| deleteEntityName | varchar(100) | 否 | **删除时使用的实体名**（可能与当前实体不同，用于删除接口） |
| saveEntityName | varchar(100) | 否 | **保存时使用的实体名**（可能与当前实体不同，用于保存接口） |
| defaultSchema | varchar(200) | 否 | 保留字段，暂未使用 |
| status | int | 否 | 状态，默认 1 |
| created_at | datetime | 否 | 创建时间 |
| updated_at | datetime | 否 | 更新时间 |
| actionModule | nvarchar(1000) | 否 | **前端路径**，如 `src/views/EntityList/company.ts`，该文件定义按钮的响应事件 |
| sortFieldName | nvarchar(50) | 否 | 默认排序字段 |
| sortType | nvarchar(10) | 否 | 排序方式，默认 `desc` |

---

## 关联关系

- `vben_entity_column.entity_list_id` → 本表 id（实体的列配置）
- `vben_form_schema.entitylistid` → 本表 id（实体的表单配置）

---

## 示例 actionModule

```
src/views/EntityList/company.ts
```

该 ts 文件中编写列表按钮（如导出、批量操作等）的点击事件逻辑。
