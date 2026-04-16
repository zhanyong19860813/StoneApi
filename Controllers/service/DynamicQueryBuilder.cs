using Org.BouncyCastle.Bcpg.OpenPgp;
using SqlSugar;
using StoneApi.Controllers.QueryModel;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;

namespace StoneApi.QueryBuilder
{
    public   class DynamicQuerySqlBuilder
    {

         SqlSugarClient _db;

        // ✅ 允许动态查询的表名白名单（区分大小写不敏感）
        private static readonly HashSet<string> AllowedTableNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "vben_v_user_role_menu_actions",  // 用户菜单按钮权限，entityListFromDesigner 必需
        "t_base_company",
        "t_product",
        "t_order",
          "ImageList",
          "t_base_department",
          "vben_menus",
          "v_t_sys_user_role",
          "vben_role_menu",
          "vben_menus_new",
          "v_vben_t_sys_user_role",
          "vben_t_sys_user",
          "t_base_employee",
          "vben_v_role_menu",
          "v_t_employee_info",
          "vben_menu_actions",
          "vben_v_role_menu_actions",
          "vben_entity_list",
          "vben_form_schema_field",
          "vben_entity_column",
          "vben_entitylist_desinger",
          "vben_form_desinger",
          "vben_form_desinger",
          "vben_form_desinger",
          "vben_t_base_dictionary",
          "vben_t_base_dictionary_detail",
          "vben_sys_operation_log",
          "Dms_Lst_WaterOrElectricityPrice",
          "v_Dms_Lst_WaterOrElectricityPrice",
            "v_t_base_employee",
            "v_t_base_department"

        // 👆 按需添加你的表名
    };

        /// <summary>
        /// 表名是否允许查询（白名单 或 表设计器创建的 vben_t_ 前缀表）
        /// </summary>
        private static bool IsTableAllowed(string tableName)
        {
            //  if (string.IsNullOrWhiteSpace(tableName)) return false;
            ////  if (AllowedTableNames.Contains(tableName)) return true;
            //  if (tableName.StartsWith("vben_t_", StringComparison.OrdinalIgnoreCase)) return true;
            //  return false;

            return true;
        }

        public DynamicQuerySqlBuilder(SqlSugarClient db)
        {
             _db = db;
        }

 

        /// <summary>
        /// 查询方法
        /// </summary>
        /// <param name="db"></param>
        /// <param name="request"></param>
        /// <param name="allowedTables"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public QueryResult<dynamic> ExecuteQuery(DynamicQueryRequest request)
        {
          if (request == null)
                throw new ArgumentException("请求体不能为空");

            if (string.IsNullOrWhiteSpace(request.TableName))
                throw new ArgumentException("表名不能为空");

            if (!IsTableAllowed(request.TableName))
                throw new ArgumentException($"不允许查询表：{request.TableName}");

            // 1️⃣ 查询字段（字段全部被过滤时避免非法 SQL「SELECT  FROM」）
            string selectClause = GetQueryFieldStr(request.QueryField);
            if (string.IsNullOrWhiteSpace(selectClause))
                selectClause = "*";

            // 2️⃣ where
            int paramIndex = 0;
            var (whereSql, parameters) = BuildWhereClauseFromRequest(request, ref paramIndex);

            // 3️⃣ 总数
            string countSql = $"SELECT COUNT(*) FROM [{request.TableName}]";
            if (!string.IsNullOrEmpty(whereSql))
                countSql += " WHERE " + whereSql;

            int total = _db.Ado.GetInt(countSql, parameters.ToArray());

            // 4️⃣ 查询SQL
            var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");
            if (!string.IsNullOrEmpty(whereSql))
                sqlBuilder.Append(" WHERE ").Append(whereSql);

            if (!string.IsNullOrWhiteSpace(request.SortBy))
                sqlBuilder.Append(GetOrderByClause(request.SortBy, request.SortOrder));
            else if (request.Page.HasValue && request.PageSize.HasValue)
                // OFFSET/FETCH 必须有 ORDER BY，无 SortBy 时用常量兜底
                sqlBuilder.Append(" ORDER BY (SELECT 1)");

            if (request.Page.HasValue && request.PageSize.HasValue)
            {
                int offset = (request.Page.Value - 1) * request.PageSize.Value;
                sqlBuilder.Append($" OFFSET {offset} ROWS FETCH NEXT {request.PageSize.Value} ROWS ONLY");
            }

            string sql = sqlBuilder.ToString();
            var items = _db.Ado.SqlQuery<dynamic>(sql, parameters.ToArray());

            return new QueryResult<dynamic>
            {
                items = items,
                total = total
            };
        }


