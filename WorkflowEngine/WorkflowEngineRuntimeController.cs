using System.Security.Claims;
using System.Text.Json;
using System.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SqlSugar;

namespace StoneApi.WorkflowEngine;

[ApiController]
[Authorize]
[Route("api/workflow-engine/runtime")]
public class WorkflowEngineRuntimeController : ControllerBase
{
    private readonly SqlSugarClient _db;
    private readonly IConfiguration _configuration;

    public WorkflowEngineRuntimeController(SqlSugarClient db, IConfiguration configuration)
    {
        _db = db;
        _configuration = configuration;
    }

    private string CurrentUserId() =>
        User?.FindFirst("UserId")?.Value
        ?? User?.FindFirst("employee_id")?.Value
        ?? User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User?.Identity?.Name
        ?? "";

    private bool IsWorkflowAdmin()
    {
        if (User?.Identity?.IsAuthenticated != true) return false;
        if (User.IsInRole("WorkflowAdmin") || User.IsInRole("Admin") || User.IsInRole("SuperAdmin"))
            return true;
        var roleClaims = User.Claims
            .Where(c =>
                c.Type == ClaimTypes.Role
                || c.Type.Equals("role", StringComparison.OrdinalIgnoreCase)
                || c.Type.Equals("roles", StringComparison.OrdinalIgnoreCase)
                || c.Type.Equals("RoleCode", StringComparison.OrdinalIgnoreCase))
            .Select(c => c.Value ?? "")
            .Where(v => v.Length > 0);
        foreach (var raw in roleClaims)
        {
            var tokens = raw.Split(new[] { ',', ';', ' ' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var token in tokens)
            {
                var t = token.Trim();
                if (t.Equals("WorkflowAdmin", StringComparison.OrdinalIgnoreCase)
                    || t.Equals("Admin", StringComparison.OrdinalIgnoreCase)
                    || t.Equals("SuperAdmin", StringComparison.OrdinalIgnoreCase)
                    || t.Equals("Administrator", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
        }
        return false;
    }

    private bool IsRuntimeMockAllowed()
    {
        var allowByConfig = _configuration.GetValue<bool?>("WorkflowEngine:AllowRuntimeMockUser") == true
            || string.Equals(_configuration["WorkflowEngine:AllowRuntimeMockUser"], "true", StringComparison.OrdinalIgnoreCase);
        return allowByConfig && IsWorkflowAdmin();
    }

    /// <summary>
    /// 测试用：当 WorkflowEngine:AllowRuntimeMockUser=true 且请求头 X-Workflow-Mock-User-Id 非空时，
    /// 「我的待办 / 办理任务」按该工号识别身份（仍需有效 JWT）。生产环境请关闭。
    /// 注意：若 JWT 中无 UserId/employee_id 等声明导致 CurrentUserId 为空，旧逻辑会忽略模拟头；
    /// 此处在已认证且允许模拟时仍采用请求头工号，否则测试页「我的待办」会一直为空。
    /// </summary>
    private string RuntimeActorUserId()
    {
        var loginUid = CurrentUserId();
        if (IsRuntimeMockAllowed()
            && User?.Identity?.IsAuthenticated == true
            && Request.Headers.TryGetValue("X-Workflow-Mock-User-Id", out var mock))
        {
            var m = mock.ToString().Trim();
            if (!string.IsNullOrWhiteSpace(m))
                return m;
        }

        return loginUid;
    }

    /// <summary>
    /// 将“用户ID/工号/用户名”等标识统一解析为 t_base_employee.id（person_key=employee_id）。
    /// <paramref name="activeOnly"/>：为 true 时仅匹配在职（<c>t_base_employee.status = 0</c>）。
    /// </summary>
    private string ResolveEmployeeIdOrEmpty(string rawIdentity, bool activeOnly = false)
    {
        var k = (rawIdentity ?? "").Trim();
        if (k.Length == 0) return "";
        var activeEmp = activeOnly ? " AND ISNULL(e.status, 0) = 0 " : "";
        try
        {
            var dtEmp = _db.Ado.GetDataTable(
                $"""
                SELECT TOP 1
                  CAST(e.id AS varchar(50)) AS emp_id
                FROM dbo.t_base_employee e WITH (NOLOCK)
                WHERE (LTRIM(RTRIM(CAST(e.id AS varchar(50)))) = LTRIM(RTRIM(@k))
                   OR LTRIM(RTRIM(ISNULL(e.code, ''))) = LTRIM(RTRIM(@k))
                   OR LTRIM(RTRIM(ISNULL(e.username, ''))) = LTRIM(RTRIM(@k)))
                   {activeEmp}
                """,
                new SugarParameter("@k", k)
            );
            if (dtEmp.Rows.Count > 0)
            {
                var v = dtEmp.Rows[0]["emp_id"]?.ToString()?.Trim() ?? "";
                if (!string.IsNullOrWhiteSpace(v)) return v;
            }
        }
        catch
        {
            // ignore and fallback
        }

        var activeJoin = activeOnly ? " AND ISNULL(e.status, 0) = 0 " : "";
        try
        {
            var dtByUser = _db.Ado.GetDataTable(
                $"""
                SELECT TOP 1
                  CAST(e.id AS varchar(50)) AS emp_id
                FROM dbo.vben_t_sys_user u WITH (NOLOCK)
                LEFT JOIN dbo.t_base_employee e WITH (NOLOCK)
                  ON (
                       LTRIM(RTRIM(CAST(e.id AS varchar(50)))) = LTRIM(RTRIM(CAST(u.id AS varchar(50))))
                    OR
                       LTRIM(RTRIM(ISNULL(e.code,''))) = LTRIM(RTRIM(ISNULL(u.employee_id,'')))
                    OR (
                         u.username IS NOT NULL
                     AND LTRIM(RTRIM(ISNULL(e.username,''))) = LTRIM(RTRIM(ISNULL(u.username,'')))
                    )
                  )
                WHERE (LTRIM(RTRIM(CAST(u.id AS varchar(50)))) = LTRIM(RTRIM(@k))
                   OR LTRIM(RTRIM(ISNULL(u.employee_id,''))) = LTRIM(RTRIM(@k))
                   OR LTRIM(RTRIM(ISNULL(u.username,''))) = LTRIM(RTRIM(@k)))
                   AND e.id IS NOT NULL
                   {activeJoin}
                """,
                new SugarParameter("@k", k)
            );
            if (dtByUser.Rows.Count > 0)
            {
                var v = dtByUser.Rows[0]["emp_id"]?.ToString()?.Trim() ?? "";
                if (!string.IsNullOrWhiteSpace(v)) return v;
            }
        }
        catch
        {
            // ignore and fallback
        }

        return "";
    }

    private string? GetEmployeeDisplayNameOrNull(string empId)
    {
        var id = (empId ?? "").Trim();
        if (id.Length == 0) return null;
        try
        {
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1 LTRIM(RTRIM(ISNULL(name,''))) AS n
                FROM dbo.t_base_employee WITH (NOLOCK)
                WHERE LTRIM(RTRIM(CAST(id AS varchar(50)))) = LTRIM(RTRIM(@id))
                """,
                new SugarParameter("@id", id));
            if (dt.Rows.Count == 0) return null;
            var n = dt.Rows[0]["n"]?.ToString()?.Trim();
            return string.IsNullOrEmpty(n) ? null : n;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>发起人部门：优先实例 starter_dept_id，否则查员工表 dept_id。</summary>
    private string? GetStarterDepartmentId(JObject ctx, string starterEmpId)
    {
        var fromCtx = (ctx["starterDeptId"]?.ToString() ?? "").Trim();
        if (fromCtx.Length > 0) return fromCtx;
        var emp = (starterEmpId ?? "").Trim();
        if (emp.Length == 0) return null;
        try
        {
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1 CAST(dept_id AS varchar(50)) AS d
                FROM dbo.t_base_employee WITH (NOLOCK)
                WHERE LTRIM(RTRIM(CAST(id AS varchar(50)))) = LTRIM(RTRIM(@e))
                  AND ISNULL(status, 0) = 0
                """,
                new SugarParameter("@e", emp));
            if (dt.Rows.Count == 0) return null;
            var d = dt.Rows[0]["d"]?.ToString()?.Trim();
            return string.IsNullOrEmpty(d) ? null : d;
        }
        catch
        {
            return null;
        }
    }

    private string? TryGetParentDepartmentId(string deptId)
    {
        if (!Guid.TryParse((deptId ?? "").Trim(), out var gid)) return null;
        try
        {
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1 CAST(parent_id AS varchar(50)) AS p
                FROM dbo.t_base_department WITH (NOLOCK)
                WHERE id = @id
                """,
                new SugarParameter("@id", gid));
            if (dt.Rows.Count == 0) return null;
            var p = dt.Rows[0]["p"]?.ToString()?.Trim();
            return string.IsNullOrEmpty(p) ? null : p;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// 从部门行解析主管/代管：优先 firstmanagercode → firstmanager 姓名 → secondmanagercode → secondmanager。
    /// </summary>
    private string? TryResolveManagerEmpIdFromDeptRow(string deptId)
    {
        if (!Guid.TryParse((deptId ?? "").Trim(), out var gid)) return null;
        try
        {
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1
                  LTRIM(RTRIM(ISNULL(firstmanagercode,''))) AS fc1,
                  LTRIM(RTRIM(ISNULL(secondmanagercode,''))) AS fc2,
                  LTRIM(RTRIM(ISNULL(firstmanager,''))) AS n1,
                  LTRIM(RTRIM(ISNULL(secondmanager,''))) AS n2
                FROM dbo.t_base_department WITH (NOLOCK)
                WHERE id = @id
                """,
                new SugarParameter("@id", gid));
            if (dt.Rows.Count == 0) return null;
            var r = dt.Rows[0];
            var fc1 = r["fc1"]?.ToString()?.Trim() ?? "";
            var fc2 = r["fc2"]?.ToString()?.Trim() ?? "";
            var n1 = r["n1"]?.ToString()?.Trim() ?? "";
            var n2 = r["n2"]?.ToString()?.Trim() ?? "";

            if (fc1.Length > 0)
            {
                var id = ResolveEmployeeIdOrEmpty(fc1, activeOnly: true);
                if (id.Length > 0) return id;
            }
            if (n1.Length > 0)
            {
                var id = TryResolveEmployeeIdByNameExact(n1);
                if (!string.IsNullOrEmpty(id)) return id;
            }
            if (fc2.Length > 0)
            {
                var id = ResolveEmployeeIdOrEmpty(fc2, activeOnly: true);
                if (id.Length > 0) return id;
            }
            if (n2.Length > 0) return TryResolveEmployeeIdByNameExact(n2);
        }
        catch
        {
            // ignore
        }

        return null;
    }

    private string? TryResolveEmployeeIdByNameExact(string name)
    {
        var n = (name ?? "").Trim();
        if (n.Length == 0) return null;
        try
        {
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1 CAST(id AS varchar(50)) AS id
                FROM dbo.t_base_employee WITH (NOLOCK)
                WHERE LTRIM(RTRIM(ISNULL(name,''))) = LTRIM(RTRIM(@n))
                  AND ISNULL(status, 0) = 0
                """,
                new SugarParameter("@n", n));
            if (dt.Rows.Count == 0) return null;
            return dt.Rows[0]["id"]?.ToString()?.Trim();
        }
        catch
        {
            return null;
        }
    }

    /// <summary>直接领导 / 部门主管：仅发起人所在部门。</summary>
    private string? TryResolveDirectDeptLeader(string starterDeptId) =>
        TryResolveManagerEmpIdFromDeptRow(starterDeptId);

    /// <summary>间接上级：从上级部门链逐级找第一个能解析出主管的部门。</summary>
    private string? TryResolveIndirectLeader(string starterDeptId)
    {
        var current = TryGetParentDepartmentId(starterDeptId);
        var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var depth = 0;
        while (!string.IsNullOrEmpty(current) && depth++ < 64)
        {
            if (!visited.Add(current)) break;
            var emp = TryResolveManagerEmpIdFromDeptRow(current);
            if (!string.IsNullOrEmpty(emp)) return emp;
            current = TryGetParentDepartmentId(current) ?? "";
        }
        return null;
    }

    /// <param name="expr">如 $resolve.directLeader</param>
    private (string? EmpId, string? Error) ResolveAssigneeExpression(
        string expr,
        JObject form,
        JObject ctx)
    {
        var e = (expr ?? "").Trim();
        var starter = (ctx["starterUserId"]?.ToString() ?? "").Trim();
        switch (e)
        {
            case "$resolve.initiatorSelf":
                if (starter.Length == 0) return (null, "缺少发起人标识");
                var self = ResolveEmployeeIdOrEmpty(starter, activeOnly: true);
                if (self.Length == 0) return (null, "发起人未匹配到在职员工");
                return (self, null);
            case "$resolve.directLeader":
            case "$resolve.deptHead":
            {
                var deptId = GetStarterDepartmentId(ctx, starter);
                if (string.IsNullOrEmpty(deptId))
                    return (null, "无法解析发起人部门（请传 starterDeptId 或维护员工 dept_id）");
                var leader = TryResolveDirectDeptLeader(deptId);
                return leader == null
                    ? (null, "本部门未配置主管/代管人或无法匹配到在职员工")
                    : (leader, null);
            }
            case "$resolve.indirectLeader":
            {
                var deptId = GetStarterDepartmentId(ctx, starter);
                if (string.IsNullOrEmpty(deptId))
                    return (null, "无法解析发起人部门（请传 starterDeptId 或维护员工 dept_id）");
                var leader = TryResolveIndirectLeader(deptId);
                return leader == null
                    ? (null, "上级部门链未找到可匹配的主管")
                    : (leader, null);
            }
            default:
                return (null, $"未知审批表达式：{e}");
        }
    }

    private static string NewBizNo(string prefix) =>
        $"{prefix}{DateTime.Now:yyyyMMddHHmmssfff}{Random.Shared.Next(100, 999)}";

    public class RuntimeStartRequest
    {
        public string? ProcessCode { get; set; }
        public Guid? ProcessDefId { get; set; }
        public string? BusinessKey { get; set; }
        public string? Title { get; set; }
        public string? StarterDeptId { get; set; }
        /** 调试用：模拟发起人（不传则使用当前登录人） */
        public string? MockStarterUserId { get; set; }
        /** 调试展示用：模拟发起人姓名 */
        public string? MockStarterName { get; set; }
        public JsonElement? MainForm { get; set; }
        public JsonElement? TabsData { get; set; }
    }

    [HttpPost("start")]
    public IActionResult Start([FromBody] RuntimeStartRequest req)
    {
        var loginUid = CurrentUserId();
        if (string.IsNullOrWhiteSpace(loginUid))
            return Ok(new { code = 401, message = "未获取到登录人" });
        if (!string.IsNullOrWhiteSpace(req.MockStarterUserId) && !IsRuntimeMockAllowed())
            return Ok(new { code = 403, message = "无权限使用模拟发起人能力" });
        var starterIdentity = string.IsNullOrWhiteSpace(req.MockStarterUserId)
            ? loginUid
            : req.MockStarterUserId.Trim();
        var starterUid = ResolveEmployeeIdOrEmpty(starterIdentity);
        if (string.IsNullOrWhiteSpace(starterUid))
            return Ok(new { code = 400, message = $"发起人标识未映射到员工ID：{starterIdentity}" });
        var starterName = string.IsNullOrWhiteSpace(req.MockStarterName)
            ? starterIdentity
            : req.MockStarterName.Trim();

        var def = ResolveProcessDef(req.ProcessDefId, req.ProcessCode);
        if (def == null) return Ok(new { code = 404, message = "流程定义不存在" });
        if (!def.is_valid) return Ok(new { code = 400, message = "流程已标记为无效，无法发起" });

        var ver = ResolvePublishedVersion(def.id);
        if (ver == null) return Ok(new { code = 400, message = "流程尚未发布版本" });

        if (!TryParseGraph(ver.definition_json, out var graph, out var parseErr))
            return Ok(new { code = 400, message = $"definition_json 解析失败：{parseErr}" });

        var startNode = graph.Nodes.FirstOrDefault(n => n.BizType == "start")
            ?? graph.Nodes.FirstOrDefault();
        if (startNode == null)
            return Ok(new { code = 400, message = "流程图缺少节点" });

        var form = ToJObjectOrEmpty(req.MainForm);
        var tabsData = ToJObjectOrNull(req.TabsData);
        var ctx = new JObject
        {
            ["starterUserId"] = starterUid,
            ["starterDeptId"] = req.StarterDeptId ?? "",
        };
        var now = DateTime.Now;
        var instanceId = Guid.NewGuid();
        var instanceNo = NewBizNo("WFI");
        var title = string.IsNullOrWhiteSpace(req.Title) ? def.process_name : req.Title!.Trim();
        var compatProcessCode = !string.IsNullOrWhiteSpace(def.process_code)
            ? def.process_code.Trim()
            : (!string.IsNullOrWhiteSpace(req.ProcessCode) ? req.ProcessCode.Trim() : $"DEF-{def.id:N}");
        var compatProcessName = !string.IsNullOrWhiteSpace(def.process_name)
            ? def.process_name.Trim()
            : (!string.IsNullOrWhiteSpace(title) ? title : compatProcessCode);

        var nextNodes = ResolveNextActionableNodes(graph, startNode.Id, form, ctx);
        var nextRunnable = nextNodes.Where(x => x.BizType != "end").ToList();
        var currentNodeIds = string.Join(",",
            nextRunnable.Select(x => x.Id).Distinct());
        var isCompletedDirectly = nextRunnable.Count == 0;

        var (taskPlans, taskPlanErr) = BuildNewTaskPlansForNodes(nextRunnable, starterUid, form, ctx);
        if (!string.IsNullOrEmpty(taskPlanErr))
            return Ok(new { code = 400, message = taskPlanErr });

        _db.Ado.BeginTran();
        try
        {
            InsertWfInstanceCompat(
                instanceId: instanceId,
                instanceNo: instanceNo,
                processDefId: def.id,
                processDefVerId: ver.id,
                processCode: compatProcessCode,
                processName: compatProcessName,
                versionNo: ver.version_no,
                businessKey: req.BusinessKey?.Trim(),
                title: title,
                starterEmpId: starterUid,
                starterDeptId: req.StarterDeptId?.Trim(),
                status: isCompletedDirectly ? (byte)1 : (byte)0,
                currentNodeIds: currentNodeIds,
                startedAt: now,
                endedAt: isCompletedDirectly ? now : null,
                createdAt: now,
                updatedAt: now
            );

            _db.Insertable(new wf_instance_data
            {
                id = Guid.NewGuid(),
                instance_id = instanceId,
                node_id = startNode.Id,
                form_code = null,
                main_form_json = form.HasValues ? form.ToString(Formatting.None) : null,
                tabs_data_json = tabsData?.HasValues == true ? tabsData.ToString(Formatting.None) : null,
                snapshot_at = now,
                operator_user_id = starterUid
            }).ExecuteCommand();

            _db.Insertable(new wf_action_log
            {
                id = Guid.NewGuid(),
                instance_id = instanceId,
                task_id = null,
                node_id = startNode.Id,
                action_type = "submit",
                action_result = isCompletedDirectly ? "completed" : "submitted",
                operator_user_id = starterUid,
                operator_name = starterName,
                comment = "发起流程",
                payload_json = null,
                action_at = now,
                created_at = now
            }).ExecuteCommand();

            foreach (var plan in taskPlans)
            {
                _db.Insertable(new wf_task
                {
                    id = Guid.NewGuid(),
                    task_no = NewBizNo("WFT"),
                    instance_id = instanceId,
                    node_id = plan.NodeId,
                    node_name = plan.NodeName,
                    assignee_user_id = plan.AssigneeUserId,
                    assignee_name = plan.AssigneeName,
                    task_type = plan.TaskType,
                    status = 0,
                    sign_mode = plan.SignMode,
                    batch_no = plan.BatchNo,
                    source_task_id = null,
                    tenant_id = null,
                    received_at = now,
                    completed_at = null,
                    due_at = null,
                    created_at = now,
                    updated_at = now
                }).ExecuteCommand();
            }

            _db.Ado.CommitTran();
        }
        catch (Exception ex)
        {
            _db.Ado.RollbackTran();
            return Ok(new { code = 500, message = ex.Message });
        }

        return Ok(new
        {
            code = 0,
            data = new
            {
                instanceId,
                instanceNo,
                status = isCompletedDirectly ? "completed" : "running",
                nextNodeIds = nextNodes.Where(x => x.BizType != "end").Select(x => x.Id).Distinct().ToList()
            }
        });
    }

    public class RuntimeCompleteTaskRequest
    {
        public Guid TaskId { get; set; }
        public string Action { get; set; } = "agree";
        public string? Comment { get; set; }
        /** action=reject 时可指定退回节点；为空则按“驳回终止”处理 */
        public string? RejectToNodeId { get; set; }
        public JsonElement? MainForm { get; set; }
        public JsonElement? TabsData { get; set; }
    }

    [HttpPost("task/complete")]
    public IActionResult CompleteTask([FromBody] RuntimeCompleteTaskRequest req)
    {
        var uid = RuntimeActorUserId();
        var action = (req.Action ?? "agree").Trim().ToLowerInvariant();
        if (req.TaskId == Guid.Empty) return Ok(new { code = 400, message = "taskId 不能为空" });
        if (action != "agree" && action != "reject")
            return Ok(new { code = 400, message = "action 仅支持 agree/reject" });

        var task = _db.Queryable<wf_task>().InSingle(req.TaskId);
        if (task == null) return Ok(new { code = 404, message = "任务不存在" });
        if (task.status != 0) return Ok(new { code = 409, message = "任务已处理" });
        if (!string.Equals(task.assignee_user_id, uid, StringComparison.OrdinalIgnoreCase))
            return Ok(new { code = 403, message = "仅任务办理人可处理" });

        var inst = _db.Queryable<wf_instance>().InSingle(task.instance_id);
        if (inst == null) return Ok(new { code = 404, message = "实例不存在" });
        if (inst.status != 0) return Ok(new { code = 409, message = "实例非运行中状态" });

        var ver = _db.Queryable<wf_process_def_ver>().InSingle(inst.process_def_ver_id);
        if (ver == null) return Ok(new { code = 404, message = "流程版本不存在" });
        if (!TryParseGraph(ver.definition_json, out var graph, out var parseErr))
            return Ok(new { code = 400, message = $"definition_json 解析失败：{parseErr}" });

        var form = ToJObjectOrNull(req.MainForm) ?? LatestMainForm(inst.id) ?? new JObject();
        var tabsData = ToJObjectOrNull(req.TabsData);
        var ctx = new JObject
        {
            ["starterUserId"] = inst.starter_emp_id,
            ["starterDeptId"] = inst.starter_dept_id ?? "",
        };
        var now = DateTime.Now;

        var curNode = graph.Nodes.FirstOrDefault(n => n.Id == task.node_id);
        if (curNode == null) return Ok(new { code = 400, message = "当前任务节点不存在于定义中" });

        var nodeMode = ResolveNodeRoutingMode(curNode);
        var pendingAtNode = _db.Queryable<wf_task>()
            .Where(t => t.instance_id == inst.id && t.node_id == task.node_id && t.status == 0)
            .ToList();

        var transition = BuildTransitionForTaskComplete(
            graph,
            curNode,
            task,
            pendingAtNode,
            action,
            req.RejectToNodeId,
            form,
            ctx);
        if (!transition.Ok)
            return Ok(new { code = 400, message = transition.Message });

        _db.Ado.BeginTran();
        try
        {
            _db.Updateable<wf_task>()
                .SetColumns(t => t.status == (action == "agree" ? (byte)1 : (byte)2))
                .SetColumns(t => t.completed_at == now)
                .SetColumns(t => t.updated_at == now)
                .Where(t => t.id == req.TaskId)
                .ExecuteCommand();

            _db.Insertable(new wf_instance_data
            {
                id = Guid.NewGuid(),
                instance_id = inst.id,
                node_id = task.node_id,
                form_code = null,
                main_form_json = form.HasValues ? form.ToString(Formatting.None) : null,
                tabs_data_json = tabsData?.HasValues == true ? tabsData.ToString(Formatting.None) : null,
                snapshot_at = now,
                operator_user_id = uid
            }).ExecuteCommand();

            _db.Insertable(new wf_action_log
            {
                id = Guid.NewGuid(),
                instance_id = inst.id,
                task_id = task.id,
                node_id = task.node_id,
                action_type = action == "agree" ? "approve" : "reject",
                action_result = action,
                operator_user_id = uid,
                operator_name = uid,
                comment = req.Comment?.Trim(),
                payload_json = null,
                action_at = now,
                created_at = now
            }).ExecuteCommand();

            if (transition.CancelTaskIds.Count > 0)
            {
                _db.Updateable<wf_task>()
                    .SetColumns(t => t.status == (byte)4)
                    .SetColumns(t => t.updated_at == now)
                    .Where(t => transition.CancelTaskIds.Contains(t.id))
                    .ExecuteCommand();
            }

            if (transition.WillEnd)
            {
                _db.Updateable<wf_instance>()
                    .SetColumns(i => i.status == transition.EndStatus)
                    .SetColumns(i => i.current_node_ids == "")
                    .SetColumns(i => i.ended_at == now)
                    .SetColumns(i => i.updated_at == now)
                    .Where(i => i.id == inst.id)
                    .ExecuteCommand();
            }
            else
            {
                foreach (var plan in transition.NewTaskPlans)
                {
                    _db.Insertable(new wf_task
                    {
                        id = Guid.NewGuid(),
                        task_no = NewBizNo("WFT"),
                        instance_id = inst.id,
                        node_id = plan.NodeId,
                        node_name = plan.NodeName,
                        assignee_user_id = plan.AssigneeUserId,
                        assignee_name = plan.AssigneeName,
                        task_type = plan.TaskType,
                        status = 0,
                        sign_mode = plan.SignMode,
                        batch_no = plan.BatchNo,
                        source_task_id = task.id,
                        tenant_id = null,
                        received_at = now,
                        completed_at = null,
                        due_at = null,
                        created_at = now,
                        updated_at = now
                    }).ExecuteCommand();
                }

                var nextCsv = string.Join(",", transition.NextRunningNodeIds.Distinct());
                _db.Updateable<wf_instance>()
                    .SetColumns(i => i.current_node_ids == nextCsv)
                    .SetColumns(i => i.updated_at == now)
                    .Where(i => i.id == inst.id)
                    .ExecuteCommand();
            }

            _db.Ado.CommitTran();
        }
        catch (Exception ex)
        {
            _db.Ado.RollbackTran();
            return Ok(new { code = 500, message = ex.Message });
        }

        return Ok(new
        {
            code = 0,
            data = new
            {
                instanceId = inst.id,
                action,
                nodeMode,
                status = transition.WillEnd ? "ended" : "running",
                nextNodeIds = transition.NextRunningNodeIds.Distinct().ToList()
            }
        });
    }

    public class RuntimeDeleteTasksRequest
    {
        public List<string>? TaskIds { get; set; }
    }

    /// <summary>
    /// 批量删除待办（仅删除 status=0 的待办，转为 status=4 取消态，不再出现在待办列表）。
    /// </summary>
    [HttpPost("task/delete-batch")]
    public IActionResult DeleteTasks([FromBody] RuntimeDeleteTasksRequest req)
    {
        if (!IsWorkflowAdmin())
            return Ok(new { code = 403, message = "无权限执行批量删除待办操作" });

        var rawIds = (req?.TaskIds ?? new List<string>())
            .Select(x => (x ?? "").Trim())
            .Where(x => x.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        if (rawIds.Count == 0) return Ok(new { code = 400, message = "taskIds 不能为空" });

        var guidIds = rawIds
            .Select(x => Guid.TryParse(x, out var g) ? g : Guid.Empty)
            .Where(g => g != Guid.Empty)
            .Distinct()
            .ToList();
        if (guidIds.Count == 0) return Ok(new { code = 400, message = "taskIds 格式不正确" });

        var now = DateTime.Now;
        var affected = _db.Updateable<wf_task>()
            .SetColumns(t => t.status == 4)
            .SetColumns(t => t.completed_at == now)
            .SetColumns(t => t.updated_at == now)
            .Where(t => guidIds.Contains(t.id) && t.status == 0)
            .ExecuteCommand();

        return Ok(new
        {
            code = 0,
            data = new
            {
                requested = rawIds.Count,
                affected
            }
        });
    }

    [HttpGet("todo")]
    public IActionResult GetMyTodo([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var uid = RuntimeActorUserId();
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var total = 0;
        var data = _db.Queryable<wf_task, wf_instance, wf_process_def>(
                (t, i, d) => t.instance_id == i.id && i.process_def_id == d.id)
            .Where((t, i, d) => t.status == 0 && t.assignee_user_id == uid)
            .OrderBy((t, i, d) => t.received_at, OrderByType.Desc)
            .Select((t, i, d) => new
            {
                taskId = t.id,
                taskNo = t.task_no,
                instanceId = i.id,
                instanceNo = i.instance_no,
                processName = d.process_name,
                nodeId = t.node_id,
                nodeName = t.node_name,
                assigneeUserId = t.assignee_user_id,
                assigneeName = t.assignee_name,
                receivedAt = t.received_at,
                businessKey = i.business_key,
                title = i.title,
                status = t.status,
            })
            .ToPageList(page, pageSize, ref total);

        var cache = new Dictionary<string, (string WorkNo, string DisplayName)>(StringComparer.OrdinalIgnoreCase);
        var items = data.Select(x =>
        {
            var assigneeId = Convert.ToString(x.assigneeUserId) ?? "";
            var assigneeName = Convert.ToString(x.assigneeName) ?? "";
            if (!cache.TryGetValue(assigneeId, out var prof))
            {
                prof = ResolveAssigneeProfile(assigneeId, assigneeName);
                cache[assigneeId] = prof;
            }
            return new
            {
                x.taskId,
                x.taskNo,
                x.instanceId,
                x.instanceNo,
                x.processName,
                x.nodeId,
                x.nodeName,
                x.assigneeUserId,
                x.assigneeName,
                assigneeWorkNo = prof.WorkNo,
                assigneeDisplayName = prof.DisplayName,
                x.receivedAt,
                x.businessKey,
                x.title,
                x.status,
            };
        }).ToList();

        return Ok(new
        {
            code = 0,
            data = new
            {
                page,
                pageSize,
                total,
                items
            }
        });
    }

    /// <summary>
    /// 全员待办（不按办理人过滤）。用于监控/排查；办理任务仍须任务办理人本人调用 task/complete。
    /// </summary>
    [HttpGet("todo/all")]
    public IActionResult GetAllTodo(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? box = null)
    {
        if (!IsWorkflowAdmin())
            return Ok(new { code = 403, message = "无权限查看全员待办" });

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var boxMode = (box ?? "todo").Trim().ToLowerInvariant();
        if (boxMode != "todo" && boxMode != "cc" && boxMode != "done")
        {
            boxMode = "todo";
        }

        var total = 0;
        var q = _db.Queryable<wf_task, wf_instance, wf_process_def>(
            (t, i, d) => t.instance_id == i.id && i.process_def_id == d.id);
        if (boxMode == "todo")
        {
            q = q.Where((t, i, d) => t.status == 0 && t.task_type != 2);
        }
        else if (boxMode == "cc")
        {
            q = q.Where((t, i, d) => t.status == 0 && t.task_type == 2);
        }
        else
        {
            q = q.Where((t, i, d) => t.status != 0);
        }
        var data = q
            .OrderBy((t, i, d) => boxMode == "done" ? t.completed_at : t.received_at, OrderByType.Desc)
            .Select((t, i, d) => new
            {
                taskId = t.id,
                taskNo = t.task_no,
                instanceId = i.id,
                instanceNo = i.instance_no,
                processName = d.process_name,
                nodeId = t.node_id,
                nodeName = t.node_name,
                assigneeUserId = t.assignee_user_id,
                assigneeName = t.assignee_name,
                taskType = t.task_type,
                receivedAt = t.received_at,
                completedAt = t.completed_at,
                businessKey = i.business_key,
                title = i.title,
                status = t.status,
            })
            .ToPageList(page, pageSize, ref total);

        var cache = new Dictionary<string, (string WorkNo, string DisplayName)>(StringComparer.OrdinalIgnoreCase);
        var items = data.Select(x =>
        {
            var assigneeId = Convert.ToString(x.assigneeUserId) ?? "";
            var assigneeName = Convert.ToString(x.assigneeName) ?? "";
            if (!cache.TryGetValue(assigneeId, out var prof))
            {
                prof = ResolveAssigneeProfile(assigneeId, assigneeName);
                cache[assigneeId] = prof;
            }
            return new
            {
                x.taskId,
                x.taskNo,
                x.instanceId,
                x.instanceNo,
                x.processName,
                x.nodeId,
                x.nodeName,
                x.assigneeUserId,
                x.assigneeName,
                x.taskType,
                assigneeWorkNo = prof.WorkNo,
                assigneeDisplayName = prof.DisplayName,
                x.receivedAt,
                x.completedAt,
                x.businessKey,
                x.title,
                x.status,
            };
        }).ToList();

        return Ok(new
        {
            code = 0,
            data = new
            {
                page,
                pageSize,
                total,
                items
            }
        });
    }

    private static bool LooksLikeRoleLabel(string s)
    {
        var t = (s ?? "").Trim();
        if (t.Length == 0) return false;
        return t.Contains("负责人", StringComparison.OrdinalIgnoreCase)
            || t.Contains("经理", StringComparison.OrdinalIgnoreCase)
            || t.Contains("审批", StringComparison.OrdinalIgnoreCase)
            || t.Contains("发起", StringComparison.OrdinalIgnoreCase)
            || t.Contains("角色", StringComparison.OrdinalIgnoreCase);
    }

    private (string WorkNo, string DisplayName) ResolveAssigneeProfile(string assigneeUserId, string? assigneeName)
    {
        var uid = (assigneeUserId ?? "").Trim();
        var rawName = (assigneeName ?? "").Trim();
        if (uid.Length == 0) return ("", rawName);

        static string Cell(DataRow row, string col)
        {
            if (!row.Table.Columns.Contains(col)) return "";
            var o = row[col];
            return o == null || o == DBNull.Value ? "" : o.ToString()!.Trim();
        }

        try
        {
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1
                  u.username AS username,
                  u.employee_id AS employee_id,
                  u.name AS user_name,
                  e.code AS emp_code,
                  e.name AS emp_name
                FROM dbo.vben_t_sys_user u WITH (NOLOCK)
                LEFT JOIN dbo.t_base_employee e WITH (NOLOCK)
                  ON (
                       LTRIM(RTRIM(ISNULL(e.code,''))) = LTRIM(RTRIM(ISNULL(u.employee_id,'')))
                    OR (
                         u.username IS NOT NULL
                     AND LTRIM(RTRIM(ISNULL(e.username,''))) = LTRIM(RTRIM(ISNULL(u.username,'')))
                    )
                  )
                WHERE LTRIM(RTRIM(CAST(u.id AS varchar(50)))) = LTRIM(RTRIM(@uid))
                   OR LTRIM(RTRIM(ISNULL(u.employee_id,''))) = LTRIM(RTRIM(@uid))
                   OR LTRIM(RTRIM(ISNULL(u.username,''))) = LTRIM(RTRIM(@uid))
                """,
                new SugarParameter("@uid", uid)
            );
            if (dt.Rows.Count > 0)
            {
                var r = dt.Rows[0];
                var empCode = Cell(r, "emp_code");
                var employeeId = Cell(r, "employee_id");
                var username = Cell(r, "username");
                var userName = Cell(r, "user_name");
                var empName = Cell(r, "emp_name");

                var workNo = !string.IsNullOrWhiteSpace(empCode)
                    ? empCode
                    : !string.IsNullOrWhiteSpace(employeeId)
                        ? employeeId
                        : !string.IsNullOrWhiteSpace(username)
                            ? username
                            : uid;

                // 姓名优先员工主数据；若联表没拿到员工名，再按“工号/用户名”直查员工表一次兜底。
                if (string.IsNullOrWhiteSpace(empName))
                {
                    var dtEmpByCode = _db.Ado.GetDataTable(
                        """
                        SELECT TOP 1
                          e.code AS emp_code,
                          e.name AS emp_name
                        FROM dbo.t_base_employee e WITH (NOLOCK)
                        WHERE LTRIM(RTRIM(CAST(e.id AS varchar(50)))) = LTRIM(RTRIM(@k))
                           OR LTRIM(RTRIM(ISNULL(e.code,''))) = LTRIM(RTRIM(@k))
                           OR LTRIM(RTRIM(ISNULL(e.username,''))) = LTRIM(RTRIM(@k))
                        """,
                        new SugarParameter("@k", workNo)
                    );
                    if (dtEmpByCode.Rows.Count > 0)
                    {
                        var er = dtEmpByCode.Rows[0];
                        var byCodeName = Cell(er, "emp_name");
                        var byCodeNo = Cell(er, "emp_code");
                        if (!string.IsNullOrWhiteSpace(byCodeNo)) workNo = byCodeNo;
                        if (!string.IsNullOrWhiteSpace(byCodeName)) empName = byCodeName;
                    }
                }

                var displayName = !string.IsNullOrWhiteSpace(empName)
                    ? empName
                    : (!LooksLikeRoleLabel(userName) && !string.IsNullOrWhiteSpace(userName)
                        ? userName
                        : workNo);

                return (workNo, displayName);
            }
        }
        catch
        {
            // ignore and fallback
        }

        // 未命中 sys_user 时，也按传入 id（可能本身就是工号）直查员工主数据
        try
        {
            var dtEmp = _db.Ado.GetDataTable(
                """
                SELECT TOP 1
                  e.code AS emp_code,
                  e.name AS emp_name
                FROM dbo.t_base_employee e WITH (NOLOCK)
                WHERE LTRIM(RTRIM(CAST(e.id AS varchar(50)))) = LTRIM(RTRIM(@k))
                   OR LTRIM(RTRIM(ISNULL(e.code,''))) = LTRIM(RTRIM(@k))
                   OR LTRIM(RTRIM(ISNULL(e.username,''))) = LTRIM(RTRIM(@k))
                """,
                new SugarParameter("@k", uid)
            );
            if (dtEmp.Rows.Count > 0)
            {
                var er = dtEmp.Rows[0];
                var empCode = Cell(er, "emp_code");
                var empName = Cell(er, "emp_name");
                var workNo = !string.IsNullOrWhiteSpace(empCode) ? empCode : uid;
                var displayName = !string.IsNullOrWhiteSpace(empName) ? empName : workNo;
                return (workNo, displayName);
            }
        }
        catch
        {
            // ignore and fallback
        }

        var fallbackName = LooksLikeRoleLabel(rawName) ? uid : (string.IsNullOrWhiteSpace(rawName) ? uid : rawName);
        return (uid, fallbackName);
    }

    [HttpGet("instance/{instanceId:guid}")]
    public IActionResult GetInstanceDetail(Guid instanceId)
    {
        var inst = _db.Queryable<wf_instance>().InSingle(instanceId);
        if (inst == null) return Ok(new { code = 404, message = "实例不存在" });

        var def = _db.Queryable<wf_process_def>().InSingle(inst.process_def_id);
        var ver = _db.Queryable<wf_process_def_ver>().InSingle(inst.process_def_ver_id);
        var tasks = _db.Queryable<wf_task>()
            .Where(t => t.instance_id == instanceId)
            .OrderBy(t => t.created_at, OrderByType.Desc)
            .ToList();
        var latestData = _db.Queryable<wf_instance_data>()
            .Where(d => d.instance_id == instanceId)
            .OrderBy(d => d.snapshot_at, OrderByType.Desc)
            .First();

        return Ok(new
        {
            code = 0,
            data = new
            {
                instance = inst,
                process = def == null ? null : new
                {
                    def.id,
                    def.process_code,
                    def.process_name,
                    versionNo = ver?.version_no
                },
                latestData = latestData == null ? null : new
                {
                    latestData.node_id,
                    latestData.form_code,
                    latestData.main_form_json,
                    latestData.tabs_data_json,
                    latestData.snapshot_at
                },
                tasks = tasks.Select(t => new
                {
                    t.id,
                    t.task_no,
                    t.node_id,
                    t.node_name,
                    t.assignee_user_id,
                    t.assignee_name,
                    t.task_type,
                    t.status,
                    t.sign_mode,
                    t.batch_no,
                    t.received_at,
                    t.completed_at
                }).ToList()
            }
        });
    }

    [HttpGet("instance/{instanceId:guid}/timeline")]
    public IActionResult GetInstanceTimeline(Guid instanceId)
    {
        var inst = _db.Queryable<wf_instance>().InSingle(instanceId);
        if (inst == null) return Ok(new { code = 404, message = "实例不存在" });

        var logs = _db.Queryable<wf_action_log>()
            .Where(x => x.instance_id == instanceId)
            .OrderBy(x => x.action_at, OrderByType.Asc)
            .ToList();

        return Ok(new
        {
            code = 0,
            data = logs.Select(l => new
            {
                l.id,
                l.task_id,
                l.node_id,
                l.action_type,
                l.action_result,
                l.operator_user_id,
                l.operator_name,
                l.comment,
                l.payload_json,
                l.action_at
            }).ToList()
        });
    }

    private wf_process_def? ResolveProcessDef(Guid? processDefId, string? processCode)
    {
        if (processDefId is Guid id && id != Guid.Empty)
            return _db.Queryable<wf_process_def>().InSingle(id);
        var code = (processCode ?? "").Trim();
        if (code.Length == 0) return null;
        return _db.Queryable<wf_process_def>().First(x => x.process_code == code);
    }

    private wf_process_def_ver? ResolvePublishedVersion(Guid processDefId)
    {
        return _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == processDefId && v.is_published)
            .OrderBy(v => v.version_no, OrderByType.Desc)
            .First();
    }

