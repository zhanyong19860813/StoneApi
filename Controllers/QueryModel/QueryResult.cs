namespace StoneApi.Controllers.QueryModel
{
    public class QueryResult<T>
    {
        public List<T> Items { get; set; }
        public int Total { get; set; }
    }
}
