namespace StoneApi.Controllers.QueryModel
{
  
    public class Condition
    {
        public string Field { get; set; } = string.Empty;
        public string Operator { get; set; } = "eq"; // eq, contains, startswith, endswith
        public string Value { get; set; } = string.Empty;
    }
}
