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

       // SqlSugarClient _db;



        public DynamicQuerySqlBuilder()
        {
            //_db = db;
        }

        //public BuiltQueryResult BuildQuery(DynamicQueryRequest request)
        //{ 
        //}

    //    /// <summary>
    //    /// 查询方法
    //    /// </summary>
    //    /// <param name="db"></param>
    //    /// <param name="request"></param>
    //    /// <param name="allowedTables"></param>
    //    /// <returns></returns>
    //    /// <exception cref="ArgumentException"></exception>
    //    public QueryResult<dynamic> ExecuteQuery(
    // SqlSugarClient db,
    // DynamicQueryRequest request,
    //HashSet<string> allowedTables)
    //    {
    //        //if (request == null)
    //        //    throw new ArgumentException("请求体不能为空");

    //        if (string.IsNullOrWhiteSpace(request.TableName))
    //            throw new ArgumentException("表名不能为空");

    //        if (!allowedTables.Contains(request.TableName))
    //            throw new ArgumentException($"不允许查询表：{request.TableName}");

    //        // 1️⃣ 查询字段
    //        string selectClause = GetQueryFieldStr(request.QueryField);

    //        // 2️⃣ where
    //        int paramIndex = 0;
    //        var (whereSql, parameters) = BuildWhereClauseFromRequest(request, ref paramIndex);

    //        // 3️⃣ 总数
    //        string countSql = $"SELECT COUNT(*) FROM [{request.TableName}]";
    //        if (!string.IsNullOrEmpty(whereSql))
    //            countSql += " WHERE " + whereSql;

    //        int total = db.Ado.GetInt(countSql, parameters.ToArray());

    //        // 4️⃣ 查询SQL
    //        var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");
    //        if (!string.IsNullOrEmpty(whereSql))
    //            sqlBuilder.Append(" WHERE ").Append(whereSql);

    //        if (!string.IsNullOrWhiteSpace(request.SortBy))
    //            sqlBuilder.Append(GetOrderByClause(request.SortBy, request.SortOrder));

    //        if (request.Page.HasValue && request.PageSize.HasValue)
    //        {
    //            int offset = (request.Page.Value - 1) * request.PageSize.Value;
    //            sqlBuilder.Append($" OFFSET {offset} ROWS FETCH NEXT {request.PageSize.Value} ROWS ONLY");
    //        }

    //        string sql = sqlBuilder.ToString();
    //        var items = db.Ado.SqlQuery<dynamic>(sql, parameters.ToArray());

    //        return new QueryResult<dynamic>
    //        {
    //            Items = items,
    //            Total = total
    //        };
    //    }


        /// <summary>
        /// 查询方法
        /// </summary>
        /// <param name="db"></param>
        /// <param name="request"></param>
        /// <param name="allowedTables"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public QueryResult<dynamic> ExecuteQuery(
    SqlSugarClient db,
    DynamicQueryRequest request,
    HashSet<string> allowedTables)
        {
            if (request == null)
                throw new ArgumentException("请求体不能为空");

            if (string.IsNullOrWhiteSpace(request.TableName))
                throw new ArgumentException("表名不能为空");

            if (!allowedTables.Contains(request.TableName))
                throw new ArgumentException($"不允许查询表：{request.TableName}");

            // 1️⃣ 查询字段
            string selectClause = GetQueryFieldStr(request.QueryField);

            // 2️⃣ where
            int paramIndex = 0;
            var (whereSql, parameters) = BuildWhereClauseFromRequest(request, ref paramIndex);

            // 3️⃣ 总数
            string countSql = $"SELECT COUNT(*) FROM [{request.TableName}]";
            if (!string.IsNullOrEmpty(whereSql))
                countSql += " WHERE " + whereSql;

            int total = db.Ado.GetInt(countSql, parameters.ToArray());

            // 4️⃣ 查询SQL
            var sqlBuilder = new StringBuilder($"SELECT {selectClause} FROM [{request.TableName}]");
            if (!string.IsNullOrEmpty(whereSql))
                sqlBuilder.Append(" WHERE ").Append(whereSql);

            if (!string.IsNullOrWhiteSpace(request.SortBy))
                sqlBuilder.Append(GetOrderByClause(request.SortBy, request.SortOrder));

            if (request.Page.HasValue && request.PageSize.HasValue)
            {
                int offset = (request.Page.Value - 1) * request.PageSize.Value;
                sqlBuilder.Append($" OFFSET {offset} ROWS FETCH NEXT {request.PageSize.Value} ROWS ONLY");
            }

            string sql = sqlBuilder.ToString();
            var items = db.Ado.SqlQuery<dynamic>(sql, parameters.ToArray());

            return new QueryResult<dynamic>
            {
                Items = items,
                Total = total
            };
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
    SqlSugarClient db,
    DynamicQueryRequest request,
    HashSet<string> allowedTables)
        {
            if (request == null)
                throw new ArgumentException("请求体不能为空");

            if (string.IsNullOrWhiteSpace(request.TableName))
                throw new ArgumentException("表名不能为空");

            if (!allowedTables.Contains(request.TableName))
                throw new ArgumentException($"不允许导出表：{request.TableName}");

            // 1️⃣ 查询字段
            string selectClause = GetQueryFieldStr(request.QueryField);

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
            DataTable data = db.Ado.GetDataTable(sql, parameters.ToArray());

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
            else if (request.SimpleWhere != null)
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
}