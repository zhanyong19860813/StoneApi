namespace StoneApi.Controllers.QueryModel
{
    /// <summary>
    /// 游标分页查询结果
    /// </summary>
    public class QueryResultCursor<T>
    {
        public List<T> items { get; set; }
        /// <summary>
        /// 总数。NeedTotal=false 时为 -1 表示未统计
        /// </summary>
        public int total { get; set; }
        /// <summary>
        /// 当前页最后一条的游标值，用于请求下一页
        /// </summary>
        public object? lastCursorValue { get; set; }
    }
}
