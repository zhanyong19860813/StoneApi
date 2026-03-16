# StoneApi 数据库文档

## 表结构总览

### 权限部分

| 序号 | 表名 | 说明 |
|------|------|------|
| 1 | [vben_menus_new](tables/vben_menus_new.md) | 菜单表，Vben Admin 侧边栏/路由配置 |
| 2 | [vben_t_sys_user](tables/vben_t_sys_user.md) | 用户表 |
| 3 | [vben_role](tables/vben_role.md) | 角色表 |
| 4 | [vben_t_sys_user_role](tables/vben_t_sys_user_role.md) | 用户-角色关系表 |
| 5 | [vben_t_sys_role_menus](tables/vben_t_sys_role_menus.md) | 角色-菜单关系表。**bar_items 已废弃**，按钮权限用 vben_t_sys_role_menu_actions |
| 6 | [vben_menu_actions](tables/vben_menu_actions.md) | 菜单按钮表 |
| 7 | [vben_t_sys_role_menu_actions](tables/vben_t_sys_role_menu_actions.md) | 角色-菜单-按钮权限表 |

### 系统配置部分

| 序号 | 表名 | 说明 |
|------|------|------|
| 8 | [vben_entity_list](tables/vben_entity_list.md) | 实体定义表，用于动态生成列表 |
| 9 | [vben_entity_column](tables/vben_entity_column.md) | 实体列定义表 |
| 10 | [vben_form_schema](tables/vben_form_schema.md) | 表单定义表 |
| 11 | [vben_form_schema_field](tables/vben_form_schema_field.md) | 表单字段定义表 |

### 视图

| 序号 | 视图名 | 说明 |
|------|--------|------|
| 12 | vben_v_role_menu | 角色菜单视图 |
| 13 | vben_v_user_menu | 用户菜单视图 |
| 14 | vben_v_role_menu_actions | 角色菜单按钮视图 |
| 15 | vben_v_user_role_menu_actions | 用户拥有的按钮视图 |
| 16 | vben_v_user_role_menus | 用户拥有的菜单视图 |
| 17 | v_vben_t_sys_user_role | 用户角色视图 |

**视图说明详见** [views.md](views.md)

---

## 文档说明

- **sql/**：表与视图的 DDL
- **tables/**：各表的字段说明及业务含义
- **views.md**：各视图的用途、来源表及依赖关系
