using SqlSugar;

namespace StoneApi.Controllers.QueryModel
{
    public class BuiltQueryResult
    {
        public string DataSql { get; set; }
        public string CountSql { get; set; }
        public List<SugarParameter> Parameters { get; set; } = new();
    }
}
