# MCP：SQL Server 只读（StoneApi 配套）

供 **Cursor** 通过 MCP 调用，在**测试库**上查看表/视图列表、列信息、抽样行、存储过程列表与定义；支持受限的自定义 `SELECT`（外包 `TOP`）。

## 1. 配置连接

```bash
cd tools/mcp-sqlserver
copy .env.example .env
# 编辑 .env，填写 SQLSERVER_CONNECTION_STRING（或分项变量）
npm install
npm run build
```

## 2. 接入 Cursor

打开 **Cursor → Settings → MCP**，增加一项（路径按你本机修改）：

```json
{
  "mcpServers": {
    "sqlserver-test": {
      "command": "node",
      "args": ["D:/code/StoneApi/tools/mcp-sqlserver/dist/index.js"],
      "env": {
        "SQLSERVER_CONNECTION_STRING": "Server=...;Database=...;User Id=...;Password=...;Encrypt=true;TrustServerCertificate=true"
      }
    }
  }
}
```

开发时可改用 `tsx` 免编译：

```json
"command": "npx",
"args": ["tsx", "D:/code/StoneApi/tools/mcp-sqlserver/src/index.ts"]
```

（需在 `mcp-sqlserver` 目录能解析到 `npx`，或写 `node_modules/.bin/tsx` 的绝对路径。）

## 3. 暴露的工具

| 工具名 | 作用 |
|--------|------|
| `sqlserver_list_tables` | 列出表/视图，可按 schema 筛选 |
| `sqlserver_describe_table` | 列定义 + 主键列 |
| `sqlserver_sample_rows` | `TOP N` 抽样（1～500） |
| `sqlserver_list_procedures` | 存储过程列表 |
| `sqlserver_get_procedure_definition` | 存储过程全文 |
| `sqlserver_select_query` | 单条 `SELECT`，禁止 `;`、`--`、`exec` 等，结果 `TOP` 限制 |

## 4. 安全说明

- 连接串建议**仅测试库**；本服务不做 `INSERT/UPDATE/DELETE`。
- `sqlserver_select_query` 仍可能被滥用读敏感数据，请用测试数据与账号权限控制。
