using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;

namespace StoneApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DepRankController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public DepRankController(SqlSugarClient db)
    {
        _db = db;
    }

    public sealed class InheritItem
    {
        public string? dep_id { get; set; }
        public string? rank_id { get; set; }
    }

    public sealed class InheritRequest
    {
        public List<InheritItem>? items { get; set; }
    }

    [HttpPost("inherit")]
    public IActionResult Inherit([FromBody] InheritRequest? request)
    {
        var items = request?.items ?? [];
        if (items.Count == 0)
        {
            return BadRequest("请选择记录");
        }

        var operatorName =
            User.FindFirst("name")?.Value
            ?? User.Identity?.Name
            ?? "system";

        try
        {
            foreach (var item in items)
            {
                var depId = (item?.dep_id ?? "").Trim();
                var rankId = (item?.rank_id ?? "").Trim();
                if (string.IsNullOrWhiteSpace(depId) || string.IsNullOrWhiteSpace(rankId))
                {
                    return BadRequest("参数缺失：dep_id/rank_id");
                }

                _db.Ado.ExecuteCommand(
                    "EXEC pro_rank_inherit @root_id, @rank_id, @operator_name",
                    new SugarParameter("@root_id", depId),
                    new SugarParameter("@rank_id", rankId),
                    new SugarParameter("@operator_name", operatorName)
                );
            }

            return Ok(new { code = 0, data = true, message = "操作成功" });
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}

