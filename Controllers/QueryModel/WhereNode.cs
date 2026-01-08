namespace StoneApi.Controllers.QueryModel
{
    public class WhereNode
    {
        public string Logic { get; set; } = "AND"; // "AND" 或 "OR"
        public List<Condition> Conditions { get; set; } = new();
        public List<WhereNode> Groups { get; set; } = new();
    }



 
    }
