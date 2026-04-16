using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace StoneApi.Services;

/// <summary>
/// 钉钉 oapi 员工接口（按工号 userid 做 upsert）。
/// </summary>
public sealed class DingTalkOapiUserService
{
    private readonly HttpClient _http;

    public DingTalkOapiUserService(HttpClient http)
    {
        _http = http;
        _http.Timeout = TimeSpan.FromSeconds(60);
    }

    public async Task<JObject> GetUserAsync(string accessToken, string userId, CancellationToken ct = default)
    {
        var url =
            $"https://oapi.dingtalk.com/user/get?access_token={Uri.EscapeDataString(accessToken)}&userid={Uri.EscapeDataString(userId)}";
        var json = await _http.GetStringAsync(url, ct).ConfigureAwait(false);
        return JObject.Parse(json);
    }

    public async Task<JObject> CreateUserAsync(
        string accessToken,
        string userId,
        string name,
        string mobile,
        long deptId,
        CancellationToken ct = default)
    {
        var body = new JObject
        {
            ["userid"] = userId,
            ["name"] = name,
            ["mobile"] = mobile,
            ["department"] = new JArray(deptId),
        };
        using var content = new StringContent(
            body.ToString(Formatting.None),
            Encoding.UTF8,
            "application/json");
        var url = $"https://oapi.dingtalk.com/user/create?access_token={Uri.EscapeDataString(accessToken)}";
        using var resp = await _http.PostAsync(url, content, ct).ConfigureAwait(false);
        var json = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return JObject.Parse(json);
    }

    public async Task<JObject> UpdateUserAsync(
        string accessToken,
        string userId,
        string name,
        string mobile,
        long deptId,
        CancellationToken ct = default)
    {
        var body = new JObject
        {
            ["userid"] = userId,
            ["name"] = name,
            ["mobile"] = mobile,
            ["department"] = new JArray(deptId),
        };
        using var content = new StringContent(
            body.ToString(Formatting.None),
            Encoding.UTF8,
            "application/json");
        var url = $"https://oapi.dingtalk.com/user/update?access_token={Uri.EscapeDataString(accessToken)}";
        using var resp = await _http.PostAsync(url, content, ct).ConfigureAwait(false);
        var json = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return JObject.Parse(json);
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

