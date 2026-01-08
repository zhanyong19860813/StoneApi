namespace StoneApi.Controllers.QueryModel
{

    /// <summary>
    /// // ======================
    // 请求 DTO（POST 用）
    // ======================
    /// </summary>

    public class QueryRequest
        {
            public string TableName { get; set; } = string.Empty;
            public WhereNode? Where { get; set; }
            public string? OrderBy { get; set; }
            public int? Top { get; set; }
        }
   
}