        /// <summary>
        /// 查询方法 查询第一行第一列
        /// </summary>
        /// <param name="request"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public object ExecuteScalar(DynamicQueryRequest request)
        {
            int paramIndex = 0;   // 👈 就在这里

            string select = GetQueryFieldStr(request.QueryField);

            if (select.Contains(","))
                throw new ArgumentException("Scalar 查询只能返回一个字段");

            var (whereSql, parameters) =
                BuildWhereClauseFromRequest(request, ref paramIndex);

            var sql = $"SELECT TOP 1 {select} FROM [{request.TableName}]";

            if (!string.IsNullOrEmpty(whereSql))
                sql += " WHERE " + whereSql;

            return _db.Ado.GetScalar(sql, parameters.ToArray());
        }


        /// <summary>
        /// 导出数据方法
        /// </summary>
        /// <param name="db"></param>
        /// <param name="request"></param>
        /// <param name="allowedTables"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public DataTable ExecuteQueryForExport(

    DynamicQueryRequest request
  )
        {
            if (request == null)
                throw new ArgumentException("请求体不能为空");

            if (string.IsNullOrWhiteSpace(request.TableName))
                throw new ArgumentException("表名不能为空");

            if (!IsTableAllowed(request.TableName))
                throw new ArgumentException($"不允许导出表：{request.TableName}");

            // 1️⃣ 查询字段
            string selectClause = GetQueryFieldStr(request.QueryField);
            if (string.IsNullOrWhiteSpace(selectClause))
                selectClause = "*";

            // 2️⃣ where
            int paramIndex = 0;
            var (whereSql, parameters) = BuildWhereClauseFromRequest(request, ref paramIndex);

            // 3️⃣ SQL
            var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");

            if (!string.IsNullOrEmpty(whereSql))
                sqlBuilder.Append(" WHERE ").Append(whereSql);

            if (!string.IsNullOrWhiteSpace(request.SortBy))
                sqlBuilder.Append(GetOrderByClause(request.SortBy, request.SortOrder));

            string sql = sqlBuilder.ToString();

            // 4️⃣ 查询数据
            DataTable data = _db.Ado.GetDataTable(sql, parameters.ToArray());

            return data;
        }

        /// <summary>
        /// 获取排序字段
        /// </summary>
        /// <param name="SortBy">  排序字段名</param>
        /// <param name="SortOrder">DESC|ASC  降序或升序</param>
        /// <returns></returns>
        private string GetOrderByClause(string SortBy, string SortOrder)
        {

            string sqlorderbystr = "";
            if (!string.IsNullOrWhiteSpace(SortBy))
            {
                string dir = SortOrder?.Equals("desc", StringComparison.OrdinalIgnoreCase) == true ? "DESC" : "ASC";
                //if (!IsValidColumnName( SortBy))
                //    return BadRequest($"无效排序字段: { SortBy}");

                sqlorderbystr = $" ORDER BY [{SortBy}] {dir}";

            }
            return sqlorderbystr;

        }

        /// <summary>
        /// 获取查询字段
        /// </summary>
        /// <param name="QueryField"></param>
        /// <returns></returns>
        private string GetQueryFieldStr(string QueryField)
        {

            string selectClause = "*";
            if (!string.IsNullOrWhiteSpace(QueryField))
            {
                var safeFields = QueryField
                    .Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(f => f.Trim())
                    .Where(f => f.All(c => char.IsLetterOrDigit(c) || c == '_' || char.IsWhiteSpace(c) || f.Contains(" as ", StringComparison.OrdinalIgnoreCase)))
                    .ToList();

                if (!safeFields.Any())
                    return null;

                selectClause = string.Join(", ", safeFields);
            }

            return selectClause;
        }


        // 🔍 提取构建条件的公共方法
        private (string whereSql, List<SugarParameter> parameters) BuildWhereClauseFromRequest(DynamicQueryRequest request, ref int paramIndex)
        {
            var parameters = new List<SugarParameter>();
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
            else if (request.SimpleWhere != null && request.SimpleWhere.Count > 0)
            {
                (whereSql, var whereParams) = BuildWhereClause(effectiveWhere, ref paramIndex);
                if (!string.IsNullOrEmpty(whereSql))
                    parameters.AddRange(whereParams);
            }

            return (whereSql, parameters);
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
                            parameters.Add(new SugarParameter(paramName, NormalizeScalarConditionValue(cond.Field, cond.Value)));
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
                        case "gte":
                            clause = $"[{cond.Field}] >= @{paramName}";
                            parameters.Add(new SugarParameter(paramName, NormalizeScalarConditionValue(cond.Field, cond.Value)));
                            break;
                        case "lte":
                            clause = $"[{cond.Field}] <= @{paramName}";
                            parameters.Add(new SugarParameter(paramName, NormalizeScalarConditionValue(cond.Field, cond.Value)));
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

        /// <summary>
        /// eq / gte / lte 条件：若值为合法 GUID 字符串则转为 <see cref="Guid"/>，
        /// 避免 SQL Server 将无效字符串隐式转换为 <c>uniqueidentifier</c> 时报错（如 id 为 undefined、含空格）。
        /// </summary>
        private static object NormalizeScalarConditionValue(string field, string? raw)
        {
            if (raw == null)
                throw new ArgumentException($"查询条件 [{field}] 的值不能为空。");
            var s = raw.Trim();
            if (s.Length == 0)
                throw new ArgumentException($"查询条件 [{field}] 的值不能为空。");
            if (string.Equals(s, "undefined", StringComparison.OrdinalIgnoreCase)
                || string.Equals(s, "null", StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException($"查询条件 [{field}] 无效（页面数据未就绪），请刷新后重试。");
            if (Guid.TryParse(s, out var g))
                return g;
            return s;
        }


        /// <summary>
        /// 游标分页 + 可选 COUNT（新方法，不影响原 ExecuteQuery）
        /// 使用 WHERE cursorField > cursorValue 替代 OFFSET，避免深分页变慢
        /// </summary>
        public QueryResultCursor<dynamic> ExecuteQueryCursor(DynamicQueryCursorRequest request)
        {
            if (request == null)
                throw new ArgumentException("请求体不能为空");
            if (string.IsNullOrWhiteSpace(request.TableName))
                throw new ArgumentException("表名不能为空");
            if (!IsTableAllowed(request.TableName))
                throw new ArgumentException($"不允许查询表：{request.TableName}");

            string cursorField = !string.IsNullOrWhiteSpace(request.CursorField) ? request.CursorField : request.SortBy;
            if (string.IsNullOrWhiteSpace(cursorField))
                throw new ArgumentException("游标分页必须指定 CursorField 或 SortBy");

            if (!IsValidColumnName(cursorField))
                throw new ArgumentException($"无效游标字段: {cursorField}");

            int pageSize = request.PageSize ?? 20;
            if (pageSize <= 0 || pageSize > 1000) pageSize = 20;

            int paramIndex = 0;
            var (whereSql, parameters) = BuildWhereClauseFromRequest(request, ref paramIndex);

            // 1️⃣ 可选 COUNT
            int total = -1;
            if (request.NeedTotal)
            {
                string countSql = $"SELECT COUNT(*) FROM [{request.TableName}]";
                if (!string.IsNullOrEmpty(whereSql)) countSql += " WHERE " + whereSql;
                total = _db.Ado.GetInt(countSql, parameters.ToArray());
            }

            // 2️⃣ 构建查询 SQL
            string selectClause = GetQueryFieldStr(request.QueryField);
            var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");
            var allParams = new List<SugarParameter>(parameters);

            // WHERE：原有条件 + 游标条件
            var whereClauses = new List<string>();
            if (!string.IsNullOrEmpty(whereSql)) whereClauses.Add($"({whereSql})");

            bool isDesc = request.SortOrder?.Equals("desc", StringComparison.OrdinalIgnoreCase) == true;
            if (request.CursorValue != null && request.CursorValue.ToString() != "")
            {
                string cursorParam = $"p_cursor_{paramIndex++}";
                string cursorCond = isDesc
                    ? $"[{cursorField}] < @{cursorParam}"
                    : $"[{cursorField}] > @{cursorParam}";
                whereClauses.Add(cursorCond);
                allParams.Add(new SugarParameter(cursorParam, request.CursorValue));
            }

            if (whereClauses.Count > 0)
                sqlBuilder.Append(" WHERE ").Append(string.Join(" AND ", whereClauses));

            sqlBuilder.Append(GetOrderByClause(cursorField, request.SortOrder));
            sqlBuilder.Append($" OFFSET 0 ROWS FETCH NEXT {pageSize} ROWS ONLY");

            string sql = sqlBuilder.ToString();
            var dt = _db.Ado.GetDataTable(sql, allParams.ToArray());

            var items = new List<dynamic>();
            object? lastCursorVal = null;
            foreach (DataRow row in dt.Rows)
            {
                var dict = new Dictionary<string, object>();
                foreach (DataColumn col in dt.Columns)
                {
                    var val = row[col];
                    dict[col.ColumnName] = val == DBNull.Value ? null! : val;
                }
                items.Add(dict);
                if (dt.Columns.Contains(cursorField))
                    lastCursorVal = row[cursorField] == DBNull.Value ? null : row[cursorField];
            }

            return new QueryResultCursor<dynamic>
            {
                items = items,
                total = total,
                lastCursorValue = lastCursorVal
            };
        }
    }
}