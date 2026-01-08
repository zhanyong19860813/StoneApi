namespace StoneApi.Controllers.QueryModel
{
    public class BatchDeleteItem
    {
        public string TableName { get; set; }
        public string Key { get; set; }
        public List<string> Keys { get; set; }
    }
}
