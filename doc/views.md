# 视图说明

本文档描述各视图的用途、来源表及输出字段。

---

## 1. v_vben_t_sys_user_role 用户角色视图

**DDL:** [sql/v_vben_t_sys_user_role.sql](sql/v_vben_t_sys_user_role.sql)

**说明：** 用户-角色关系扩展视图，关联出用户名、角色名、员工编号等，便于列表展示和权限判断。

**来源表：** vben_t_sys_user_role、vben_t_sys_user、vben_role

**输出字段：** id, user_id, role_id, user_name, user_code, role_name, employee_id

---

## 2. vben_v_role_menu 角色菜单视图

**DDL:** [sql/vben_v_role_menu.sql](sql/vben_v_role_menu.sql)

**说明：** 角色与菜单的关联，扩展出菜单的 name、path、component、meta 等，供前端生成角色可见的菜单树。

**来源表：** vben_t_sys_role_menus、vben_menus_new

**输出字段：** id, role_id, menu_id, entity_name, url, component, meta, bar_items

**注意：** bar_items 为 vben_t_sys_role_menus 的冗余字段，已废弃，实际按钮权限请用 vben_v_role_menu_actions。

---

## 3. vben_v_user_menu 用户菜单视图

**DDL:** [sql/vben_v_user_menu.sql](sql/vben_v_user_menu.sql)

**说明：** 用户通过角色间接拥有的菜单。通过 user → user_role → role_menus → menus 关联得到。

**来源表：** vben_t_sys_user、vben_t_sys_user_role、vben_t_sys_role_menus、vben_menus_new

**输出字段：** uid, username, 以及 vben_menus_new 的全部列（id, name, path, component, meta, parent_id, status, type）

---

## 4. vben_v_role_menu_actions 角色菜单按钮视图

**DDL:** [sql/vben_v_role_menu_actions.sql](sql/vben_v_role_menu_actions.sql)

**说明：** 角色在某菜单下拥有的按钮权限，扩展出 action_key、label、button_type 等，供前端控制按钮显隐。

**来源表：** vben_t_sys_role_menu_actions、vben_menu_actions

**输出字段：** id, role_id, menu_action_id, menu_id, action_key, label, button_type, action, confirm_text, sort, status

---

## 5. vben_v_user_role_menus 用户角色菜单视图

**DDL:** [sql/vben_v_user_role_menus.sql](sql/vben_v_user_role_menus.sql)

**说明：** 用户+角色+菜单的关联视图，输出用户在某角色下拥有的菜单及用户名、角色名。被 vben_v_user_role_menu_actions 依赖。

**来源表：** vben_t_sys_role_menus、v_vben_t_sys_user_role、vben_menus_new、vben_t_sys_user、vben_role

**输出字段：** username, userid, roleid, rolename, 以及 vben_menus_new 的全部列（id, name, path 等）

---

## 6. vben_v_user_role_menu_actions 用户按钮权限视图

**DDL:** [sql/vben_v_user_role_menu_actions.sql](sql/vben_v_user_role_menu_actions.sql)

**说明：** 用户通过角色拥有的按钮权限。关联 vben_v_user_role_menus 与 vben_v_role_menu_actions，得到用户可见的菜单按钮。

**来源表：** vben_v_user_role_menus、vben_v_role_menu_actions

**输出字段：** userid, name（菜单名）, 以及 vben_v_role_menu_actions 的全部列

---

## 视图依赖关系

```
vben_v_user_role_menus
  ├── vben_t_sys_role_menus
  ├── v_vben_t_sys_user_role  ← vben_t_sys_user_role + user + role
  ├── vben_menus_new
  ├── vben_t_sys_user
  └── vben_role

vben_v_user_role_menu_actions
  ├── vben_v_user_role_menus
  └── vben_v_role_menu_actions
        ├── vben_t_sys_role_menu_actions
        └── vben_menu_actions
```
