using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using StoneApi.Controllers.QueryModel;
using System.Data;
using System.Text;

[ApiController]
[Route("api/[controller]")]
public class DynamicQueryController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public DynamicQueryController(SqlSugarClient db)
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
        // 👆 按需添加你的表名
    };


    [HttpPost("query")]
    public IActionResult QueryPost([FromBody] DynamicQueryRequest request)
    {
        if (request == null)
            return BadRequest("请求体不能为空");

        if (string.IsNullOrWhiteSpace(request.TableName))
            return BadRequest("表名不能为空");

        if (!AllowedTableNames.Contains(request.TableName))
            return BadRequest($"不允许查询表：{request.TableName}");

        // 1️⃣ 处理查询字段
        string selectClause = "*";
        if (!string.IsNullOrWhiteSpace(request.QueryField))
        {
            var safeFields = request.QueryField
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(f => f.Trim())
                .Where(f => f.All(c => char.IsLetterOrDigit(c) || c == '_' || char.IsWhiteSpace(c) || f.Contains(" as ", StringComparison.OrdinalIgnoreCase)))
                .ToList();

            if (!safeFields.Any())
                return BadRequest("查询字段无效");

            selectClause = string.Join(", ", safeFields);
        }

        // 2️⃣ 构建条件
        var parameters = new List<SugarParameter>();
        int paramIndex = 0;
        string whereSql = "";
        if (request.Where != null)
        {
            (whereSql, var whereParams) = BuildWhereClause(request.Where, ref paramIndex);
            if (!string.IsNullOrEmpty(whereSql))
                parameters.AddRange(whereParams);
        }

        // 3️⃣ 获取总条数
        string countSql = $"SELECT COUNT(*) FROM [{request.TableName}]";
        if (!string.IsNullOrEmpty(whereSql))
            countSql += " WHERE " + whereSql;

        int total = _db.Ado.GetInt(countSql, parameters.ToArray());

        // 4️⃣ 构建分页查询
        var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");
        if (!string.IsNullOrEmpty(whereSql))
            sqlBuilder.Append(" WHERE ").Append(whereSql);

        if (!string.IsNullOrWhiteSpace(request.SortBy))
        {
            string dir = request.SortOrder?.Equals("desc", StringComparison.OrdinalIgnoreCase) == true ? "DESC" : "ASC";
            if (!IsValidColumnName(request.SortBy))
                return BadRequest($"无效排序字段: {request.SortBy}");

            sqlBuilder.Append($" ORDER BY [{request.SortBy}] {dir}");
        }

        if (request.Page.HasValue && request.PageSize.HasValue)
        {
            int offset = (request.Page.Value - 1) * request.PageSize.Value;
            sqlBuilder.Append($" OFFSET {offset} ROWS FETCH NEXT {request.PageSize.Value} ROWS ONLY");
        }

        try
        {
            string sqlstr = sqlBuilder.ToString();
            var data = _db.Ado.SqlQuery<dynamic>(sqlstr, parameters.ToArray());

            return Ok(new
            {
                code = 0, // 对应 successCode
                data = new
                {
                    items = data,
                    total = total
                }
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"查询失败：{ex.Message}");
        }
    }


    /// <summary>
    /// vben前端查询接口
    /// </summary>
    /// <param name="request"></param>
    /// <returns></returns>
    [HttpPost("queryforvben")]
    public IActionResult QueryPostForVben([FromBody] DynamicQueryRequest request)
    {
        if (request == null)
            return BadRequest("请求体不能为空");

        if (string.IsNullOrWhiteSpace(request.TableName))
            return BadRequest("表名不能为空");

        if (!AllowedTableNames.Contains(request.TableName))
            return BadRequest($"不允许查询表：{request.TableName}");




        // 1️⃣ 处理查询字段
        string selectClause = "*";
        if (!string.IsNullOrWhiteSpace(request.QueryField))
        {
            var safeFields = request.QueryField
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(f => f.Trim())
                .Where(f => f.All(c => char.IsLetterOrDigit(c) || c == '_' || char.IsWhiteSpace(c) || f.Contains(" as ", StringComparison.OrdinalIgnoreCase)))
                .ToList();

            if (!safeFields.Any())
                return BadRequest("查询字段无效");

            selectClause = string.Join(", ", safeFields);
        }

        // 2️⃣ 构建条件
        var parameters = new List<SugarParameter>();
        int paramIndex = 0;
        string whereSql = "";

        var simpleWhere = request.SimpleWhere;

        //处理简单条件
        WhereNode effectiveWhere = request.Where ?? request.MapSimpleWhereToWhereNode(request.SimpleWhere);


        if (request.Where != null)
        {
            (whereSql, var whereParams) = BuildWhereClause(request.Where, ref paramIndex);
            if (!string.IsNullOrEmpty(whereSql))
                parameters.AddRange(whereParams);
        }
        else if (request.SimpleWhere != null)
        {
            (whereSql, var whereParams) = BuildWhereClause(effectiveWhere, ref paramIndex);
            if (!string.IsNullOrEmpty(whereSql))
                parameters.AddRange(whereParams);
        }







            // 3️⃣ 获取总条数
            string countSql = $"SELECT COUNT(*) FROM [{request.TableName}]";
        if (!string.IsNullOrEmpty(whereSql))
            countSql += " WHERE " + whereSql;

        int total = _db.Ado.GetInt(countSql, parameters.ToArray());

        // 4️⃣ 构建分页查询
        var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");
        if (!string.IsNullOrEmpty(whereSql))
            sqlBuilder.Append(" WHERE ").Append(whereSql);

        if (!string.IsNullOrWhiteSpace(request.SortBy))
        {
            string dir = request.SortOrder?.Equals("desc", StringComparison.OrdinalIgnoreCase) == true ? "DESC" : "ASC";
            if (!IsValidColumnName(request.SortBy))
                return BadRequest($"无效排序字段: {request.SortBy}");

            sqlBuilder.Append($" ORDER BY [{request.SortBy}] {dir}");
        }

        if (request.Page.HasValue && request.PageSize.HasValue)
        {
            int offset = (request.Page.Value - 1) * request.PageSize.Value;
            sqlBuilder.Append($" OFFSET {offset} ROWS FETCH NEXT {request.PageSize.Value} ROWS ONLY");
        }

        try
        {
            string sqlstr = sqlBuilder.ToString();
            var data = _db.Ado.SqlQuery<dynamic>(sqlstr, parameters.ToArray());

            return Ok(new
            {
                code = 0, // 对应 successCode
                data = new
                {
                    items = data,
                    total = total
                }
            });
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
            return Ok(data);
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"查询失败：{ex.Message}");
        }
    }






    [HttpPost("ExportExcel")]
    public IActionResult ExportExcel([FromBody] ExportExcelRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.TableName))
            return BadRequest("表名不能为空");

        if (req.Columns == null || req.Columns.Count == 0)
            return BadRequest("导出列不能为空");

        // 1️⃣ 构建查询
        var query = _db.Queryable<dynamic>().AS(req.TableName);

        // 2️⃣ Where 条件（动态）
        if (req.Where != null)
        {
            foreach (var kv in req.Where)
            {
                if (kv.Value == null) continue;

                var value = kv.Value.ToString();
                if (string.IsNullOrWhiteSpace(value)) continue;

                query = query.Where($"{kv.Key}.Contains(@val)", new { val = value });
            }
        }

        // 3️⃣ 排序
        if (!string.IsNullOrWhiteSpace(req.SortBy))
        {
            var order = req.SortOrder?.ToLower() == "desc" ? "desc" : "asc";
            query = query.OrderBy($"{req.SortBy} {order}");
        }

        // 4️⃣ 查询数据
        DataTable dt = query
            .Select(string.Join(",", req.Columns))
            .ToDataTable();

        // 5️⃣ 导出 Excel
        var fileBytes = ExcelHelper.ExportDataTableToExcel(dt);

        var fileName = $"{req.TableName}_{DateTime.Now:yyyyMMddHHmmss}.xlsx";

        return File(
            fileBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            fileName
        );
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




