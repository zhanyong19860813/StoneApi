namespace StoneApi.Controllers.QueryModel
{
    public class QueryResult<T>
    {
        public List<T> items { get; set; }
        public int total { get; set; }
    }
}
