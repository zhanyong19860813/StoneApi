namespace StoneApi.Controllers.QueryModel
{
    public class ExportExcelRequest
    {
        public string TableName { get; set; }
        public List<string> Columns { get; set; }
        public Dictionary<string, object> Where { get; set; }
        public string SortBy { get; set; }
        public string SortOrder { get; set; }
    }
}
