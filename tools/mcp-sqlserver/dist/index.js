"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const mcp_js_1 = require("@modelcontextprotocol/sdk/server/mcp.js");
const stdio_js_1 = require("@modelcontextprotocol/sdk/server/stdio.js");
const mssql_1 = __importDefault(require("mssql"));
const z = __importStar(require("zod/v4"));
/** 仅允许简单 SQL Server 标识符，防注入 */
const sqlIdent = z
    .string()
    .min(1)
    .max(128)
    .regex(/^[a-zA-Z_][a-zA-Z0-9_]*$/, '仅字母数字下划线，且不以数字开头');
let pool = null;
async function getPool() {
    if (pool?.connected)
        return pool;
    const connStr = process.env.SQLSERVER_CONNECTION_STRING?.trim();
    if (connStr) {
        pool = await mssql_1.default.connect(connStr);
        return pool;
    }
    const server = process.env.SQLSERVER_SERVER?.trim();
    const database = process.env.SQLSERVER_DATABASE?.trim();
    if (!server || !database) {
        throw new Error('请配置 SQLSERVER_CONNECTION_STRING，或同时设置 SQLSERVER_SERVER + SQLSERVER_DATABASE（可选 SQLSERVER_USER / SQLSERVER_PASSWORD）');
    }
    const port = process.env.SQLSERVER_PORT ? Number(process.env.SQLSERVER_PORT) : undefined;
    const user = process.env.SQLSERVER_USER?.trim();
    const password = process.env.SQLSERVER_PASSWORD ?? '';
    const cfg = {
        server,
        port,
        database,
        options: {
            encrypt: process.env.SQLSERVER_ENCRYPT !== 'false',
            trustServerCertificate: process.env.SQLSERVER_TRUST_CERT !== 'false',
        },
    };
    if (user) {
        cfg.user = user;
        cfg.password = password;
    }
    pool = await mssql_1.default.connect(cfg);
    return pool;
}
function textResult(obj) {
    return {
        content: [{ type: 'text', text: typeof obj === 'string' ? obj : JSON.stringify(obj, null, 2) }],
    };
}
/** 仅允许单条 SELECT，外包一层 TOP，避免无界扫描 */
function assertSafeSelectInner(sqlText) {
    const s = sqlText.trim();
    const lower = s.toLowerCase();
    if (!lower.startsWith('select')) {
        throw new Error('仅允许以 SELECT 开头的查询');
    }
    const banned = [
        ';',
        '--',
        '/*',
        '*/',
        ' xp_',
        ' openrowset',
        ' bulk ',
        ' insert ',
        ' update ',
        ' delete ',
        ' merge ',
        ' exec ',
        ' execute ',
        ' drop ',
        ' alter ',
        ' create ',
        ' truncate ',
        ' into ', // 防 SELECT INTO
    ];
    for (const b of banned) {
        if (lower.includes(b)) {
            throw new Error(`查询中包含不允许的片段: ${b.trim()}`);
        }
    }
    return s;
}
const mcpServer = new mcp_js_1.McpServer({
    name: 'mcp-sqlserver-stoneapi',
    version: '1.0.0',
}, {
    instructions: '连接 StoneApi 配套的 SQL Server 测试库。可列出表/视图、查看列信息、抽样行、列出存储过程及读取定义。自定义 SELECT 会外包 TOP 限制行数。仅用于只读分析。',
});
mcpServer.registerTool('sqlserver_list_tables', {
    description: '列出用户表与视图（INFORMATION_SCHEMA.TABLES）',
    inputSchema: {
        schemaName: z
            .string()
            .optional()
            .describe('可选，按架构筛选，如 dbo'),
    },
}, async ({ schemaName }) => {
    const p = await getPool();
    const req = p.request();
    if (schemaName?.trim()) {
        req.input('schema', mssql_1.default.NVarChar(128), schemaName.trim());
        const r = await req.query(`SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
         FROM INFORMATION_SCHEMA.TABLES
         WHERE TABLE_TYPE IN ('BASE TABLE','VIEW') AND TABLE_SCHEMA = @schema
         ORDER BY TABLE_SCHEMA, TABLE_NAME`);
        return textResult(r.recordset);
    }
    const r = await req.query(`SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
       FROM INFORMATION_SCHEMA.TABLES
       WHERE TABLE_TYPE IN ('BASE TABLE','VIEW')
       ORDER BY TABLE_SCHEMA, TABLE_NAME`);
    return textResult(r.recordset);
});
mcpServer.registerTool('sqlserver_describe_table', {
    description: '表/视图列定义 + 主键列（便于对存储过程、表单字段对齐）',
    inputSchema: {
        schemaName: sqlIdent.describe('架构名，如 dbo'),
        tableName: sqlIdent.describe('表名或视图名'),
    },
}, async ({ schemaName, tableName }) => {
    const p = await getPool();
    const req = p.request();
    req.input('s', mssql_1.default.NVarChar(128), schemaName);
    req.input('t', mssql_1.default.NVarChar(128), tableName);
    const cols = await req.query(`SELECT c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, c.NUMERIC_PRECISION,
              c.NUMERIC_SCALE, c.IS_NULLABLE, c.COLUMN_DEFAULT
       FROM INFORMATION_SCHEMA.COLUMNS c
       WHERE c.TABLE_SCHEMA = @s AND c.TABLE_NAME = @t
       ORDER BY c.ORDINAL_POSITION`);
    const req2 = p.request();
    req2.input('s', mssql_1.default.NVarChar(128), schemaName);
    req2.input('t', mssql_1.default.NVarChar(128), tableName);
    const pk = await req2.query(`SELECT kcu.COLUMN_NAME
       FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
       JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
         ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
       WHERE tc.TABLE_SCHEMA = @s AND tc.TABLE_NAME = @t AND tc.CONSTRAINT_TYPE = N'PRIMARY KEY'
       ORDER BY kcu.ORDINAL_POSITION`);
    return textResult({
        columns: cols.recordset,
        primaryKeyColumns: pk.recordset.map((r) => r.COLUMN_NAME),
    });
});
mcpServer.registerTool('sqlserver_sample_rows', {
    description: '按 TOP 抽样读取表或视图数据（不写库）',
    inputSchema: {
        schemaName: sqlIdent.describe('架构名，如 dbo'),
        tableName: sqlIdent.describe('表名或视图名'),
        maxRows: z.number().int().min(1).max(500).optional().default(100).describe('最多行数，默认 100，最大 500'),
    },
}, async ({ schemaName, tableName, maxRows }) => {
    const n = maxRows ?? 100;
    const p = await getPool();
    const q = `SELECT TOP (${n}) * FROM [${schemaName}].[${tableName}]`;
    const r = await p.query(q);
    return textResult({ rowCount: r.recordset?.length ?? 0, rows: r.recordset });
});
mcpServer.registerTool('sqlserver_list_procedures', {
    description: '列出存储过程（schema、名称、修改时间）',
    inputSchema: {
        schemaName: z.string().optional().describe('可选，按架构筛选'),
    },
}, async ({ schemaName }) => {
    const p = await getPool();
    if (schemaName?.trim()) {
        const req = p.request();
        req.input('schema', mssql_1.default.NVarChar(128), schemaName.trim());
        const r = await req.query(`SELECT SCHEMA_NAME(o.schema_id) AS procedure_schema, o.name AS procedure_name, o.modify_date
         FROM sys.procedures o
         WHERE SCHEMA_NAME(o.schema_id) = @schema
         ORDER BY procedure_schema, procedure_name`);
        return textResult(r.recordset);
    }
    const r = await p.query(`SELECT SCHEMA_NAME(o.schema_id) AS procedure_schema, o.name AS procedure_name, o.modify_date
       FROM sys.procedures o
       ORDER BY procedure_schema, procedure_name`);
    return textResult(r.recordset);
});
mcpServer.registerTool('sqlserver_get_procedure_definition', {
    description: '读取存储过程完整 T-SQL 定义（sys.sql_modules）',
    inputSchema: {
        schemaName: sqlIdent.describe('架构名，如 dbo'),
        procedureName: sqlIdent.describe('存储过程名，不含架构前缀'),
    },
}, async ({ schemaName, procedureName }) => {
    const p = await getPool();
    const req = p.request();
    req.input('s', mssql_1.default.NVarChar(128), schemaName);
    req.input('n', mssql_1.default.NVarChar(128), procedureName);
    const r = await req.query(`SELECT m.definition
       FROM sys.sql_modules m
       INNER JOIN sys.objects o ON m.object_id = o.object_id
       WHERE o.type = N'P' AND SCHEMA_NAME(o.schema_id) = @s AND o.name = @n`);
    const row = r.recordset?.[0];
    if (!row?.definition) {
        return textResult({ error: '未找到该存储过程', schemaName, procedureName });
    }
    return textResult(row.definition);
});
mcpServer.registerTool('sqlserver_select_query', {
    description: '执行只读 SELECT：必须是单条 SELECT 语句（可含 JOIN/WHERE 等），禁止分号注释 exec 等；结果外包 TOP 限制行数。用于复杂抽样或对照过程逻辑。',
    inputSchema: {
        sql: z.string().min(1).describe('一条 SELECT 语句，勿加分号'),
        maxRows: z.number().int().min(1).max(500).optional().default(200),
    },
}, async ({ sql: innerSql, maxRows }) => {
    const inner = assertSafeSelectInner(innerSql);
    const top = maxRows ?? 200;
    const wrapped = `SELECT TOP (${top}) * FROM (${inner}) AS _mcp_sub`;
    const p = await getPool();
    const r = await p.query(wrapped);
    return textResult({ rowCount: r.recordset?.length ?? 0, rows: r.recordset });
});
async function main() {
    const transport = new stdio_js_1.StdioServerTransport();
    await mcpServer.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
