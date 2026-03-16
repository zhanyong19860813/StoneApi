using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using StoneApi.Controllers.service;
using System.Runtime.InteropServices;

namespace StoneApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VbenSchemaController : ControllerBase
    {
        private readonly SqlSugarClient _db;

        public VbenSchemaController(SqlSugarClient db)
        {
            _db = db;
        }

        /// <summary>
        /// 根据 entityName 生成 QueryTableSchema
        /// </summary>
        [HttpGet("GetSchema")]
        public IActionResult GetSchema(string entityName,string menuId)
        {
            if (string.IsNullOrWhiteSpace(entityName))
                return BadRequest("entityName 不能为空");

            if (string.IsNullOrWhiteSpace(menuId))
                return BadRequest("菜单ID menuId 不能为空");

            // 1️⃣ 查询实体定义
            var entity = _db.Queryable<EntityList>()
                .Where(x => x.entity_name == entityName && x.status == "1")
                .Single();

            if (entity == null)
                return NotFound("实体不存在");

            // 2️⃣ 查询列定义
            var columns = _db.Queryable<EntityColumn>()
                .Where(x => x.Entity_List_Id == entity.Id.ToString() && x.Status == "1")
                .OrderBy(x => x.List_Order)
                .OrderBy(x => x.Form_Order)
                .ToList();

             Guid roleId = Guid.Parse("55555555-5555-5555-5555-555555555551");

            string struserId = User.FindFirst("UserId").Value;

            Guid userid = Guid.Parse(struserId);
            //Guid menuId = Guid.Parse("5A5AE6D5-7785-4C91-8A2A-114948D6B284");

            // 3️⃣ 构建 schema
            var schema = VbenSchemaBuilder.Build(_db, userid, Guid.Parse(menuId),entity, columns);

            return Ok(
                new { 
                    code=0,
                    data = schema });
        }
    }

    [SugarTable("vben_entity_list")]
    public class EntityList
    {
        public Guid Id { get; set; }
        public string entity_name { get; set; }
        public string Title { get; set; }
        public string TableName { get; set; }

        public string actionModule { get; set;}

        public string PrimaryKey { get; set; }

        public string status { get; set; }

        public string sortFieldName { get; set; }

        public string sortType { get; set; }

        public string DeleteEntityName { get; set; }

        public string saveEntityName { get; set; }
        
    }

    [SugarTable("vben_entity_column")]
    public class EntityColumn
    {
        public string Entity_List_Id { get; set; }

        public string Field { get; set; }
        public string Title { get; set; }

        public bool Used_In_List { get; set; }
        public bool Used_In_Form { get; set; }

        public string Column_Type { get; set; }
        public int? Width { get; set; }
        public bool? Sortable { get; set; }
        public int? List_Order { get; set; }

        public string Form_Component { get; set; }

        public string Status { get; set; }
        public int? Form_Order { get; set; }
    }

}
