# vben_menus_new 菜单表

> 对应 DDL: [../sql/vben_menus_new.sql](../sql/vben_menus_new.sql)

## 表说明

Vben Admin 前端菜单配置表，用于动态生成侧边栏和路由。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| name | nvarchar(255) | 是 | 菜单名称，显示在侧边栏 |
| path | nvarchar(255) | 是 | 路由路径，如 `/entity/list` |
| component | nvarchar(255) | 是 | 前端组件路径，如 `views/EntityList/index` |
| meta | nvarchar(500) | 否 | JSON，扩展元数据（图标、标题、权限等） |
| parent_id | uniqueidentifier | 否 | 父菜单 ID，NULL 表示一级菜单 |
| status | int | 否 | 状态：0=禁用，1=启用 |
| type | nvarchar(50) | 是 | 类型：如 `menu`、`directory`、`button` |

---

## 关联关系

- `parent_id` → `vben_menus_new.id`（自关联，树形菜单）

---

## 示例 meta 结构

```json
{
  "title": "实体列表",
  "icon": "lucide:list",
  "order": 1,
  "hideInMenu": false
}
```
