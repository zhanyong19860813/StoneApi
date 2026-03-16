namespace StoneApi.Controllers.QueryModel
{
    /// <summary>
    /// 游标分页 + 可选 COUNT 的查询请求（扩展 DynamicQueryRequest）
    /// </summary>
    public class DynamicQueryCursorRequest : DynamicQueryRequest
    {
        /// <summary>
        /// 上一页最后一条的游标字段值，首次请求不传或传 null
        /// </summary>
        public object? CursorValue { get; set; }

        /// <summary>
        /// 游标字段名，用于 WHERE cursorField > cursorValue。不传则用 SortBy
        /// </summary>
        public string? CursorField { get; set; }

        /// <summary>
        /// 是否查询总数。false 时跳过 COUNT(*)，total 返回 -1 表示未统计
        /// </summary>
        public bool NeedTotal { get; set; } = false;
    }
}
