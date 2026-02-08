using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using NPOI.SS.Formula.Functions;
using SqlSugar;

namespace StoneApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class QueryTreeDataController : ControllerBase
    {

        private readonly SqlSugarClient _db;

        public QueryTreeDataController(SqlSugarClient db)
        {
            _db = db;
        }

        /// <summary>
        /// 获取功能权限树
        /// </summary>
        [HttpGet("tree")]
        public IActionResult GetFunctionTree()
        {
            // 1️⃣ 动态查询（无实体）
            //var list = _db.Queryable<dynamic>()
            //    .AS("t_sys_function")
            //    .Select("id, id as [key], parent_id as parentId, name as title")
            //    .ToList();
            //var list = _db.Queryable<dynamic>()
            //   .AS("v_data_role_group")
            //   .Select("id, id as [key],parent_id parentId, name title")
            //   .ToList();
            var list = _db.Queryable<dynamic>()
               .AS("vben_role")
               .Select("id, id as [key],parent_id parentId, name title")
               .ToList();
            // select id, id as [key],group_id parentId, name title from[dbo].[t_sys_role]

            // 2️⃣ 构建树
            //  Guid parentid = new Guid("65B1B414-8468-440F-A224-FC5FE2C15CB6");

            Guid parentid = new Guid("00000000-0000-0000-0000-000000000000");
            
            var tree = BuildTree(list, parentid);

            return Ok( new { 
             code = 0,
             data = tree
            });
        }

        private List<dynamic> BuildTree(List<dynamic> source, Guid? parentId)
        {

            var treedata = source
                .Where(x => (Guid?)x.parentId == parentId).ToList();

            return source
                .Where(x => (Guid?)x.parentId == parentId)
                .Select(x => new
                {
                    key = x.key,
                    id= x.id,
                    title = x.title,
                    children = BuildTree(source, (Guid?)x.key)
                })
                .ToList<dynamic>();

         


        }

    }
}
