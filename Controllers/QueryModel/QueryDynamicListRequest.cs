using System.Collections.Generic;

namespace StoneApi.Controllers.QueryModel
{
    /// <summary>
    /// 动态列表查询请求
    /// </summary>
    public class QueryDynamicListRequest
    {
        /// <summary>
        /// 表名
        /// </summary>
        public string TableName { get; set; }

        /// <summary>
        /// 过滤条件（JSON格式）
        /// </summary>
        public string Filter { get; set; } = string.Empty;

        /// <summary>
        /// 查询参数（旧版）
        /// </summary>
        public Dictionary<string, object> Querys { get; set; }

        /// <summary>
        /// 排序字段
        /// </summary>
        public string OrderBy { get; set; }

        /// <summary>
        /// 页码（从1开始）
        /// </summary>
        public int PageIndex { get; set; } = 1;

        /// <summary>
        /// 每页大小
        /// </summary>
        public int PageSize { get; set; } = 10;
    }
}