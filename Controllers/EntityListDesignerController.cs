using Microsoft.AspNetCore.Mvc;
using SqlSugar;

namespace StoneApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EntityListDesignerController : ControllerBase
    {
        private readonly SqlSugarClient _db;

        public EntityListDesignerController(SqlSugarClient db)
        {
            _db = db;
        }

        /// <summary>
        /// 保存列表设计器配置
        /// </summary>
        [HttpPost("Save")]
        public IActionResult Save([FromBody] EntityListDesignerSaveRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.SchemaJson))
                return BadRequest(new { code = -1, message = "schema_json 不能为空" });

            if (string.IsNullOrWhiteSpace(request.Code))
                return BadRequest(new { code = -1, message = "code 不能为空" });

            try
            {
                var entity = new VbenEntitylistDesinger
                {
                    Id = request.Id ?? Guid.NewGuid(),
                    Code = request.Code,
                    Title = request.Title ?? "",
                    TableName = request.TableName ?? "",
                    SchemaJson = request.SchemaJson,
                    UpdatedAt = DateTime.Now
                };

                var exists = _db.Queryable<VbenEntitylistDesinger>()
                    .Where(x => x.Id == entity.Id)
                    .Any();

                if (exists)
                {
                    _db.Updateable(entity)
                        .IgnoreColumns(x => new { x.CreatedAt })
                        .ExecuteCommand();
                }
                else
                {
                    entity.CreatedAt = DateTime.Now;
                    _db.Insertable(entity).ExecuteCommand();
                }

                return Ok(new { code = 0, data = new { id = entity.Id, message = "保存成功" } });
            }
            catch (Exception ex)
            {
                return BadRequest(new { code = -1, message = ex.Message });
            }
        }
    }

    public class EntityListDesignerSaveRequest
    {
        public Guid? Id { get; set; }
        public string Code { get; set; }
        public string Title { get; set; }
        public string TableName { get; set; }
        public string SchemaJson { get; set; }
    }

    [SugarTable("vben_entitylist_desinger")]
    public class VbenEntitylistDesinger
    {
        [SugarColumn(IsPrimaryKey = true)]
        public Guid Id { get; set; }

        public string Code { get; set; }
        public string Title { get; set; }

        [SugarColumn(ColumnName = "table_name")]
        public string TableName { get; set; }

        [SugarColumn(ColumnName = "schema_json")]
        public string SchemaJson { get; set; }

        [SugarColumn(ColumnName = "created_at")]
        public DateTime? CreatedAt { get; set; }

        [SugarColumn(ColumnName = "updated_at")]
        public DateTime? UpdatedAt { get; set; }
    }
}
