using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StoneApi.Services;

namespace StoneApi.Controllers;

/// <summary>multipart 预览请求（单类型 [FromForm]，避免 Swashbuckle 与 IFormFile 混用多个参数时报错）。</summary>
public class JobSchedulingImportPreviewForm
{
    public IFormFile? File { get; set; }
    public string? OperatorName { get; set; }
    public string? OperatorEmpId { get; set; }
    public string? Mark { get; set; }
}

/// <summary>
/// 排班作业 Excel 导入（对齐老系统 FI_ID=1042 流程）。
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AttJobSchedulingImportController : ControllerBase
{
    private readonly JobSchedulingImportService _import;

    public AttJobSchedulingImportController(JobSchedulingImportService import)
    {
        _import = import;
    }

    /// <summary>
    /// 上传 Excel，校验后写入 Import_TMP_JobScheduling 并执行 Import_JobScheduling_CheckFunction。
    /// 全部通过时 CanCommit=true，前端可再调 commit。
    /// </summary>
    [HttpPost("preview")]
    [RequestSizeLimit(20_000_000)]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Preview([FromForm] JobSchedulingImportPreviewForm? form, CancellationToken ct)
    {
        var file = form?.File;
        if (file == null || file.Length == 0)
            return BadRequest(new { code = -1, message = "请选择 Excel 文件" });

        var opName = string.IsNullOrWhiteSpace(form?.OperatorName)
            ? User.FindFirst("name")?.Value ?? User.Identity?.Name ?? ""
            : form!.OperatorName!.Trim();
        var opEmp = string.IsNullOrWhiteSpace(form?.OperatorEmpId)
            ? User.FindFirst("employeeCode")?.Value ?? User.FindFirst("empId")?.Value ?? ""
            : form!.OperatorEmpId!.Trim();

        var mark = string.IsNullOrWhiteSpace(form?.Mark) ? "1042" : form!.Mark!.Trim();

        await using var stream = file.OpenReadStream();
        var r = await _import.PreviewAsync(stream, file.FileName, opName, opEmp, mark, ct);
        return Ok(new
        {
            code = 0,
            data = new
            {
                r.RowCount,
                r.CanCommit,
                errors = r.Errors.Select(e => new
                {
                    itemId = e.ItemId,
                    itemName = e.ItemName,
                    itemDetail = e.ItemDetail,
                    reason = e.Reason,
                }),
            },
        });
    }

    public class CommitBody
    {
        public string? OperatorName { get; set; }
        public string? Mark { get; set; }
    }

    /// <summary>
    /// 将当前操作人在临时表中的数据合并到 att_lst_JobScheduling（存储过程 + 清空临时表）。
    /// </summary>
    [HttpPost("commit")]
    public async Task<IActionResult> Commit([FromBody] CommitBody? body, CancellationToken ct)
    {
        var opName = string.IsNullOrWhiteSpace(body?.OperatorName)
            ? User.FindFirst("name")?.Value ?? User.Identity?.Name ?? ""
            : body!.OperatorName.Trim();
        if (string.IsNullOrEmpty(opName))
            return BadRequest(new { code = -1, message = "无法确定操作人姓名" });

        var (ok, msg) = await _import.CommitAsync(opName, body?.Mark ?? "1042", ct);
        if (!ok)
            return BadRequest(new { code = -1, message = msg });
        return Ok(new { code = 0, data = new { message = "导入成功" } });
    }
}
