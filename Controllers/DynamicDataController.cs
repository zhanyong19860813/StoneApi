using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using StoneApi.Controllers.QueryModel;

[ApiController]
[Route("api/[controller]")]
public class DynamicDataAssistantController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public DynamicDataAssistantController(SqlSugarClient db)
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
                "vben_role_menu",
          "v_t_sys_user_role"
        // 👆 按需添加你的表名
    };

    // ======================
    // POST 查询（复杂条件）
    // ======================
    [HttpPost("query")]
    public IActionResult QueryByPost([FromBody] QueryRequest request)
    {
        if (request == null)
            return BadRequest("请求体不能为空");

        if (string.IsNullOrWhiteSpace(request.TableName))
            return BadRequest("表名不能为空");

        // ✅ 修正：使用本地 AllowedTableNames 而非不存在的 AllowedDynamicTables
        if (!AllowedTableNames.Contains(request.TableName))
            return BadRequest($"不允许查询表：{request.TableName}");

        string selectClause = request.Top.HasValue && request.Top > 0
            ? $"SELECT TOP {Math.Min(request.Top.Value, 10000)} *"
            : "SELECT *";

        var sqlBuilder = new StringBuilder($"{selectClause} FROM [{request.TableName}]");
        var parameters = new List<SugarParameter>();
        int paramIndex = 0;

        if (request.Where != null)
        {
            var (whereSql, whereParams) = BuildWhereClause(request.Where, ref paramIndex);
            if (!string.IsNullOrEmpty(whereSql))
            {
                sqlBuilder.Append(" WHERE ").Append(whereSql);
                parameters.AddRange(whereParams);
            }
        }

        if (!string.IsNullOrWhiteSpace(request.OrderBy))
        {
            var orderParts = new List<string>();
            foreach (var part in request.OrderBy.Split(',', StringSplitOptions.RemoveEmptyEntries))
            {
                var trimmed = part.Trim();
                if (string.IsNullOrEmpty(trimmed)) continue;

                string[] segs = trimmed.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
                string field = segs[0];
                if (!IsValidColumnName(field))
                    return BadRequest($"无效的排序字段：{field}");

                string dir = segs.Length == 2 && segs[1].Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? "DESC"
                    : "ASC";

                orderParts.Add($"[{field}] {dir}");
            }

            if (orderParts.Any())
            {
                sqlBuilder.Append(" ORDER BY ").Append(string.Join(", ", orderParts));
            }
        }

        try
        {
            var data = _db.Ado.SqlQuery<dynamic>(sqlBuilder.ToString(), parameters.ToArray());
            return Ok(data);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"查询失败：{ex.Message}");
        }
    }

    // ======================
    // GET 查询（简单 + filter 表达式）
    // ======================
    [HttpGet("query")]
    public IActionResult QueryByGet(
        [FromQuery] string tableName,
        [FromQuery] string? filter = null,
        [FromQuery] int? top = null,
        [FromQuery] string? orderBy = null)
    {
        if (string.IsNullOrWhiteSpace(tableName))
            return BadRequest("表名不能为空");

        // ✅ 修正：使用本地 AllowedTableNames
        if (!AllowedTableNames.Contains(tableName))
            return BadRequest($"不允许查询表：{tableName}");

        var sqlBuilder = new StringBuilder();
        var parameters = new List<SugarParameter>();
        var whereClauses = new List<string>();

        if (!string.IsNullOrWhiteSpace(filter))
        {
            try
            {
                var parsed = ParseFilterExpression(filter.Trim(), parameters);
                if (!string.IsNullOrEmpty(parsed))
                {
                    whereClauses.Add(parsed);
                }
            }
            catch (Exception ex)
            {
                return BadRequest($"filter 表达式无效: {ex.Message}");
            }
        }
        else
        {
            // 兼容旧式平铺参数
            var allParams = Request.Query
                .Where(kvp => !new[] { "tableName", "filter", "top", "orderBy" }
                    .Contains(kvp.Key, StringComparer.OrdinalIgnoreCase))
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => (object)kvp.Value.ToString(),
                    StringComparer.OrdinalIgnoreCase);

            foreach (var filterParam in allParams)
            {
                string rawKey = filterParam.Key;
                string columnName;
                string operation = "eq";

                if (rawKey.EndsWith("__contains", StringComparison.OrdinalIgnoreCase))
                {
                    columnName = rawKey.Substring(0, rawKey.Length - "__contains".Length);
                    operation = "contains";
                }
                else if (rawKey.EndsWith("__startswith", StringComparison.OrdinalIgnoreCase))
                {
                    columnName = rawKey.Substring(0, rawKey.Length - "__startswith".Length);
                    operation = "startswith";
                }
                else if (rawKey.EndsWith("__endswith", StringComparison.OrdinalIgnoreCase))
                {
                    columnName = rawKey.Substring(0, rawKey.Length - "__endswith".Length);
                    operation = "endswith";
                }
                else
                {
                    columnName = rawKey;
                    operation = "eq";
                }

                if (!IsValidColumnName(columnName))
                    return BadRequest($"无效的字段名：{columnName}");

                string? valueStr = filterParam.Value?.ToString();
                if (string.IsNullOrEmpty(valueStr)) continue;

                string[] rawValues = valueStr.Split(',', StringSplitOptions.RemoveEmptyEntries);
                var orClauses = new List<string>();

                foreach (string rawVal in rawValues)
                {
                    string val = rawVal.Trim();
                    if (string.IsNullOrEmpty(val)) continue;

                    string paramName = $"p_{parameters.Count}";
                    switch (operation.ToLowerInvariant())
                    {
                        case "contains":
                            orClauses.Add($"[{columnName}] LIKE @{paramName}");
                            parameters.Add(new SugarParameter(paramName, $"%{val}%"));
                            break;
                        case "startswith":
                            orClauses.Add($"[{columnName}] LIKE @{paramName}");
                            parameters.Add(new SugarParameter(paramName, $"{val}%"));
                            break;
                        case "endswith":
                            orClauses.Add($"[{columnName}] LIKE @{paramName}");
                            parameters.Add(new SugarParameter(paramName, $"%{val}"));
                            break;
                        default:
                            orClauses.Add($"[{columnName}] = @{paramName}");
                            parameters.Add(new SugarParameter(paramName, val));
                            break;
                    }
                }

                if (orClauses.Count > 0)
                {
                    string finalClause = orClauses.Count == 1
                        ? orClauses[0]
                        : $"({string.Join(" OR ", orClauses)})";
                    whereClauses.Add(finalClause);
                }
            }
        }

        string selectClause = top.HasValue && top > 0
            ? $"SELECT TOP {Math.Min(top.Value, 10000)} *"
            : "SELECT *";
        sqlBuilder.Append($"{selectClause} FROM [{tableName}]");

        if (whereClauses.Any())
        {
            sqlBuilder.Append(" WHERE ").Append(string.Join(" AND ", whereClauses));
        }

        if (!string.IsNullOrWhiteSpace(orderBy))
        {
            var orderParts = new List<string>();
            foreach (var part in orderBy.Split(',', StringSplitOptions.RemoveEmptyEntries))
            {
                var trimmed = part.Trim();
                if (string.IsNullOrEmpty(trimmed)) continue;

                string[] segs = trimmed.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
                string field = segs[0];
                if (!IsValidColumnName(field))
                    return BadRequest($"无效的排序字段：{field}");

                string dir = segs.Length == 2 && segs[1].Equals("desc", StringComparison.OrdinalIgnoreCase)
                    ? "DESC"
                    : "ASC";

                orderParts.Add($"[{field}] {dir}");
            }

            if (orderParts.Any())
            {
                sqlBuilder.Append(" ORDER BY ").Append(string.Join(", ", orderParts));
            }
        }

        try
        {
            var data = _db.Ado.SqlQuery<dynamic>(sqlBuilder.ToString(), parameters.ToArray());
            //return Ok(new
            //{
            //    records = data,
            //    code = 0
            //});

            return Ok(new
            {
                code = 0, // 对应 successCode
                data = new
                {
                    items = data,
                    total = 100
                }
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"查询失败：{ex.Message}");
        }
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

   

    // ======================
    // 辅助方法：解析 filter 表达式（GET 用）
    // ======================
    private string ParseFilterExpression(string expr, List<SugarParameter> parameters)
    {
        if (string.IsNullOrWhiteSpace(expr)) return null;
        var tokens = TokenizeFilter(expr);
        var (clause, _) = ParseOr(tokens, 0, parameters);
        return clause;
    }

    private List<string> TokenizeFilter(string input)
    {
        var tokens = new List<string>();
        var current = new StringBuilder();
        bool inQuotes = false;

        for (int i = 0; i < input.Length; i++)
        {
            char c = input[i];
            if (c == '\'' && (i == 0 || input[i - 1] != '\\'))
            {
                inQuotes = !inQuotes;
                current.Append(c);
            }
            else if (char.IsWhiteSpace(c) && !inQuotes)
            {
                if (current.Length > 0)
                {
                    tokens.Add(current.ToString());
                    current.Clear();
                }
            }
            else
            {
                current.Append(c);
            }
        }
        if (current.Length > 0) tokens.Add(current.ToString());
        return tokens;
    }

    private (string clause, int nextIndex) ParseOr(List<string> tokens, int index, List<SugarParameter> parameters)
    {
        var left = ParseAnd(tokens, index, parameters);
        while (left.nextIndex < tokens.Count && tokens[left.nextIndex].Equals("or", StringComparison.OrdinalIgnoreCase))
        {
            var right = ParseAnd(tokens, left.nextIndex + 1, parameters);
            left = ($"({left.clause} OR {right.clause})", right.nextIndex);
        }
        return left;
    }

    private (string clause, int nextIndex) ParseAnd(List<string> tokens, int index, List<SugarParameter> parameters)
    {
        var left = ParseComparison(tokens, index, parameters);
        while (left.nextIndex < tokens.Count && tokens[left.nextIndex].Equals("and", StringComparison.OrdinalIgnoreCase))
        {
            var right = ParseComparison(tokens, left.nextIndex + 1, parameters);
            left = ($"({left.clause} AND {right.clause})", right.nextIndex);
        }
        return left;
    }

    private (string clause, int nextIndex) ParseComparison(List<string> tokens, int index, List<SugarParameter> parameters)
    {
        if (index >= tokens.Count) throw new ArgumentException("表达式不完整");

        if (tokens[index] == "(")
        {
            var (inner, next) = ParseOr(tokens, index + 1, parameters);
            if (next >= tokens.Count || tokens[next] != ")")
                throw new ArgumentException("缺少右括号 )");
            return ($"({inner})", next + 1);
        }

        if (index + 2 >= tokens.Count)
            throw new ArgumentException("条件格式错误，应为: field operator 'value'");

        string field = tokens[index];
        string op = tokens[index + 1];
        string rawValue = tokens[index + 2];

        if (!IsValidColumnName(field))
            throw new ArgumentException($"无效字段名: {field}");

        if (rawValue.StartsWith("'") && rawValue.EndsWith("'") && rawValue.Length >= 2)
            rawValue = rawValue.Substring(1, rawValue.Length - 2);
        else
            throw new ArgumentException("值必须用单引号包围，如 'value'");

        string paramName = $"p_{parameters.Count}";
        string clause;

        switch (op.ToLowerInvariant())
        {
            case "eq":
                clause = $"[{field}] = @{paramName}";
                parameters.Add(new SugarParameter(paramName, rawValue));
                break;
            case "co":
                clause = $"[{field}] LIKE @{paramName}";
                parameters.Add(new SugarParameter(paramName, $"%{rawValue}%"));
                break;
            case "sw":
                clause = $"[{field}] LIKE @{paramName}";
                parameters.Add(new SugarParameter(paramName, $"{rawValue}%"));
                break;
            case "ew":
                clause = $"[{field}] LIKE @{paramName}";
                parameters.Add(new SugarParameter(paramName, $"%{rawValue}"));
                break;
            default:
                throw new ArgumentException($"不支持的操作符: {op}，支持: eq, co, sw, ew");
        }

        return (clause, index + 3);
    }

    // ======================
    // 字段名校验（请根据你的实际规则实现）
    // ======================
    private bool IsValidColumnName(string name)
    {
        if (string.IsNullOrWhiteSpace(name)) return false;
        // 示例：只允许字母、数字、下划线，且不超过 64 字符
        return name.All(c => char.IsLetterOrDigit(c) || c == '_') && name.Length <= 64;
    }
}






