# vben_menu_actions 菜单按钮表

> 对应 DDL: [../sql/vben_menu_actions.sql](../sql/vben_menu_actions.sql)

## 表说明

定义菜单下有哪些操作按钮（如新增、编辑、删除、导出等），供权限控制使用。

---

## 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | uniqueidentifier | 是 | 主键，默认 newid() |
| menu_id | uniqueidentifier | 是 | 所属菜单 ID |
| action_key | nvarchar(50) | 是 | 按钮唯一标识，如 `add`、`edit`、`delete` |
| label | nvarchar(50) | 是 | 按钮显示文本 |
| button_type | nvarchar(20) | 否 | 按钮类型 |
| action | nvarchar(100) | 是 | 触发的动作标识 |
| confirm_text | nvarchar(200) | 否 | 确认提示文案（如删除前弹窗） |
| sort | int | 否 | 排序，默认 0 |
| status | int | 否 | 状态，默认 1 |

---

## 关联关系

- `menu_id` → `vben_menus_new.id`
- `vben_t_sys_role_menu_actions.menu_action_id` → 本表 id
