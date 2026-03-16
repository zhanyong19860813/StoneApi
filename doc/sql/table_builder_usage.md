# 表结构设计器

通过界面建表，直接在数据库中创建。表名必须以 `vben_t_` 开头。

## API

- `POST /api/TableBuilder/CreateTable` - 创建表
- `POST /api/TableBuilder/AddColumn` - 给已有表添加字段
- `GET /api/TableBuilder/TableExists?tableName=xxx` - 检查表是否存在
- `GET /api/TableBuilder/ListTables` - 获取 vben_t_ 开头的表列表

## 权限

- DynamicQueryBuilder 已支持 `vben_t_*` 前缀的表，创建后自动可查询
- DataSave 无表名限制，可正常保存数据

## 前端路由

- `/demos/table-builder` - 表结构设计器页面
