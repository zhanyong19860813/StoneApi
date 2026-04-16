using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using SqlSugar;
using StoneApi.Services;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace StoneApi.Controllers;

/// <summary>
/// 部门手动同步至钉钉：在接口内直接调用钉钉开放平台 oapi（与老系统 <c>SyncHrmToDingTalkJob</c> 中部门逻辑一致），不再写入任务表或 EXEC 存储过程。
/// 依赖数据字典 <c>vben_t_base_dictionary.code = DingTalk_DeptSync</c> 及 <c>vben_t_base_dictionary_detail</c>（与「数据字典」页面、DataSave 一致）。
/// 推荐方式 A：明细 <c>corp_id</c>=应用 Client ID、<c>corp_secret</c>=Client Secret；换 token 时优先 appkey+appsecret，并兼容旧版 corpid+corpsecret。
/// 当前仅同步部门树（创建/更新/删除部门及 dingtalk_id），不同步 <c>t_base_department.manager</c>（部门主管需人员与钉钉 userid 对齐后再考虑）。
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DingTalkDeptSyncController : ControllerBase
{
    private const string DictCode = "DingTalk_DeptSync";

    private readonly SqlSugarClient _db;
    private readonly DingTalkOapiDepartmentService _oapi;

    public DingTalkDeptSyncController(SqlSugarClient db, DingTalkOapiDepartmentService oapi)
    {
        _db = db;
        _oapi = oapi;
    }

    /// <summary>
    /// 检查字典是否已配置且启用（前端可先调用于提示）。
    /// </summary>
    [HttpGet("config-status")]
    public IActionResult GetConfigStatus()
    {
        var st = LoadConfig();
        return Ok(new
        {
            code = 0,
            data = new
            {
                configured = st.DictionaryId != null,
                enabled = st.Enabled,
                missingKeys = st.MissingKeys,
            }
        });
    }

    public class SyncDepartmentRequest
    {
        /// <summary>部门主键 GUID（t_base_department.id）</summary>
        public string? DepartmentId { get; set; }
    }

    public class MatchDepartmentByNameRequest
    {
        /// <summary>部门主键 GUID（t_base_department.id）</summary>
        public string? DepartmentId { get; set; }

        /// <summary>
        /// underParent（默认）：仅在钉钉「上级部门」的子部门中按名称匹配（需上级 dingtalk_id 有效）；
        /// organization：从根部门 id=1 递归拉取全组织部门后按名称匹配（全企业同名多于一个则失败）。
        /// </summary>
        public string? Mode { get; set; }
    }

    /// <summary>
    /// 按部门名称在钉钉侧查找部门并回写本地 <c>dingtalk_id</c>（用于本地与钉钉已有部门但未对齐 id 的场景）。
    /// </summary>
    [HttpPost("match-department-by-name")]
    public async Task<IActionResult> MatchDepartmentByName([FromBody] MatchDepartmentByNameRequest req, CancellationToken ct)
    {
        var deptId = (req.DepartmentId ?? string.Empty).Trim();
        if (string.IsNullOrEmpty(deptId))
            return BadRequest(new { code = -1, message = "departmentId 不能为空" });
        if (!Guid.TryParse(deptId, out _))
            return BadRequest(new { code = -1, message = "departmentId 不是有效的 GUID" });

        var st = LoadConfig();
        if (st.DictionaryId == null)
            return BadRequest(new
            {
                code = -1,
                message = "未配置数据字典 DingTalk_DeptSync。"
            });
        if (st.MissingKeys.Count > 0)
            return BadRequest(new
            {
                code = -1,
                message = $"数据字典缺少或为空：{string.Join("、", st.MissingKeys)}。"
            });
        if (!st.Enabled)
            return BadRequest(new { code = -1, message = "钉钉部门同步未启用。" });

        var dept = LoadDepartmentRow(deptId);
        if (dept == null)
            return BadRequest(new { code = -1, message = "未找到该部门记录。" });

        var localName = (dept.Name ?? "").Trim();
        if (string.IsNullOrEmpty(localName))
            return BadRequest(new { code = -1, message = "部门名称为空，无法按名匹配。" });

        var mode = (req.Mode ?? "underParent").Trim();
        var orgWide = string.Equals(mode, "organization", StringComparison.OrdinalIgnoreCase);

        var tokenJo = await _oapi.GetTokenAsync(st.CorpId!, st.CorpSecret!, ct).ConfigureAwait(false);
        if (!DingTalkOapiDepartmentService.IsOk(tokenJo))
            return BadRequest(new
            {
                code = -1,
                message = "获取钉钉 access_token 失败：" + DingTalkOapiDepartmentService.ErrString(tokenJo)
            });
        var token = tokenJo["access_token"]?.ToString();
        if (string.IsNullOrEmpty(token))
            return BadRequest(new { code = -1, message = "钉钉未返回 access_token。" });

        try
        {
            List<(string Id, string Name, string? ParentId)> entries;

            if (orgWide)
            {
                var listObj = await _oapi.GetDepartmentListAsync(token, "1", true, ct).ConfigureAwait(false);
                if (!DingTalkOapiDepartmentService.IsOk(listObj))
                    return BadRequest(new
                    {
                        code = -1,
                        message = "拉取钉钉全组织部门失败：" + DingTalkOapiDepartmentService.ErrString(listObj)
                    });
                entries = DingTalkOapiDepartmentService.ParseDepartmentList(listObj);
            }
            else
            {
                if (string.IsNullOrWhiteSpace(dept.ParentId))
                    return BadRequest(new
                    {
                        code = -1,
                        message = "根部门请使用 mode=organization 在全组织内按名匹配，或手工维护 dingtalk_id。"
                    });

                var parentDdId = string.IsNullOrWhiteSpace(dept.ParentDingtalkId)
                    ? ResolveParentDingtalkId(deptId)
                    : dept.ParentDingtalkId!.Trim();

                if (string.IsNullOrWhiteSpace(parentDdId))
                    return BadRequest(new
                    {
                        code = -1,
                        message = "上级部门无有效 dingtalk_id，无法仅在父部门下匹配。请先同步上级，或改用 mode=organization。"
                    });

                var listObj = await _oapi.GetDepartmentListAsync(token, parentDdId, false, ct).ConfigureAwait(false);
                if (!DingTalkOapiDepartmentService.IsOk(listObj))
                    return BadRequest(new
                    {
                        code = -1,
                        message = "拉取钉钉子部门列表失败：" + DingTalkOapiDepartmentService.ErrString(listObj)
                    });
                entries = DingTalkOapiDepartmentService.ParseDepartmentList(listObj);
            }

            var matches = entries
                .Where(e => string.Equals(e.Name.Trim(), localName, StringComparison.Ordinal))
                .ToList();

            if (matches.Count == 0)
                return BadRequest(new
                {
                    code = -1,
                    message = orgWide
                        ? $"在全组织未找到与「{localName}」同名的钉钉部门。"
                        : $"在上级钉钉部门下未找到与「{localName}」同名的子部门。"
                });

            if (matches.Count > 1)
            {
                var ids = string.Join("、", matches.Select(m => m.Id));
                return BadRequest(new
                {
                    code = -1,
                    message =
                        $"钉钉侧存在 {matches.Count} 个同名部门「{localName}」，无法自动对应。请改部门名称消除歧义，或手工在钉钉侧确认后填写 dingtalk_id。候选 id：{ids}"
                });
            }

            var dingId = matches[0].Id;
            UpdateDepartmentDingtalkId(dept.DepartmentId!, dingId);

            return Ok(new
            {
                code = 0,
                message = orgWide
                    ? $"已按全组织名称匹配并回写 dingtalk_id={dingId}。"
                    : $"已在上级钉钉部门下按名称匹配并回写 dingtalk_id={dingId}。",
                data = new { dingtalkId = dingId }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = ex.Message });
        }
    }

    /// <summary>
    /// 将选中部门立即同步到钉钉（创建 / 更新 / 删除），并回写 <c>t_base_department.dingtalk_id</c>。
    /// </summary>
    [HttpPost("sync-department")]
    public async Task<IActionResult> SyncDepartment([FromBody] SyncDepartmentRequest req, CancellationToken ct)
    {
        var deptId = (req.DepartmentId ?? string.Empty).Trim();
        if (string.IsNullOrEmpty(deptId))
            return BadRequest(new { code = -1, message = "departmentId 不能为空" });
        if (!Guid.TryParse(deptId, out _))
            return BadRequest(new { code = -1, message = "departmentId 不是有效的 GUID" });

        var st = LoadConfig();
        if (st.DictionaryId == null)
            return BadRequest(new
            {
                code = -1,
                message = "未配置数据字典「钉钉部门同步」。请在系统数据字典中新增编码 DingTalk_DeptSync 及明细项（见迁移脚本说明）。"
            });
        if (st.MissingKeys.Count > 0)
            return BadRequest(new
            {
                code = -1,
                message = $"数据字典 DingTalk_DeptSync 缺少或为空：{string.Join("、", st.MissingKeys)}。请在数据字典中补全。"
            });
        if (!st.Enabled)
            return BadRequest(new
            {
                code = -1,
                message = "钉钉部门同步未启用：请将数据字典明细 enabled 的值设为 1。"
            });

        var dept = LoadDepartmentRow(deptId);
        if (dept == null)
            return BadRequest(new { code = -1, message = "未找到该部门记录。" });
        if (string.IsNullOrWhiteSpace(dept.ParentId))
            return BadRequest(new { code = -1, message = "根部门无上级，无法同步到钉钉（与老系统逻辑一致）。" });

        var parentDdId = string.IsNullOrWhiteSpace(dept.ParentDingtalkId)
            ? ResolveParentDingtalkId(deptId)
            : dept.ParentDingtalkId!.Trim();

        if (string.IsNullOrWhiteSpace(parentDdId))
            return BadRequest(new
            {
                code = -1,
                message = "父级部门未维护钉钉部门 ID（dingtalk_id），请先同步上级部门到钉钉。"
            });

        var tokenJo = await _oapi.GetTokenAsync(st.CorpId!, st.CorpSecret!, ct).ConfigureAwait(false);
        if (!DingTalkOapiDepartmentService.IsOk(tokenJo))
            return BadRequest(new
            {
                code = -1,
                message = "获取钉钉 access_token 失败：" + DingTalkOapiDepartmentService.ErrString(tokenJo)
            });
        var token = tokenJo["access_token"]?.ToString();
        if (string.IsNullOrEmpty(token))
            return BadRequest(new { code = -1, message = "钉钉未返回 access_token，请检查 corp_id / corp_secret。" });

        try
        {
            if (dept.IsStop == true)
                return await SyncStoppedDepartmentAsync(dept, token, ct).ConfigureAwait(false);
            if (string.IsNullOrWhiteSpace(dept.DingtalkId))
                return await CreateDepartmentOnDingTalkAsync(dept, parentDdId, token, ct).ConfigureAwait(false);
            return await UpdateDepartmentOnDingTalkAsync(dept, parentDdId, token, ct).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = ex.Message });
        }
    }

    private sealed class DepartmentRow
    {
        public string? DepartmentId { get; set; }
        public string? Name { get; set; }
        public string? DingtalkId { get; set; }
        public string? ParentId { get; set; }
        public string? ParentDingtalkId { get; set; }
        public int? Sort { get; set; }
        public bool? IsStop { get; set; }
    }

    private DepartmentRow? LoadDepartmentRow(string departmentId)
    {
        var rows = _db.Ado.SqlQuery<DepartmentRow>(
            """
            SELECT
              CAST(d.id AS varchar(50)) AS DepartmentId,
              LTRIM(RTRIM(d.name)) AS Name,
              LTRIM(RTRIM(d.dingtalk_id)) AS DingtalkId,
              CAST(d.parent_id AS varchar(50)) AS ParentId,
              LTRIM(RTRIM(p.dingtalk_id)) AS ParentDingtalkId,
              d.sort AS Sort,
              d.is_stop AS IsStop
            FROM dbo.t_base_department AS d WITH (NOLOCK)
            LEFT JOIN dbo.t_base_department AS p WITH (NOLOCK) ON d.parent_id = p.id
            WHERE d.id = @id
            """,
            new SugarParameter("@id", departmentId));
        return rows.FirstOrDefault();
    }

    private string? ResolveParentDingtalkId(string departmentId)
    {
        var rows = _db.Ado.SqlQuery<ParentDdRow>(
            """
            SELECT LTRIM(RTRIM(p.dingtalk_id)) AS DdId
            FROM dbo.t_base_department AS c WITH (NOLOCK)
            INNER JOIN dbo.t_base_department AS p WITH (NOLOCK) ON c.parent_id = p.id
            WHERE c.id = @id
            """,
            new SugarParameter("@id", departmentId));
        return rows.FirstOrDefault()?.DdId;
    }

    private sealed class ParentDdRow
    {
        public string? DdId { get; set; }
    }

    private static string ErrCode(JObject jo) => jo["errcode"]?.ToString() ?? "";

    private void UpdateDepartmentDingtalkId(string departmentId, string? dingtalkId)
    {
        _db.Ado.ExecuteCommand(
            "UPDATE dbo.t_base_department SET dingtalk_id = @dd WHERE id = @id",
            new SugarParameter("@dd", dingtalkId == null ? DBNull.Value : dingtalkId),
            new SugarParameter("@id", departmentId));
    }

    private async Task<IActionResult> SyncStoppedDepartmentAsync(DepartmentRow d, string token, CancellationToken ct)
    {
        var ddid = d.DingtalkId?.Trim();
        if (string.IsNullOrEmpty(ddid))
            return Ok(new { code = 0, message = "部门已停用且本地无钉钉部门 ID，无需调用删除接口。" });

        if (!long.TryParse(ddid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var dingLong))
            return BadRequest(new { code = -1, message = "本部门 dingtalk_id 格式无效，无法删除钉钉部门。" });

        var del = await _oapi.DeleteDepartmentAsync(token, dingLong, ct).ConfigureAwait(false);
        var code = ErrCode(del);
        if (code != "0" && code != "60003")
            return BadRequest(new { code = -1, message = "钉钉删除部门失败：" + DingTalkOapiDepartmentService.ErrString(del) });

        UpdateDepartmentDingtalkId(d.DepartmentId!, null);
        return Ok(new { code = 0, message = "已与钉钉同步：停用部门已从钉钉删除（或远端已不存在）。" });
    }

    private async Task<string?> FindExistingChildDeptIdByNameAsync(
        string token,
        string parentDdId,
        string name,
        CancellationToken ct)
    {
        var listObj = await _oapi.GetDepartmentListAsync(token, parentDdId, false, ct).ConfigureAwait(false);
        if (!DingTalkOapiDepartmentService.IsOk(listObj))
            return null;
        var dep = listObj["department"];
        if (dep == null || dep.Type == JTokenType.Null)
            return null;

        IEnumerable<JToken> items = dep.Type == JTokenType.Array ? dep : new JArray(dep);
        foreach (var item in items)
        {
            if (item is not JObject jo)
                continue;
            if (string.Equals(jo["name"]?.ToString(), name, StringComparison.Ordinal))
                return jo["id"]?.ToString();
        }

        return null;
    }

    private async Task<IActionResult> CreateDepartmentOnDingTalkAsync(
        DepartmentRow d,
        string parentDdId,
        string token,
        CancellationToken ct)
    {
        var name = d.Name?.Trim();
        if (string.IsNullOrEmpty(name))
            return BadRequest(new { code = -1, message = "部门名称为空，无法同步到钉钉。" });

        var orderStr = d.Sort?.ToString(CultureInfo.InvariantCulture) ?? "0";
        var createRes = await _oapi.CreateDepartmentAsync(token, name, parentDdId, orderStr, ct).ConfigureAwait(false);
        var code = ErrCode(createRes);
        string? ddid;
        if (code == "0")
            ddid = createRes["id"]?.ToString();
        else if (code == "60008")
        {
            ddid = await FindExistingChildDeptIdByNameAsync(token, parentDdId, name, ct).ConfigureAwait(false);
            if (string.IsNullOrEmpty(ddid))
                return BadRequest(new
                {
                    code = -1,
                    message = "钉钉返回部门重名(60008)，但在父部门下未找到同名部门。详情：" + createRes
                });
        }
        else if (code == "60004")
        {
            return BadRequest(new
            {
                code = -1,
                message =
                    "钉钉提示父部门不存在(60004)：当前使用的上级钉钉部门 id 在钉钉侧无效（上级可能已在钉钉删除，或本系统里上级 dingtalk_id 过期/填错）。请从组织架构根节点开始，在「部门管理」里先对上级部门执行「同步到钉钉」，再同步本级；必要时在上级部门清空 dingtalk_id 后重新同步上级。"
            });
        }
        else
            return BadRequest(new { code = -1, message = "钉钉创建部门失败：" + DingTalkOapiDepartmentService.ErrString(createRes) });

        if (string.IsNullOrEmpty(ddid))
            return BadRequest(new { code = -1, message = "钉钉创建部门未返回 id。" });

        UpdateDepartmentDingtalkId(d.DepartmentId!, ddid);

        return Ok(new { code = 0, message = "已与钉钉完成部门同步（新建）。当前仅同步部门架构，不含部门主管。" });
    }

    private async Task<IActionResult> UpdateDepartmentOnDingTalkAsync(
        DepartmentRow d,
        string parentDdId,
        string token,
        CancellationToken ct)
    {
        var ddid = d.DingtalkId!.Trim();
        if (!long.TryParse(ddid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var dingLong))
            return BadRequest(new { code = -1, message = "本部门 dingtalk_id 无效，无法更新钉钉部门。" });

        var name = d.Name?.Trim();
        if (string.IsNullOrEmpty(name))
            return BadRequest(new { code = -1, message = "部门名称为空，无法同步到钉钉。" });

        var orderStr = d.Sort?.ToString(CultureInfo.InvariantCulture) ?? "0";
        var upd = await _oapi.UpdateDepartmentAsync(token, dingLong, name, parentDdId, orderStr, null, ct)
            .ConfigureAwait(false);
        if (!DingTalkOapiDepartmentService.IsOk(upd))
        {
            // 本地仍保存 dingtalk_id，但钉钉侧已删除/不存在 → 按新建重建并写回新 id
            if (ErrCode(upd) == "60003")
            {
                UpdateDepartmentDingtalkId(d.DepartmentId!, null);
                d.DingtalkId = null;
                return await CreateDepartmentOnDingTalkAsync(d, parentDdId, token, ct).ConfigureAwait(false);
            }

            return BadRequest(new { code = -1, message = "钉钉更新部门失败：" + DingTalkOapiDepartmentService.ErrString(upd) });
        }

        return Ok(new { code = 0, message = "已与钉钉完成部门同步（更新）。当前仅同步部门架构，不含部门主管。" });
    }

    private sealed class ConfigState
    {
        public Guid? DictionaryId { get; set; }
        public bool Enabled { get; set; }
        public string? CorpId { get; set; }
        public string? CorpSecret { get; set; }
        public List<string> MissingKeys { get; } = new();
    }

    private ConfigState LoadConfig()
    {
        var st = new ConfigState();
        var idObj = _db.Ado.GetScalar(
            "SELECT id FROM dbo.vben_t_base_dictionary WITH (NOLOCK) WHERE code = @c",
            new SugarParameter("@c", DictCode));
        if (idObj == null || idObj == DBNull.Value)
            return st;

        st.DictionaryId = Guid.Parse(idObj.ToString()!, CultureInfo.InvariantCulture);

        var rows = _db.Ado.SqlQuery<DetailRow>(
            """
            SELECT LTRIM(RTRIM(name)) AS Name, LTRIM(RTRIM(value)) AS Value
            FROM dbo.vben_t_base_dictionary_detail WITH (NOLOCK)
            WHERE dictionary_id = @did AND (is_stop IS NULL OR is_stop <> '1')
            """,
            new SugarParameter("@did", st.DictionaryId.Value));

        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in rows)
        {
            if (!string.IsNullOrEmpty(r.Name))
                map[r.Name!] = r.Value ?? "";
        }

        if (!map.TryGetValue("enabled", out var en))
            st.MissingKeys.Add("enabled");
        else
            st.Enabled = en.Trim() == "1";

        if (!map.TryGetValue("corp_id", out var cid) || string.IsNullOrWhiteSpace(cid))
            st.MissingKeys.Add("corp_id");
        else
            st.CorpId = cid.Trim();

        if (!map.TryGetValue("corp_secret", out var csec) || string.IsNullOrWhiteSpace(csec))
            st.MissingKeys.Add("corp_secret");
        else
            st.CorpSecret = csec.Trim();

        return st;
    }

    private sealed class DetailRow
    {
        public string? Name { get; set; }
        public string? Value { get; set; }
    }
}
