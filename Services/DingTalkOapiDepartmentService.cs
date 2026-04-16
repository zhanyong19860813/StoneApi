using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace StoneApi.Services;

/// <summary>
/// 钉钉开放平台 oapi 部门接口（与老系统 DingTalkAPI 中部门相关方法、SyncHrmToDingTalkJob 调用方式一致，改为 HttpClient 实现，不依赖 DingTalk.Api SDK）。
/// </summary>
public sealed class DingTalkOapiDepartmentService
{
    private readonly HttpClient _http;

    public DingTalkOapiDepartmentService(HttpClient http)
    {
        _http = http;
        _http.Timeout = TimeSpan.FromSeconds(60);
    }

    /// <summary>
    /// 获取 access_token。钉钉文档现为 appkey+appsecret；旧文档为 corpid+corpsecret（corpid 为企业 CorpId）。
    /// 两种参数名会依次尝试，避免填了 Client ID 却仍走 corpid 导致 40089。
    /// </summary>
    public async Task<JObject> GetTokenAsync(string corpIdOrAppKey, string corpSecretOrAppSecret, CancellationToken ct = default)
    {
        var id = corpIdOrAppKey.Trim();
        var secret = corpSecretOrAppSecret.Trim();

        // 1) 新版（官方）：https://oapi.dingtalk.com/gettoken?appkey=&appsecret=
        var urlApp = $"https://oapi.dingtalk.com/gettoken?appkey={Uri.EscapeDataString(id)}&appsecret={Uri.EscapeDataString(secret)}";
        var bodyApp = await _http.GetStringAsync(urlApp, ct).ConfigureAwait(false);
        var joApp = JObject.Parse(bodyApp);
        if (IsOk(joApp))
            return joApp;

        // 2) 旧版：corpid=企业 CorpId & corpsecret=应用 AppSecret
        var urlCorp =
            $"https://oapi.dingtalk.com/gettoken?corpid={Uri.EscapeDataString(id)}&corpsecret={Uri.EscapeDataString(secret)}";
        var bodyCorp = await _http.GetStringAsync(urlCorp, ct).ConfigureAwait(false);
        return JObject.Parse(bodyCorp);
    }

    public async Task<JObject> CreateDepartmentAsync(
        string accessToken,
        string name,
        string parentDingDeptId,
        string order,
        CancellationToken ct = default)
    {
        // 钉钉现要求 POST body 为 application/json，表单会返回 43009
        var body = new JObject
        {
            ["name"] = name,
            ["parentid"] = parentDingDeptId,
            ["order"] = string.IsNullOrWhiteSpace(order) ? "0" : order,
        };
        using var content = new StringContent(
            body.ToString(Formatting.None),
            Encoding.UTF8,
            "application/json");
        var url = $"https://oapi.dingtalk.com/department/create?access_token={Uri.EscapeDataString(accessToken)}";
        using var resp = await _http.PostAsync(url, content, ct).ConfigureAwait(false);
        var json = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return JObject.Parse(json);
    }

    public async Task<JObject> UpdateDepartmentAsync(
        string accessToken,
        long dingDeptId,
        string? name,
        string? parentDingDeptId,
        string? order,
        string? deptManagerUseridList,
        CancellationToken ct = default)
    {
        var body = new JObject { ["id"] = dingDeptId };
        if (name != null) body["name"] = name;
        if (parentDingDeptId != null) body["parentid"] = parentDingDeptId;
        if (order != null) body["order"] = order;
        if (deptManagerUseridList != null) body["deptManagerUseridList"] = deptManagerUseridList;

        using var content = new StringContent(
            body.ToString(Formatting.None),
            Encoding.UTF8,
            "application/json");
        var url = $"https://oapi.dingtalk.com/department/update?access_token={Uri.EscapeDataString(accessToken)}";
        using var resp = await _http.PostAsync(url, content, ct).ConfigureAwait(false);
        var json = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return JObject.Parse(json);
    }

    public async Task<JObject> DeleteDepartmentAsync(string accessToken, long dingDeptId, CancellationToken ct = default)
    {
        var url =
            $"https://oapi.dingtalk.com/department/delete?access_token={Uri.EscapeDataString(accessToken)}&id={dingDeptId}";
        var json = await _http.GetStringAsync(url, ct).ConfigureAwait(false);
        return JObject.Parse(json);
    }

    public async Task<JObject> GetDepartmentListAsync(
        string accessToken,
        string parentDingDeptId,
        bool fetchChild = false,
        CancellationToken ct = default)
    {
        var fetch = fetchChild ? "true" : "false";
        var url =
            $"https://oapi.dingtalk.com/department/list?access_token={Uri.EscapeDataString(accessToken)}&id={Uri.EscapeDataString(parentDingDeptId)}&fetch_child={fetch}";
        var json = await _http.GetStringAsync(url, ct).ConfigureAwait(false);
        return JObject.Parse(json);
    }

    /// <summary>
    /// 解析 <c>department/list</c> 返回的 <c>department</c> 数组（单条时也可能是对象）。
    /// </summary>
    public static List<(string Id, string Name, string? ParentId)> ParseDepartmentList(JObject listObj)
    {
        var list = new List<(string Id, string Name, string? ParentId)>();
        if (!IsOk(listObj))
            return list;
        var dep = listObj["department"];
        if (dep == null || dep.Type == JTokenType.Null)
            return list;
        var tokens = dep.Type == JTokenType.Array ? dep : new JArray(dep);
        foreach (var t in tokens)
        {
            if (t is not JObject jo)
                continue;
            var id = jo["id"]?.ToString();
            if (string.IsNullOrEmpty(id))
                continue;
            list.Add((id, jo["name"]?.ToString() ?? "", jo["parentid"]?.ToString()));
        }

        return list;
    }

    public static bool IsOk(JObject jo)
    {
        var err = jo["errcode"];
        if (err == null) return false;
        return err.Type == JTokenType.Integer ? err.Value<int>() == 0 : err.ToString() == "0";
    }

    public static string ErrString(JObject jo)
    {
        var c = jo["errcode"]?.ToString() ?? "";
        var m = jo["errmsg"]?.ToString() ?? "";
        return string.IsNullOrEmpty(m) ? c : $"{c}: {m}";
    }
}
