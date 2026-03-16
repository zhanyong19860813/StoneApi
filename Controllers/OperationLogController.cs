using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using System.Text.Json;

namespace StoneApi.Controllers;

/// <summary>
/// 操作日志 - 接收前端上报的菜单/按钮点击，后端 SQL 由 SqlSugar Aop 记录
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class OperationLogController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public OperationLogController(IConfiguration config, IHttpContextAccessor httpContextAccessor)
    {
        _config = config;
        _httpContextAccessor = httpContextAccessor;
    }

    /// <summary>
    /// 记录前端操作（菜单点击、按钮点击）
    /// 用户信息从 JWT 解析，不信任前端传递
    /// </summary>
    [HttpPost("Record")]
    [Authorize]
    public IActionResult Record([FromBody] OperationLogRecordRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.ActionType))
            return BadRequest(new { code = -1, message = "action_type 不能为空" });

        var userId = User.FindFirst("employeeId")?.Value ?? User.FindFirst("sub")?.Value ?? User.FindFirst("userId")?.Value ?? "";
        var userName = User.Identity?.Name ?? User.FindFirst("name")?.Value ?? "";
        var ip = GetClientIp();
        var endpoint = $"{Request.Method} {Request.Path}";

        TryWriteLog(new LogEntry
        {
            UserId = userId,
            UserName = userName,
            ActionType = request.ActionType,
            Target = request.Target,
            Description = request.Description,
            RequestParams = request.RequestParams,
            Endpoint = endpoint,
            Ip = ip,
        });

        return Ok(new { code = 0, message = "ok" });
    }

    private string? GetClientIp()
    {
        var ip = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (string.IsNullOrEmpty(ip))
            ip = Request.Headers["X-Real-IP"].FirstOrDefault();
        if (string.IsNullOrEmpty(ip) && HttpContext.Connection.RemoteIpAddress != null)
            ip = HttpContext.Connection.RemoteIpAddress.ToString();
        return ip;
    }

    /// <summary>
    /// 写日志到数据库，失败不影响主流程
    /// </summary>
    internal static void TryWriteLog(LogEntry entry, string? connStr = null)
    {
        try
        {
            var cs = connStr ?? GetConnectionString();
            if (string.IsNullOrEmpty(cs)) return;

            using var db = new SqlSugarClient(new ConnectionConfig
            {
                ConnectionString = cs,
                DbType = DbType.SqlServer,
                IsAutoCloseConnection = true,
            });

            var sql = @"INSERT INTO [dbo].[vben_sys_operation_log]
    ([user_id],[user_name],[action_type],[target],[description],[sql_text],[request_params],[endpoint],[ip])
VALUES (@userId,@userName,@actionType,@target,@desc,@sqlText,@reqParams,@endpoint,@ip)";

            db.Ado.ExecuteCommand(sql, new[]
            {
                new SugarParameter("@userId", entry.UserId ?? ""),
                new SugarParameter("@userName", entry.UserName ?? ""),
                new SugarParameter("@actionType", entry.ActionType),
                new SugarParameter("@target", entry.Target ?? ""),
                new SugarParameter("@desc", entry.Description ?? ""),
                new SugarParameter("@sqlText", entry.SqlText ?? ""),
                new SugarParameter("@reqParams", Truncate(entry.RequestParams, 4000)),
                new SugarParameter("@endpoint", entry.Endpoint ?? ""),
                new SugarParameter("@ip", entry.Ip ?? ""),
            });
        }
        catch
        {
            // 静默失败，不影响业务
        }
    }

    private static string Truncate(string? s, int maxLen)
    {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Length <= maxLen ? s : s.Substring(0, maxLen) + "...";
    }

    private static string? _staticConnStr;
    private static string? GetConnectionString()
    {
        return _staticConnStr;
    }
    internal static void SetConnectionString(string? s)
    {
        _staticConnStr = s;
    }
}

// 供 Aop 等非 Controller 场景调用
internal static class OperationLogHelper
{
    public static void TryWriteSqlLog(string? userId, string? userName, string sql, string? endpoint, string? ip, string? requestParams = null)
    {
        var actionType = "query";
        if (sql.TrimStart().StartsWith("INSERT", StringComparison.OrdinalIgnoreCase)) actionType = "save";
        else if (sql.TrimStart().StartsWith("UPDATE", StringComparison.OrdinalIgnoreCase)) actionType = "save";
        else if (sql.TrimStart().StartsWith("DELETE", StringComparison.OrdinalIgnoreCase)) actionType = "delete";

        OperationLogController.TryWriteLog(new LogEntry
        {
            UserId = userId,
            UserName = userName,
            ActionType = actionType,
            SqlText = sql.Length > 8000 ? sql.Substring(0, 8000) + "..." : sql,
            RequestParams = requestParams,
            Endpoint = endpoint,
            Ip = ip,
        });
    }
}

public class OperationLogRecordRequest
{
    public string ActionType { get; set; } = "";  // menu_click | button_click
    public string? Target { get; set; }
    public string? Description { get; set; }
    public string? RequestParams { get; set; }
}

internal class LogEntry
{
    public string? UserId { get; set; }
    public string? UserName { get; set; }
    public string ActionType { get; set; } = "";
    public string? Target { get; set; }
    public string? Description { get; set; }
    public string? SqlText { get; set; }
    public string? RequestParams { get; set; }
    public string? Endpoint { get; set; }
    public string? Ip { get; set; }
}
