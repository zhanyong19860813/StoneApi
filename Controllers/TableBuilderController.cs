using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using System.Text;
using System.Text.RegularExpressions;

namespace StoneApi.Controllers;

/// <summary>
/// 表结构设计器 - 在界面上建表，真实在数据库中创建
/// 创建的表名必须以 vben_t_ 开头，便于与 DynamicQuery 白名单联动
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class TableBuilderController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public TableBuilderController(SqlSugarClient db)
    {
        _db = db;
    }

    private const string TablePrefix = "vben_t_";
    private static readonly Regex TableNameRegex = new(@"^[a-zA-Z_][a-zA-Z0-9_]*$", RegexOptions.Compiled);
    private static readonly Regex ColumnNameRegex = new(@"^[a-zA-Z_][a-zA-Z0-9_]*$", RegexOptions.Compiled);

    /// <summary>
    /// 创建表
    /// </summary>
    [HttpPost("CreateTable")]
    public IActionResult CreateTable([FromBody] CreateTableRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.TableName))
            return BadRequest(new { code = -1, message = "表名不能为空" });

        var tableName = request.TableName.Trim();
        if (!tableName.StartsWith(TablePrefix, StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { code = -1, message = $"表名必须以 {TablePrefix} 开头" });

        if (!TableNameRegex.IsMatch(tableName))
            return BadRequest(new { code = -1, message = "表名只能包含字母、数字、下划线" });

        if (request.Columns == null || request.Columns.Count == 0)
            return BadRequest(new { code = -1, message = "至少需要定义一个字段" });

        var primaryColumns = request.Columns.Where(c => c.IsPrimaryKey).ToList();
        if (primaryColumns.Count == 0)
            return BadRequest(new { code = -1, message = "必须指定一个主键字段" });
        if (primaryColumns.Count > 1)
            return BadRequest(new { code = -1, message = "暂不支持复合主键，请只指定一个主键" });

        try
        {
            var sql = BuildCreateTableSql(tableName, request.Description, request.Columns);
            _db.Ado.ExecuteCommand(sql);
            return Ok(new { code = 0, message = "创建成功", tableName });
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = ex.Message });
        }
    }

    /// <summary>
    /// 给已有表添加字段
    /// </summary>
    [HttpPost("AddColumn")]
    public IActionResult AddColumn([FromBody] AddColumnRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.TableName))
            return BadRequest(new { code = -1, message = "表名不能为空" });
        if (request.Column == null)
            return BadRequest(new { code = -1, message = "字段定义不能为空" });

        var tableName = request.TableName.Trim();
        if (!tableName.StartsWith(TablePrefix, StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { code = -1, message = $"表名必须以 {TablePrefix} 开头" });

        if (!ColumnNameRegex.IsMatch(request.Column.Name.Trim()))
            return BadRequest(new { code = -1, message = "字段名只能包含字母、数字、下划线" });

        try
        {
            var colDef = BuildColumnDef(request.Column, forAlter: true);
            var sql = $"ALTER TABLE [{tableName}] ADD [{request.Column.Name.Trim()}] {colDef}";
            _db.Ado.ExecuteCommand(sql);
            return Ok(new { code = 0, message = "添加成功" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = ex.Message });
        }
    }

    /// <summary>
    /// 检查表是否存在
    /// </summary>
    [HttpGet("TableExists")]
    public IActionResult TableExists([FromQuery] string tableName)
    {
        if (string.IsNullOrWhiteSpace(tableName))
            return BadRequest(new { code = -1, message = "表名不能为空" });

        try
        {
            var sql = $@"
                SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @name";
            var count = _db.Ado.GetInt(sql, new SqlSugar.SugarParameter("@name", tableName.Trim()));
            return Ok(new { code = 0, exists = count > 0 });
        }
        catch
        {
            return Ok(new { code = 0, exists = false });
        }
    }

    /// <summary>
    /// 获取数据库中已存在的 vben_t_ 开头的表列表
    /// </summary>
    [HttpGet("ListTables")]
    public IActionResult ListTables()
    {
        try
        {
            var sql = @"
                SELECT TABLE_NAME as TableName
                FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME LIKE 'vben_t_%'
                ORDER BY TABLE_NAME";
            var list = _db.Ado.SqlQuery<string>(sql);
            return Ok(new { code = 0, data = list ?? new List<string>() });
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = ex.Message });
        }
    }

    /// <summary>
    /// 根据表名/视图名获取列信息，供列表设计器「表格列」自动带出。仅允许与 DynamicQuery 相同的白名单表或 vben_t_ 前缀表。
    /// </summary>
    [HttpGet("ListTableColumns")]
    public IActionResult ListTableColumns([FromQuery] string tableName)
    {
        if (string.IsNullOrWhiteSpace(tableName))
            return BadRequest(new { code = -1, message = "表名不能为空" });
        var name = tableName.Trim();
        if (!IsTableAllowedForColumns(name))
            return BadRequest(new { code = -1, message = $"不允许查询该表/视图的列信息: {name}" });
        try
        {
            var sql = @"
                SELECT COLUMN_NAME AS ColumnName, DATA_TYPE AS DataType, ORDINAL_POSITION AS OrdinalPosition
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @name
                ORDER BY ORDINAL_POSITION";
            var rows = _db.Ado.SqlQuery<TableColumnInfo>(sql, new SqlSugar.SugarParameter("@name", name));
            return Ok(new { code = 0, data = rows ?? new List<TableColumnInfo>() });
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = ex.Message });
        }
    }

    /// <summary>
    /// 与 DynamicQuery 白名单一致：仅允许白名单表或 vben_t_ 前缀表
    /// </summary>
    private static bool IsTableAllowedForColumns(string tableName)
    {
        if (string.IsNullOrWhiteSpace(tableName)) return false;
        if (AllowedTableNamesForColumns.Contains(tableName)) return true;
        if (tableName.StartsWith("vben_t_", StringComparison.OrdinalIgnoreCase)) return true;
        return false;
    }

    private static readonly HashSet<string> AllowedTableNamesForColumns = new(StringComparer.OrdinalIgnoreCase)
    {
        "vben_v_user_role_menu_actions", "t_base_company", "t_product", "t_order", "ImageList",
        "t_base_department", "vben_menus", "v_t_sys_user_role", "vben_role_menu", "vben_menus_new",
        "v_vben_t_sys_user_role", "vben_t_sys_user", "t_base_employee", "vben_v_role_menu", "v_t_employee_info",
        "vben_menu_actions", "vben_v_role_menu_actions", "vben_entity_list", "vben_form_schema_field",
        "vben_entity_column", "vben_entitylist_desinger", "vben_form_desinger", "vben_t_base_dictionary",
        "vben_t_base_dictionary_detail", "vben_sys_operation_log",
    };

    private string BuildCreateTableSql(string tableName, string? description, List<TableColumnDef> columns)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"CREATE TABLE [dbo].[{tableName}] (");

        var colDefs = new List<string>();
        string? primaryKeyCol = null;

        foreach (var col in columns)
        {
            if (!ColumnNameRegex.IsMatch(col.Name.Trim()))
                throw new ArgumentException($"无效字段名: {col.Name}");

            var def = BuildColumnDef(col, forAlter: false);
            if (col.IsPrimaryKey)
                primaryKeyCol = col.Name.Trim();
            colDefs.Add($"  [{col.Name.Trim()}] {def}");
        }

        sb.AppendLine(string.Join(",\r\n", colDefs));

        if (!string.IsNullOrEmpty(primaryKeyCol))
            sb.AppendLine($", CONSTRAINT [PK_{tableName}] PRIMARY KEY CLUSTERED ([{primaryKeyCol}] ASC)");

        sb.AppendLine(") ON [PRIMARY]");

        return sb.ToString();
    }

    private string BuildColumnDef(TableColumnDef col, bool forAlter)
    {
        var name = col.Name.Trim();
        var type = (col.DataType ?? "nvarchar").ToLowerInvariant();
        var length = col.Length ?? 50;
        var nullable = col.Nullable;
        var isPrimaryKey = col.IsPrimaryKey;
        var defaultValue = col.DefaultValue?.Trim();

        var typeStr = type switch
        {
            "int" => "int",
            "bigint" => "bigint",
            "smallint" => "smallint",
            "tinyint" => "tinyint",
            "bit" => "bit",
            "decimal" => $"decimal({col.Precision ?? 18},{col.Scale ?? 2})",
            "float" => "float",
            "datetime" => "datetime",
            "date" => "date",
            "time" => "time",
            "uniqueidentifier" => "uniqueidentifier",
            "varchar" => $"varchar({length})",
            "nvarchar" => $"nvarchar({length})",
            "char" => $"char({length})",
            "nchar" => $"nchar({length})",
            "text" => "nvarchar(max)",
            _ => $"nvarchar({length})"
        };

        var parts = new List<string> { typeStr };

        if (!nullable && !forAlter)
            parts.Add("NOT NULL");
        else if (nullable)
            parts.Add("NULL");

        if (!forAlter)
        {
            if (!string.IsNullOrEmpty(defaultValue))
            {
                if (type is "uniqueidentifier" && defaultValue.Equals("NEWID()", StringComparison.OrdinalIgnoreCase))
                    parts.Add("DEFAULT NEWID()");
                else if (type is "datetime" or "date" && defaultValue.Equals("GETDATE()", StringComparison.OrdinalIgnoreCase))
                    parts.Add("DEFAULT GETDATE()");
                else if (type is "bit" && (defaultValue == "0" || defaultValue == "1"))
                    parts.Add($"DEFAULT {defaultValue}");
                else if (type is "int" or "bigint" or "smallint" or "decimal" or "float")
                {
                    if (decimal.TryParse(defaultValue, out _))
                        parts.Add($"DEFAULT {defaultValue}");
                }
                else
                    parts.Add($"DEFAULT N'{defaultValue.Replace("'", "''")}'");
            }
            else if (type is "uniqueidentifier" && isPrimaryKey)
            {
                parts.Add("DEFAULT NEWID()");
            }
        }
        else if (!string.IsNullOrEmpty(defaultValue))
        {
            if (type is "uniqueidentifier" && defaultValue.Equals("NEWID()", StringComparison.OrdinalIgnoreCase))
                parts.Add("DEFAULT NEWID()");
            else if (type is "datetime" or "date" && defaultValue.Equals("GETDATE()", StringComparison.OrdinalIgnoreCase))
                parts.Add("DEFAULT GETDATE()");
            else if (type is "bit" && (defaultValue == "0" || defaultValue == "1"))
                parts.Add($"DEFAULT {defaultValue}");
            else if (type is "int" or "bigint" or "smallint" or "decimal" or "float" && decimal.TryParse(defaultValue, out _))
                parts.Add($"DEFAULT {defaultValue}");
            else
                parts.Add($"DEFAULT N'{defaultValue.Replace("'", "''")}'");
        }

        return string.Join(" ", parts);
    }
}

public class CreateTableRequest
{
    public string TableName { get; set; } = "";
    public string? Description { get; set; }
    public List<TableColumnDef> Columns { get; set; } = new();
}

public class AddColumnRequest
{
    public string TableName { get; set; } = "";
    public TableColumnDef Column { get; set; } = new();
}

public class TableColumnDef
{
    public string Name { get; set; } = "";
    public string DataType { get; set; } = "nvarchar";
    public int? Length { get; set; } = 50;
    public int? Precision { get; set; }
    public int? Scale { get; set; }
    public bool Nullable { get; set; } = true;
    public bool IsPrimaryKey { get; set; }
    public string? DefaultValue { get; set; }
    public string? Comment { get; set; }
}

/// <summary>
/// 表/视图列信息，供 ListTableColumns 返回
/// </summary>
public class TableColumnInfo
{
    public string ColumnName { get; set; } = "";
    public string? DataType { get; set; }
    public int OrdinalPosition { get; set; }
}