    private static bool TryParseGraph(string definitionJson, out GraphVm graph, out string error)
    {
        graph = new GraphVm();
        error = "";
        try
        {
            var root = JObject.Parse(definitionJson);
            var gd = root["graphData"] as JObject ?? root["graph"] as JObject ?? new JObject();
            var nodes = gd["nodes"] as JArray ?? new JArray();
            var edges = gd["edges"] as JArray ?? new JArray();

            graph.Nodes = nodes.Select(n =>
            {
                var jo = n as JObject ?? new JObject();
                var id = jo["id"]?.ToString() ?? "";
                var text = jo["text"]?["value"]?.ToString() ?? jo["text"]?.ToString() ?? id;
                var props = jo["properties"] as JObject ?? new JObject();
                var biz = (props["bizType"]?.ToString() ?? "").Trim().ToLowerInvariant();
                if (biz.Length == 0)
                {
                    var tp = (jo["type"]?.ToString() ?? "").Trim().ToLowerInvariant();
                    biz = tp switch
                    {
                        "diamond" => "condition",
                        "circle" => "approve",
                        _ => "approve",
                    };
                }
                return new NodeVm { Id = id, Name = text, BizType = biz, Properties = props };
            }).Where(x => !string.IsNullOrWhiteSpace(x.Id)).ToList();

            graph.Edges = edges.Select(e =>
            {
                var jo = e as JObject ?? new JObject();
                var p = jo["properties"] as JObject ?? new JObject();
                return new EdgeVm
                {
                    Id = jo["id"]?.ToString() ?? "",
                    SourceNodeId = jo["sourceNodeId"]?.ToString() ?? "",
                    TargetNodeId = jo["targetNodeId"]?.ToString() ?? "",
                    Priority = p["priority"]?.Value<int?>() ?? 100,
                    Properties = p
                };
            }).Where(x => !string.IsNullOrWhiteSpace(x.SourceNodeId) && !string.IsNullOrWhiteSpace(x.TargetNodeId))
                .ToList();

            return true;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    /// <summary>
    /// 设计器在「退回」出口上标记 isReturn=true。同意办理时不得沿该边前进，否则无条件边会因 priority 靠前而误走退回线。
    /// </summary>
    private static bool IsReturnEdgeProperties(JObject properties)
    {
        var v = properties["isReturn"];
        if (v == null) return false;
        if (v.Type == JTokenType.Boolean) return v.Value<bool>();
        var s = v.ToString().Trim();
        return s.Equals("true", StringComparison.OrdinalIgnoreCase) || s == "1";
    }

    /// <summary>
    /// 从当前节点沿出边前进到下一可执行节点（跳过条件网关仅作传递）。
    /// <paramref name="skipReturnEdgesOnForwardRouting"/>：同意/发起提交等「正向」流转时跳过 isReturn 边，避免误退回。
    /// </summary>
    private static List<NodeVm> ResolveNextActionableNodes(
        GraphVm graph,
        string fromNodeId,
        JObject form,
        JObject ctx,
        bool skipReturnEdgesOnForwardRouting = true)
    {
        var output = new List<NodeVm>();
        var queue = new Queue<string>();
        var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        queue.Enqueue(fromNodeId);

        while (queue.Count > 0)
        {
            var cur = queue.Dequeue();
            if (!visited.Add(cur)) continue;

            // 与前端「出口顺序」一致：Priority 升序；每条边再 MatchEdge，首条命中即采用，不再看后续边。
            var outs = graph.Edges
                .Where(e => string.Equals(e.SourceNodeId, cur, StringComparison.OrdinalIgnoreCase))
                .Where(e => !skipReturnEdgesOnForwardRouting || !IsReturnEdgeProperties(e.Properties))
                .OrderBy(e => e.Priority)
                .ToList();
            if (outs.Count == 0) continue;

            EdgeVm? matched = null;
            foreach (var e in outs)
            {
                if (MatchEdge(e.Properties, form, ctx))
                {
                    matched = e;
                    break;
                }
            }
            matched ??= outs[0];

            var next = graph.Nodes.FirstOrDefault(n =>
                string.Equals(n.Id, matched.TargetNodeId, StringComparison.OrdinalIgnoreCase));
            if (next == null) continue;

            if (next.BizType == "condition")
                queue.Enqueue(next.Id);
            else
                output.Add(next);
        }

        return output;
    }

    private static bool MatchEdge(JObject properties, JObject form, JObject ctx)
    {
        var groups = properties["ruleGroups"]?["anyOf"] as JArray;
        if (groups != null && groups.Count > 0)
        {
            foreach (var g in groups.OfType<JObject>())
            {
                var allOf = g["allOf"] as JArray;
                if (allOf == null || allOf.Count == 0) continue;
                if (allOf.OfType<JObject>().All(r => MatchRule(r, form, ctx)))
                    return true;
            }
            return false;
        }

        var rules = properties["rules"] as JArray;
        if (rules != null && rules.Count > 0)
            return rules.OfType<JObject>().All(r => MatchRule(r, form, ctx));

        var cond = (properties["condition"]?.ToString() ?? "").Trim();
        if (cond.Length > 0) return MatchFallbackCondition(cond, form);

        return true;
    }

    private static bool MatchRule(JObject rule, JObject form, JObject ctx)
    {
        var scope = (rule["scope"]?.ToString() ?? "form").Trim().ToLowerInvariant();
        var key = (rule["key"]?.ToString() ?? "").Trim();
        var op = (rule["op"]?.ToString() ?? "==").Trim();
        if (key.Length == 0) return false;

        var left = scope == "initiator" ? (ctx[key] ?? JValue.CreateNull()) : (form[key] ?? JValue.CreateNull());
        var right = rule["value"];
        var rightTo = rule["valueTo"];

        var ls = left?.ToString() ?? "";
        var rs = right?.ToString() ?? "";
        var lNumOk = decimal.TryParse(ls, out var lNum);
        var rNumOk = decimal.TryParse(rs, out var rNum);

        return op switch
        {
            "==" => string.Equals(ls, rs, StringComparison.OrdinalIgnoreCase),
            "!=" => !string.Equals(ls, rs, StringComparison.OrdinalIgnoreCase),
            ">" when lNumOk && rNumOk => lNum > rNum,
            ">=" when lNumOk && rNumOk => lNum >= rNum,
            "<" when lNumOk && rNumOk => lNum < rNum,
            "<=" when lNumOk && rNumOk => lNum <= rNum,
            "contains" => ls.Contains(rs, StringComparison.OrdinalIgnoreCase),
            "startsWith" => ls.StartsWith(rs, StringComparison.OrdinalIgnoreCase),
            "endsWith" => ls.EndsWith(rs, StringComparison.OrdinalIgnoreCase),
            "between" when lNumOk && decimal.TryParse(rightTo?.ToString(), out var hi)
                => lNum >= rNum && lNum <= hi,
            "not_between" when lNumOk && decimal.TryParse(rightTo?.ToString(), out var hi2)
                => !(lNum >= rNum && lNum <= hi2),
            _ => false,
        };
    }

    private static bool MatchFallbackCondition(string cond, JObject form)
    {
        // MVP：支持 form.xxx == y / != / >/</>=/<= 的简表达式
        var x = cond.Replace(" ", "");
        var ops = new[] { "==", "!=", ">=", "<=", ">", "<" };
        var op = ops.FirstOrDefault(x.Contains);
        if (string.IsNullOrWhiteSpace(op)) return true;
        var parts = x.Split(op);
        if (parts.Length != 2) return true;
        var leftExpr = parts[0];
        var rightRaw = parts[1].Trim('\'', '"');
        var key = leftExpr.StartsWith("form.", StringComparison.OrdinalIgnoreCase)
            ? leftExpr["form.".Length..]
            : leftExpr;
        var left = form[key]?.ToString() ?? "";

        var lNumOk = decimal.TryParse(left, out var lNum);
        var rNumOk = decimal.TryParse(rightRaw, out var rNum);
        return op switch
        {
            "==" => string.Equals(left, rightRaw, StringComparison.OrdinalIgnoreCase),
            "!=" => !string.Equals(left, rightRaw, StringComparison.OrdinalIgnoreCase),
            ">" when lNumOk && rNumOk => lNum > rNum,
            ">=" when lNumOk && rNumOk => lNum >= rNum,
            "<" when lNumOk && rNumOk => lNum < rNum,
            "<=" when lNumOk && rNumOk => lNum <= rNum,
            _ => false,
        };
    }

    /// <summary>
    /// 解析节点审批人；assigneeStrategies 按设计器约定顺序尝试，命中第一条产出办理人的策略即停止（同条 user 可多选）。
    /// 排除发起人本人（文档：不需要自己审批）。结果 userId 均为在职员工的 t_base_employee.id。
    /// </summary>
    private (List<(string UserId, string? DisplayName)> List, string? Error) ResolveAssigneesForNode(
        NodeVm node,
        JObject form,
        JObject ctx,
        string fallbackUserId)
    {
        var starter = (ctx["starterUserId"]?.ToString() ?? "").Trim();
        var outList = new List<(string UserId, string? DisplayName)>();
        var allowSelfApproval = false;

        var arr = node.Properties["assigneeStrategies"] as JArray;
        if (arr != null && arr.Count > 0)
        {
            foreach (var jo in arr.OfType<JObject>())
            {
                var kind = (jo["kind"]?.ToString() ?? "").Trim().ToLowerInvariant();
                var value = (jo["value"]?.ToString() ?? "").Trim();
                var label = (jo["label"]?.ToString() ?? "").Trim();
                switch (kind)
                {
                    case "user":
                    {
                        if (value.Length == 0) continue;
                        var parts = value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                        var batch = new List<(string UserId, string? DisplayName)>();
                        foreach (var part in parts)
                        {
                            var id = ResolveEmployeeIdOrEmpty(part, activeOnly: true);
                            if (id.Length == 0)
                                return (new List<(string, string?)>(), $"审批人标识未映射到在职员工：{part}");
                            var dn = GetEmployeeDisplayNameOrNull(id) ?? (label.Length > 0 ? label : part);
                            batch.Add((id, dn));
                        }
                        outList = batch;
                        goto AfterStrategies;
                    }
                    case "form_field":
                    {
                        if (value.Length == 0) continue;
                        var raw = form[value]?.ToString() ?? "";
                        if (string.IsNullOrWhiteSpace(raw)) continue;
                        var id = ResolveEmployeeIdOrEmpty(raw.Trim(), activeOnly: true);
                        if (id.Length == 0)
                            return (new List<(string, string?)>(), $"表单字段值未映射到在职员工：{raw}");
                        outList = new List<(string, string?)>
                        {
                            (id, GetEmployeeDisplayNameOrNull(id) ?? raw.Trim())
                        };
                        goto AfterStrategies;
                    }
                    case "expression":
                    {
                        if (value.Length == 0) continue;
                        if (string.Equals(value.Trim(), "$resolve.initiatorSelf", StringComparison.OrdinalIgnoreCase))
                            allowSelfApproval = true;
                        var (empId, err) = ResolveAssigneeExpression(value, form, ctx);
                        if (!string.IsNullOrEmpty(err))
                            return (new List<(string, string?)>(), err);
                        if (string.IsNullOrEmpty(empId)) continue;
                        outList = new List<(string, string?)>
                        {
                            (empId, GetEmployeeDisplayNameOrNull(empId) ?? (label.Length > 0 ? label : empId))
                        };
                        goto AfterStrategies;
                    }
                    default:
                        continue;
                }
            }
        }

        AfterStrategies:
        if (outList.Count == 0)
        {
            var ar = node.Properties["approverResolve"] as JObject;
            if (ar != null)
            {
                var mode = (ar["mode"]?.ToString() ?? "").Trim();
                if (string.Equals(mode, "form_field", StringComparison.OrdinalIgnoreCase))
                {
                    var key = (ar["formFieldKey"]?.ToString() ?? "").Trim();
                    if (key.Length > 0)
                    {
                        var raw = form[key]?.ToString() ?? "";
                        if (string.IsNullOrWhiteSpace(raw))
                            return (new List<(string, string?)>(), $"表单字段「{key}」为空，无法解析审批人");
                        var id = ResolveEmployeeIdOrEmpty(raw.Trim(), activeOnly: true);
                        if (id.Length == 0)
                            return (new List<(string, string?)>(), $"表单字段值未映射到在职员工：{raw}");
                        outList.Add((id, GetEmployeeDisplayNameOrNull(id) ?? raw.Trim()));
                    }
                }
                else
                {
                    if (string.Equals(mode, "initiator_self", StringComparison.OrdinalIgnoreCase))
                        allowSelfApproval = true;
                    var expr = mode switch
                    {
                        "direct_leader" => "$resolve.directLeader",
                        "indirect_leader" => "$resolve.indirectLeader",
                        "dept_head" => "$resolve.deptHead",
                        "initiator_self" => "$resolve.initiatorSelf",
                        _ => ""
                    };
                    if (expr.Length > 0)
                    {
                        var (empId, err) = ResolveAssigneeExpression(expr, form, ctx);
                        if (!string.IsNullOrEmpty(err))
                            return (new List<(string, string?)>(), err);
                        if (!string.IsNullOrEmpty(empId))
                            outList.Add((empId, GetEmployeeDisplayNameOrNull(empId) ?? empId));
                    }
                }
            }
        }

        if (outList.Count == 0)
        {
            var assignee = (node.Properties["assignee"]?.ToString() ?? "").Trim();
            if (assignee.Length > 0)
                outList.Add((fallbackUserId, assignee));
        }
        if (outList.Count == 0)
            outList.Add((fallbackUserId, fallbackUserId));

        outList = outList
            .GroupBy(x => x.UserId, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First())
            .ToList();
        if (!allowSelfApproval)
            outList = outList
                .Where(x => !string.Equals(x.UserId, starter, StringComparison.OrdinalIgnoreCase))
                .ToList();

        if (outList.Count == 0)
            return (new List<(string, string?)>(),
                allowSelfApproval
                    ? $"{node.Name} 节点未匹配到审批人。请联系管理员核实。"
                    : $"{node.Name} 节点未匹配到审批人（已排除本人）。请联系管理员核实。");

        return (outList, null);
    }

    private static string ResolveNodeRoutingMode(NodeVm node)
    {
        var m = (node.Properties["approvalRoutingMode"]?.ToString() ?? "").Trim().ToLowerInvariant();
        if (m is "all" or "any" or "cc" or "sequential") return m;
        var b = node.Properties["behaviors"] as JObject;
        if (b?["sequentialApproval"]?.Value<bool>() == true) return "sequential";
        if (b?["countersign"]?.Value<bool>() == true) return "all";
        return node.BizType == "cc" ? "cc" : "any";
    }

    private (List<TaskPlan> Plans, string? Error) BuildNewTaskPlansForNodes(
        List<NodeVm> nodes,
        string fallbackUserId,
        JObject form,
        JObject ctx)
    {
        var plans = new List<TaskPlan>();
        foreach (var node in nodes)
        {
            var mode = ResolveNodeRoutingMode(node);
            var taskType = node.BizType == "cc" ? (byte)2 : (byte)1;
            if (mode == "sequential")
            {
                var seq = node.Properties["sequentialApprovers"] as JArray;
                if (seq != null && seq.Count > 0)
                {
                    var first = seq.OfType<JObject>().FirstOrDefault();
                    if (first != null)
                    {
                        var uid = (first["userId"]?.ToString() ?? "").Trim();
                        var label = (first["label"]?.ToString() ?? uid).Trim();
                        if (uid.Length > 0)
                        {
                            plans.Add(new TaskPlan
                            {
                                NodeId = node.Id,
                                NodeName = node.Name,
                                AssigneeUserId = uid,
                                AssigneeName = label,
                                TaskType = taskType,
                                SignMode = "sequential",
                                BatchNo = 1
                            });
                            continue;
                        }
                    }
                }
            }

            var (assignees, err) = ResolveAssigneesForNode(node, form, ctx, fallbackUserId);
            if (!string.IsNullOrEmpty(err))
                return (new List<TaskPlan>(), err);
            foreach (var a in assignees)
            {
                plans.Add(new TaskPlan
                {
                    NodeId = node.Id,
                    NodeName = node.Name,
                    AssigneeUserId = a.UserId,
                    AssigneeName = a.DisplayName,
                    TaskType = taskType,
                    SignMode = mode,
                    BatchNo = mode == "sequential" ? 1 : null
                });
            }
        }
        return (plans, null);
    }

    private TransitionPlan BuildTransitionForTaskComplete(
        GraphVm graph,
        NodeVm curNode,
        wf_task curTask,
        List<wf_task> pendingAtNode,
        string action,
        string? rejectToNodeId,
        JObject form,
        JObject ctx)
    {
        var result = new TransitionPlan { Ok = true, EndStatus = 1 };
        var mode = ResolveNodeRoutingMode(curNode);
        if (action == "reject")
        {
            if (!string.IsNullOrWhiteSpace(rejectToNodeId))
            {
                var backNode = graph.Nodes.FirstOrDefault(n => n.Id == rejectToNodeId.Trim());
                if (backNode == null)
                    return TransitionPlan.Fail("指定的退回节点不存在");
                var (backPlans, backErr) = BuildNewTaskPlansForNodes(
                    new List<NodeVm> { backNode },
                    ctx["starterUserId"]?.ToString() ?? "",
                    form,
                    ctx);
                if (!string.IsNullOrEmpty(backErr))
                    return TransitionPlan.Fail(backErr);
                result.NewTaskPlans = backPlans;
                result.NextRunningNodeIds = result.NewTaskPlans.Select(x => x.NodeId).Distinct().ToList();
                result.CancelTaskIds = pendingAtNode.Where(t => t.id != curTask.id).Select(t => t.id).ToList();
                return result;
            }

            result.WillEnd = true;
            result.EndStatus = 2; // reject => terminated
            result.CancelTaskIds = pendingAtNode.Where(t => t.id != curTask.id).Select(t => t.id).ToList();
            return result;
        }

        var siblingsAfterDone = pendingAtNode.Where(t => t.id != curTask.id).ToList();
        if (mode == "all" || mode == "cc")
        {
            if (siblingsAfterDone.Any())
            {
                result.WillEnd = false;
                result.NextRunningNodeIds = new List<string> { curNode.Id };
                return result;
            }
        }
        else if (mode == "sequential")
        {
            var curBatch = curTask.batch_no ?? 1;
            var seq = curNode.Properties["sequentialApprovers"] as JArray;
            if (seq != null && seq.Count > curBatch)
            {
                var next = seq[curBatch] as JObject; // 1-based batch -> index
                var uid = (next?["userId"]?.ToString() ?? "").Trim();
                var label = (next?["label"]?.ToString() ?? uid).Trim();
                if (uid.Length > 0)
                {
                    result.NewTaskPlans = new List<TaskPlan>
                    {
                        new()
                        {
                            NodeId = curNode.Id,
                            NodeName = curNode.Name,
                            AssigneeUserId = uid,
                            AssigneeName = label,
                            TaskType = curNode.BizType == "cc" ? (byte)2 : (byte)1,
                            SignMode = "sequential",
                            BatchNo = curBatch + 1
                        }
                    };
                    result.NextRunningNodeIds = new List<string> { curNode.Id };
                    return result;
                }
            }
        }
        else if (mode == "any")
        {
            result.CancelTaskIds = siblingsAfterDone.Select(t => t.id).ToList();
        }

        var nextNodes = ResolveNextActionableNodes(graph, curNode.Id, form, ctx);
        var runNodes = nextNodes.Where(x => x.BizType != "end").ToList();
        if (runNodes.Count == 0)
        {
            result.WillEnd = true;
            result.EndStatus = 1;
            return result;
        }

        var (fwdPlans, fwdErr) = BuildNewTaskPlansForNodes(
            runNodes,
            ctx["starterUserId"]?.ToString() ?? "",
            form,
            ctx);
        if (!string.IsNullOrEmpty(fwdErr))
            return TransitionPlan.Fail(fwdErr);
        result.NewTaskPlans = fwdPlans;
        result.NextRunningNodeIds = result.NewTaskPlans.Select(x => x.NodeId).Distinct().ToList();
        return result;
    }

    private JObject? LatestMainForm(Guid instanceId)
    {
        var row = _db.Queryable<wf_instance_data>()
            .Where(x => x.instance_id == instanceId)
            .OrderBy(x => x.snapshot_at, OrderByType.Desc)
            .First();
        if (row == null || string.IsNullOrWhiteSpace(row.main_form_json)) return null;
        try { return JObject.Parse(row.main_form_json); } catch { return null; }
    }

    private static JObject ToJObjectOrEmpty(JsonElement? element)
    {
        return ToJObjectOrNull(element) ?? new JObject();
    }

    private void InsertWfInstanceCompat(
        Guid instanceId,
        string instanceNo,
        Guid processDefId,
        Guid processDefVerId,
        string processCode,
        string processName,
        int versionNo,
        string? businessKey,
        string? title,
        string starterEmpId,
        string? starterDeptId,
        byte status,
        string currentNodeIds,
        DateTime startedAt,
        DateTime? endedAt,
        DateTime createdAt,
        DateTime updatedAt)
    {
        var cols = _db.Ado.SqlQuery<string>(
            "SELECT [name] FROM sys.columns WHERE object_id = OBJECT_ID('dbo.wf_instance')")
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var names = new List<string>();
        var vals = new List<string>();
        var ps = new List<SugarParameter>();

        void Add(string col, object? val)
        {
            if (!cols.Contains(col)) return;
            names.Add($"[{col}]");
            var p = $"@{col}";
            vals.Add(p);
            ps.Add(new SugarParameter(p, val ?? DBNull.Value));
        }

        Add("id", instanceId);
        Add("instance_no", instanceNo);
        Add("process_def_id", processDefId);
        Add("process_def_ver_id", processDefVerId);
        Add("business_key", businessKey);
        Add("title", title);
        // 新旧列并存兼容：优先使用 starter_emp_id，旧列仍同步写入
        Add("starter_emp_id", starterEmpId);
        Add("starter_user_id", starterEmpId);
        Add("starter_dept_id", starterDeptId);
        Add("status", status);
        Add("current_node_ids", currentNodeIds);
        Add("started_at", startedAt);
        Add("ended_at", endedAt);
        Add("created_at", createdAt);
        Add("updated_at", updatedAt);

        // 兼容旧版 wf_instance 强制非空列
        Add("process_code", processCode);
        Add("process_name", processName);
        Add("definition_version", versionNo.ToString());
        Add("initiator", starterEmpId);
        Add("current_node_id", currentNodeIds);

        if (names.Count == 0) throw new Exception("wf_instance 表字段读取失败");
        var sql = $"INSERT INTO [dbo].[wf_instance] ({string.Join(", ", names)}) VALUES ({string.Join(", ", vals)})";
        _db.Ado.ExecuteCommand(sql, ps);
    }

    private static JObject? ToJObjectOrNull(JsonElement? element)
    {
        if (!element.HasValue) return null;
        var value = element.Value;
        if (value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null) return null;
        try
        {
            var raw = value.GetRawText();
            if (string.IsNullOrWhiteSpace(raw)) return null;
            var token = JToken.Parse(raw);
            return token as JObject;
        }
        catch
        {
            return null;
        }
    }

    private sealed class GraphVm
    {
        public List<NodeVm> Nodes { get; set; } = new();
        public List<EdgeVm> Edges { get; set; } = new();
    }

    private sealed class NodeVm
    {
        public string Id { get; set; } = "";
        public string Name { get; set; } = "";
        public string BizType { get; set; } = "approve";
        public JObject Properties { get; set; } = new();
    }

    private sealed class EdgeVm
    {
        public string Id { get; set; } = "";
        public string SourceNodeId { get; set; } = "";
        public string TargetNodeId { get; set; } = "";
        public int Priority { get; set; } = 100;
        public JObject Properties { get; set; } = new();
    }

    private sealed class TaskPlan
    {
        public string NodeId { get; set; } = "";
        public string NodeName { get; set; } = "";
        public string AssigneeUserId { get; set; } = "";
        public string? AssigneeName { get; set; }
        public byte TaskType { get; set; } = 1;
        public string? SignMode { get; set; }
        public int? BatchNo { get; set; }
    }

    private sealed class TransitionPlan
    {
        public bool Ok { get; set; }
        public string? Message { get; set; }
        public bool WillEnd { get; set; }
        public byte EndStatus { get; set; } = 1;
        public List<Guid> CancelTaskIds { get; set; } = new();
        public List<TaskPlan> NewTaskPlans { get; set; } = new();
        public List<string> NextRunningNodeIds { get; set; } = new();

        public static TransitionPlan Fail(string msg) => new() { Ok = false, Message = msg };
    }
}

