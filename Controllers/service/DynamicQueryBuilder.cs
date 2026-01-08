//using SqlSugar;
//using StoneApi.Controllers.QueryModel;
//using System.Text;

//namespace StoneApi.Controllers.service
//{
//    using System.Text;
//    using SqlSugar;
//    using StoneApi.Controllers.QueryModel;

//    public static class DynamicQueryBuilder
//    {
//        #region 主入口

//        public static DynamicQueryResult Build(
//            string tableName,
//            string? queryField,
//            WhereNode? where,
//            string? sortBy,
//            string? sortOrder,
//            int? page,
//            int? pageSize,
//            bool enablePaging,
//            Func<string, bool> columnValidator
//        )
//        {
//            var parameters = new List<SugarParameter>();
//            int paramIndex = 0;

//            // 1️⃣ SELECT
//            string selectClause = BuildSelectClause(queryField, columnValidator);

//            // 2️⃣ WHERE
//            string whereSql = "";
//            if (where != null)
//            {
//                (whereSql, var whereParams) =
//                    BuildWhereClause(where, ref paramIndex);

//                parameters.AddRange(whereParams);
//            }

//            // 3️⃣ COUNT SQL
//            var countSql = new StringBuilder($"SELECT COUNT(*) FROM [{tableName}]");
//            if (!string.IsNullOrEmpty(whereSql))
//                countSql.Append(" WHERE ").Append(whereSql);

//            // 4️⃣ DATA SQL
//            var dataSql = new StringBuilder($"SELECT {selectClause} FROM [{tableName}]");
//            if (!string.IsNullOrEmpty(whereSql))
//                dataSql.Append(" WHERE ").Append(whereSql);

//            // 5️⃣ ORDER
//            if (!string.IsNullOrWhiteSpace(sortBy))
//            {
//                if (!columnValidator(sortBy))
//                    throw new ArgumentException($"无效排序字段: {sortBy}");

//                string dir = sortOrder?.Equals("desc", StringComparison.OrdinalIgnoreCase) == true
//                    ? "DESC"
//                    : "ASC";

//                dataSql.Append($" ORDER BY [{sortBy}] {dir}");
//            }

//            // 6️⃣ PAGE
//            if (enablePaging && page.HasValue && pageSize.HasValue)
//            {
//                int offset = (page.Value - 1) * pageSize.Value;
//                dataSql.Append($" OFFSET {offset} ROWS FETCH NEXT {pageSize.Value} ROWS ONLY");
//            }

//            return new DynamicQueryResult
//            {
//                CountSql = countSql.ToString(),
//                DataSql = dataSql.ToString(),
//                Parameters = parameters
//            };
//        }

//        #endregion

//        #region SELECT

//        private static string BuildSelectClause(
//            string? queryField,
//            Func<string, bool> columnValidator
//        )
//        {
//            if (string.IsNullOrWhiteSpace(queryField))
//                return "*";

//            var fields = queryField
//                .Split(',', StringSplitOptions.RemoveEmptyEntries)
//                .Select(f => f.Trim());

//            var list = new List<string>();

//            foreach (var field in fields)
//            {
//                var parts = field.Split(
//                    new[] { " as ", " AS " },
//                    StringSplitOptions.RemoveEmptyEntries
//                );

//                if (parts.Length == 1)
//                {
//                    if (!columnValidator(parts[0]))
//                        throw new ArgumentException($"无效字段: {parts[0]}");

//                    list.Add($"[{parts[0]}]");
//                }
//                else if (parts.Length == 2)
//                {
//                    var column = parts[0].Trim();
//                    var alias = parts[1].Trim();

//                    if (!columnValidator(column))
//                        throw new ArgumentException($"无效字段: {column}");

//                    // alias 允许中文
//                    if (!alias.All(c =>
//                            char.IsLetterOrDigit(c)
//                            || c == '_'
//                            || c >= 0x4e00))
//                        throw new ArgumentException($"无效别名: {alias}");

//                    list.Add($"[{column}] AS [{alias}]");
//                }
//                else
//                {
//                    throw new ArgumentException($"字段格式错误: {field}");
//                }
//            }

//            if (!list.Any())
//                throw new ArgumentException("查询字段不能为空");

//            return string.Join(", ", list);
//        }

//        #endregion

//        #region WHERE

//        private static (string sql, List<SugarParameter> parameters)
//            BuildWhereClause(WhereNode node, ref int paramIndex)
//        {
//            var parameters = new List<SugarParameter>();
//            var sql = BuildWhereInternal(node, parameters, ref paramIndex);
//            return (sql, parameters);
//        }

//        private static string BuildWhereInternal(
//            WhereNode node,
//            List<SugarParameter> parameters,
//            ref int paramIndex
//        )
//        {
//            if (node == null) return "";

//            // 组合条件
//            if (node.Children != null && node.Children.Any())
//            {
//                var parts = node.Children
//                    .Select(child =>
//                        BuildWhereInternal(child, parameters, ref paramIndex))
//                    .Where(s => !string.IsNullOrWhiteSpace(s))
//                    .ToList();

//                if (!parts.Any())
//                    return "";

//                string joiner = node.Logic?.ToUpper() == "OR" ? " OR " : " AND ";
//                return "(" + string.Join(joiner, parts) + ")";
//            }

//            // 叶子条件
//            string paramName = $"@p{paramIndex++}";
//            parameters.Add(new SugarParameter(paramName, node.Value));

//            return node.Operator switch
//            {
//                "=" => $"[{node.Field}] = {paramName}",
//                "!=" => $"[{node.Field}] <> {paramName}",
//                ">" => $"[{node.Field}] > {paramName}",
//                ">=" => $"[{node.Field}] >= {paramName}",
//                "<" => $"[{node.Field}] < {paramName}",
//                "<=" => $"[{node.Field}] <= {paramName}",
//                "like" => $"[{node.Field}] LIKE {paramName}",
//                "contains" => $"[{node.Field}] LIKE '%' + {paramName} + '%'",
//                _ => throw new NotSupportedException($"不支持操作符: {node.Operator}")
//            };
//        }

//        #endregion
//    }


//}
