using SqlSugar;

namespace StoneApi.Controllers.QueryModel
{
     
    //public class DynamicQueryResult
    //{
    //    /// <summary>
    //    /// 查询总数 SQL
    //    /// </summary>
    //    public string CountSql { get; set; }

    //    /// <summary>
    //    /// 查询数据 / 导出数据 SQL
    //    /// </summary>
    //    public string DataSql { get; set; }

    //    /// <summary>
    //    /// SQL 参数（防注入）
    //    /// </summary>
    //    public List<SugarParameter> Parameters { get; set; } = new();

    //    /// <summary>
    //    /// 是否分页（导出一般不分页）
    //    /// </summary>
    //    public bool HasPaging { get; set; }
    //}


    public class DynamicQueryResult
    {
        public string Sql { get; set; }
        public List<SugarParameter> Parameters { get; set; } = new();
    }
}
