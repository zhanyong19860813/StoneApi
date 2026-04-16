namespace StoneApi.Controllers.QueryModel
{
 

    // ======================
    // DTO
    // ======================
    public class DynamicQueryRequest
    {
        public string TableName { get; set; } = string.Empty;

        // 支持分页
        public int? Page { get; set; }
        public int? PageSize { get; set; }

        // 排序
        public string? SortBy { get; set; }
        public string? SortOrder { get; set; }

        // 查询字段，可传 "a,b,c as d"
        public string? QueryField { get; set; }

        // 条件树
        public WhereNode? Where { get; set; }

        // 新增简单对象方式
        public Dictionary<string, string>? SimpleWhere { get; set; }




        /// <summary>
        /// 将简单的 key-value 条件转换成 WhereNode（默认模糊查询 contains）
        /// </summary>
        public  WhereNode MapSimpleWhereToWhereNode(Dictionary<string, string> simpleWhere)
        {
            if (simpleWhere == null || !simpleWhere.Any())
                return null;

            var node = new WhereNode
            {
                Logic = "AND",
                Conditions = simpleWhere
                    .Where(kv => !string.IsNullOrWhiteSpace(kv.Value)) // 忽略空值
                    .Select(kv =>
                    {
                        string key = kv.Key;
                        string field;
                        string op;
                        if (key.EndsWith("_gte", StringComparison.OrdinalIgnoreCase) && key.Length > 4)
                        {
                            field = key.Substring(0, key.Length - 4);
                            op = "gte";
                        }
                        else if (key.EndsWith("_lte", StringComparison.OrdinalIgnoreCase) && key.Length > 4)
                        {
                            field = key.Substring(0, key.Length - 4);
                            op = "lte";
                        }
                        else if (key.EndsWith("_eq", StringComparison.OrdinalIgnoreCase) && key.Length > 3)
                        {
                            field = key.Substring(0, key.Length - 3);
                            op = "eq";
                        }
                        else
                        {
                            field = key;
                            op = "contains";
                        }

                        return new Condition
                        {
                            Field = field,
                            Operator = op,
                            Value = kv.Value
                        };
                    }).ToList()
            };

            return node;
        }
    }
}
