# StoneApi 接口说明

## 通用查询接口

### POST /api/DynamicQueryBeta/queryforvben

通用动态查询接口（最新版），前端动态列表根据 `entity_name` 配置调用，查询对应业务表数据。

**请求参数：**

```json
{
  "tableName": "string",
  "page": 0,
  "pageSize": 0,
  "sortBy": "string",
  "sortOrder": "string",
  "queryField": "string",
  "where": {
    "logic": "string",
    "conditions": [
      {
        "field": "string",
        "operator": "string",
        "value": "string"
      }
    ],
    "groups": ["string"]
  },
  "simpleWhere": {
    "additionalProp1": "string",
    "additionalProp2": "string",
    "additionalProp3": "string"
  }
}
```

| 参数 | 类型 | 说明 |
|------|------|------|
| tableName | string | 要查询的表名，对应 vben_entity_list.tableName |
| page | int | 页码 |
| pageSize | int | 每页条数 |
| sortBy | string | 排序字段 |
| sortOrder | string | 排序方向，如 `asc` / `desc` |
| queryField | string | 查询字段（如搜索范围） |
| where | object | 复杂查询条件，支持逻辑组合 |
| where.logic | string | 条件逻辑，如 `and` / `or` |
| where.conditions | array | 条件数组 |
| where.conditions[].field | string | 字段名 |
| where.conditions[].operator | string | 操作符，如 `eq`、`like`、`gt` 等 |
| where.conditions[].value | string | 值 |
| where.groups | array | 条件分组 |
| simpleWhere | object | 简单键值对条件，key 为字段名，value 为值 |

---

### POST /api/DynamicQueryBeta/queryforvben-cursor（游标分页 + 可选 COUNT，测试用）

适用于**大数据量**场景，使用游标分页替代 OFFSET，可选跳过 COUNT(*)。

**在 queryforvben 基础上新增参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| cursorValue | object | 上一页最后一条的游标值，首次请求不传 |
| cursorField | string | 游标字段名，不传则用 sortBy |
| needTotal | bool | 是否查询总数，默认 false（跳过 COUNT） |

**请求示例：**

```json
{
  "tableName": "t_base_employee",
  "pageSize": 20,
  "sortBy": "id",
  "sortOrder": "asc",
  "needTotal": false,
  "cursorValue": null
}
```

**下一页请求：** 将上一页返回的 `data.lastCursorValue` 作为 `cursorValue` 传入。

**响应：**

```json
{
  "code": 0,
  "data": {
    "items": [...],
    "total": -1,
    "lastCursorValue": "xxx-xxx-xxx"
  }
}
```

- `total=-1` 表示未统计（needTotal=false 时）
- `lastCursorValue` 用于请求下一页

---

## 菜单接口

### GET /api/Menu/GetMenuFromDb

从数据库获取菜单数据，后台拼接为 Vben 所需的 JSON 格式后返回。

**现状：** 后端负责数据查询 + 格式拼接（树形结构等）。

**后续改造计划：** 后端只返回原始 JSON 数据（平铺或简单结构），前端负责拼接/转换为 Vben 菜单所需的数据格式。职责分离，后端更轻量。

---

## 数据保存接口

### POST /api/DataSave/datasave-multi

**多表批量保存接口**，一次请求支持多张表的新增、修改、删除。主从表、多 tab 表单等场景可一次提交。

**事务：** 所有表在同一事务中执行，任一失败则全部回滚。

**请求体：**

```json
{
  "tables": [
    {
      "tableName": "string",
      "primaryKey": "string",
      "data": [
        { "FID": "xxx", "field1": "value1", "..." }
      ],
      "deleteRows": [
        { "FID": "xxx" }
      ]
    }
  ]
}
```

| 参数 | 类型 | 说明 |
|------|------|------|
| tables | array | 表数组，每项对应一张表 |
| tables[].tableName | string | 表名 |
| tables[].primaryKey | string | 主键列名，如 `FID`、`id` |
| tables[].data | array | 新增/修改的数据，每项为字段名→值的键值对 |
| tables[].deleteRows | array | 要删除的数据，至少包含主键列 |

**新增/修改/删除规则：**

| 操作 | 条件 |
|------|------|
| **新增** | `data` 中某行主键为空，或主键在数据库中不存在 |
| **修改** | `data` 中某行主键有值且数据库中存在该主键 |
| **删除** | `deleteRows` 中传入主键值，按主键执行 DELETE |

- 主键为空时，后端自动生成 GUID
- 使用 SQL Server `MERGE`，`data` 中的新增与修改在一次操作中完成
- 每张表可只传 `data`、只传 `deleteRows`，或两者都传；两者都无则跳过该表

**执行顺序：** 按 `tables` 数组顺序依次处理，先删后增/改。

**成功响应：**

```json
{
  "code": 0,
  "data": { "message": "多表保存成功" }
}
```

**失败响应：**

```json
{
  "code": -1,
  "message": "错误信息"
}
```

---

*（其他接口说明可继续补充）*
