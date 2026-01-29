namespace StoneApi.Controllers.QueryModel
{
    public class ExportExcelRequest
    {
        //public string TableName { get; set; }
        //public List<string> Columns { get; set; }
        //public Dictionary<string, object> Where { get; set; }
        //public string SortBy { get; set; }
        //public string SortOrder { get; set; }



        //表名
        public string TableName { get; set; } = string.Empty;


        // 排序
        public string? SortBy { get; set; }
        public string? SortOrder { get; set; }

        // 查询字段，可传 "a,b,c as d"
        public string? QueryField { get; set; }

        // 条件树
        public WhereNode? Where { get; set; }

        // 新增简单对象方式
        public Dictionary<string, string>? SimpleWhere { get; set; }
    }
}
