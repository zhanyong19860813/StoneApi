using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SqlSugar;
using StoneApi.Controllers.QueryModel;
using StoneApi.QueryBuilder;
using System.Data;
using System.Text;

[ApiController]
[Route("api/[controller]")]
public class DynamicQueryBetaController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public DynamicQueryBetaController(SqlSugarClient db)
    {
        _db = db;
    }

    // ✅ 允许动态查询的表名白名单（区分大小写不敏感）
    private static readonly HashSet<string> AllowedTableNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "t_base_company",
        "t_product",
        "t_order",
          "ImageList",
          "t_base_department",
          "vben_menus"
        // 👆 按需添加你的表名
    };


    

    [HttpPost("queryforvben")]
    public IActionResult QueryPostForVben([FromBody] DynamicQueryRequest request)
    {
        try
        {
            var builder = new DynamicQuerySqlBuilder(_db);

            var result = builder.ExecuteQuery(  request );

            return Ok(new
            {
                code = 0,
                data = result   
            });
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    
   
    [HttpPost("ExportExcel")]
    public IActionResult ExportExcel([FromBody] DynamicQueryRequest request)
    {
        try
        {
            var builder = new DynamicQuerySqlBuilder(_db);

            DataTable data = builder.ExecuteQueryForExport(  request );

            var fileBytes = ExcelHelper.ExportDataTableToExcel(data);

            var fileName = $"{request.TableName}_{DateTime.Now:yyyyMMddHHmmss}.xlsx";

            return File(
                fileBytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }



    // 🔍 提取公共的字段验证方法
    private List<string> GetSafeFields(string queryField)
    {
        if (string.IsNullOrWhiteSpace(queryField))
            return new List<string> { "*" };

        var safeFields = queryField
            .Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(f => f.Trim())
            .Where(f => f.All(c => char.IsLetterOrDigit(c) || c == '_' || char.IsWhiteSpace(c) || f.Contains(" as ", StringComparison.OrdinalIgnoreCase)))
            .ToList();

        return safeFields.Any() ? safeFields : new List<string> { "*" };
    }

    // 🔍 提取公共的查询构建方法
    private (StringBuilder sqlBuilder, int total) BuildQueryWithPaging(
        string tableName,
        List<string> safeFields,
        string whereSql,
        List<SugarParameter> parameters,
        string sortBy,
        string sortOrder,
        int? page,
        int? pageSize)
    {
        // 构建查询SQL
        var sqlBuilder = new StringBuilder($"SELECT {string.Join(", ", safeFields)} FROM [{tableName}]");
        if (!string.IsNullOrEmpty(whereSql))
            sqlBuilder.Append(" WHERE ").Append(whereSql);

        if (!string.IsNullOrWhiteSpace(sortBy))
        {
            string dir = sortOrder?.Equals("desc", StringComparison.OrdinalIgnoreCase) == true ? "DESC" : "ASC";
            sqlBuilder.Append($" ORDER BY [{sortBy}] {dir}");
        }

        if (page.HasValue && pageSize.HasValue)
        {
            int offset = (page.Value - 1) * pageSize.Value;
            sqlBuilder.Append($" OFFSET {offset} ROWS FETCH NEXT {pageSize.Value} ROWS ONLY");
        }

        // 获取总条数
        string countSql = $"SELECT COUNT(*) FROM [{tableName}]";
        if (!string.IsNullOrEmpty(whereSql))
            countSql += " WHERE " + whereSql;

        int total = _db.Ado.GetInt(countSql, parameters.ToArray());

        return (sqlBuilder, total);
    }


    private (string whereSql, List<SugarParameter> parameters) BuildWhereClause(WhereNode node, ref int paramIndex)
    {
        var clauses = new List<string>();
        var parameters = new List<SugarParameter>();

        // 处理当前层 Conditions
        if (node.Conditions != null)
        {
            foreach (var cond in node.Conditions)
            {
                if (string.IsNullOrWhiteSpace(cond?.Field) || cond.Value == null)
                    continue;

                if (!IsValidColumnName(cond.Field))
                    throw new ArgumentException($"无效字段名: {cond.Field}");

                string paramName = $"p_{paramIndex++}";
                string clause;

                switch (cond.Operator?.ToLowerInvariant())
                {
                    case "eq":
                        clause = $"[{cond.Field}] = @{paramName}";
                        parameters.Add(new SugarParameter(paramName, cond.Value));
                        break;
                    case "contains":
                        clause = $"[{cond.Field}] LIKE @{paramName}";
                        parameters.Add(new SugarParameter(paramName, $"%{cond.Value}%"));
                        break;
                    case "startswith":
                        clause = $"[{cond.Field}] LIKE @{paramName}";
                        parameters.Add(new SugarParameter(paramName, $"{cond.Value}%"));
                        break;
                    case "endswith":
                        clause = $"[{cond.Field}] LIKE @{paramName}";
                        parameters.Add(new SugarParameter(paramName, $"%{cond.Value}"));
                        break;
                    default:
                        throw new ArgumentException($"不支持的操作符: {cond.Operator}");
                }
                clauses.Add(clause);
            }
        }

        // 处理子 Groups（嵌套 OR/AND）
        if (node.Groups != null)
        {
            foreach (var group in node.Groups)
            {
                var (subSql, subParams) = BuildWhereClause(group, ref paramIndex);
                if (!string.IsNullOrEmpty(subSql))
                {
                    // ✅ 关键修复：变量名改为 groupLogic，避免与下方 logic 冲突
                    string groupLogic = group.Logic?.Equals("or", StringComparison.OrdinalIgnoreCase) == true ? "OR" : "AND";
                    // 注意：subSql 已经是完整子句（如 "Code LIKE '%SY%' OR Location LIKE '%广东%'"）
                    // 所以我们只需加括号，groupLogic 实际未被使用（但保留以防后续扩展）
                    clauses.Add($"({subSql})");
                    parameters.AddRange(subParams);
                }
            }
        }

        if (!clauses.Any())
            return ("", new List<SugarParameter>());

        // ✅ 这里是当前层的连接逻辑（AND 或 OR）
        string logic = node.Logic?.Equals("or", StringComparison.OrdinalIgnoreCase) == true ? "OR" : "AND";
        string finalClause = string.Join($" {logic} ", clauses);
        return (finalClause, parameters);
    }


     //======================
     //字段名校验（请根据你的实际规则实现）
     //======================
    private bool IsValidColumnName(string name)
    {
        if (string.IsNullOrWhiteSpace(name)) return false;
        // 示例：只允许字母、数字、下划线，且不超过 64 字符
        return name.All(c => char.IsLetterOrDigit(c) || c == '_') && name.Length <= 64;
    }

}




