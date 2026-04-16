using System.Security.Claims;
using System.Text.Json;
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

    /// <summary>
    /// 测试用：当 WorkflowEngine:AllowRuntimeMockUser=true 且请求头 X-Workflow-Mock-User-Id 非空时，
    /// 「我的待办 / 办理任务」按该工号识别身份（仍需有效 JWT）。生产环境请关闭。
    /// 注意：若 JWT 中无 UserId/employee_id 等声明导致 CurrentUserId 为空，旧逻辑会忽略模拟头；
    /// 此处在已认证且允许模拟时仍采用请求头工号，否则测试页「我的待办」会一直为空。
    /// </summary>
    private string RuntimeActorUserId()
    {
        var loginUid = CurrentUserId();
        var allow = _configuration.GetValue<bool?>("WorkflowEngine:AllowRuntimeMockUser") == true
            || string.Equals(_configuration["WorkflowEngine:AllowRuntimeMockUser"], "true", StringComparison.OrdinalIgnoreCase);

        if (allow
            && User?.Identity?.IsAuthenticated == true
            && Request.Headers.TryGetValue("X-Workflow-Mock-User-Id", out var mock))
        {
            var m = mock.ToString().Trim();
            if (!string.IsNullOrWhiteSpace(m))
                return m;
        }

        return loginUid;
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
        var starterUid = string.IsNullOrWhiteSpace(req.MockStarterUserId)
            ? loginUid
            : req.MockStarterUserId.Trim();
        var starterName = string.IsNullOrWhiteSpace(req.MockStarterName)
            ? starterUid
            : req.MockStarterName.Trim();

        var def = ResolveProcessDef(req.ProcessDefId, req.ProcessCode);
        if (def == null) return Ok(new { code = 404, message = "流程定义不存在" });

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
        var currentNodeIds = string.Join(",",
            nextNodes.Where(x => x.BizType != "end").Select(x => x.Id).Distinct());
        var isCompletedDirectly = !nextNodes.Any(x => x.BizType != "end");

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
                starterUserId: starterUid,
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

            foreach (var plan in BuildNewTaskPlansForNodes(nextNodes.Where(x => x.BizType != "end").ToList(), starterUid))
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
            ["starterUserId"] = inst.starter_user_id,
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
            })
            .ToPageList(page, pageSize, ref total);

        return Ok(new
        {
            code = 0,
            data = new
            {
                page,
                pageSize,
                total,
                items = data
            }
        });
    }

    /// <summary>
    /// 全员待办（不按办理人过滤）。用于监控/排查；办理任务仍须任务办理人本人调用 task/complete。
    /// </summary>
    [HttpGet("todo/all")]
    public IActionResult GetAllTodo([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var total = 0;
        var data = _db.Queryable<wf_task, wf_instance, wf_process_def>(
                (t, i, d) => t.instance_id == i.id && i.process_def_id == d.id)
            .Where((t, i, d) => t.status == 0)
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
            })
            .ToPageList(page, pageSize, ref total);

        return Ok(new
        {
            code = 0,
            data = new
            {
                page,
                pageSize,
                total,
                items = data
            }
        });
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
        var published = _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == processDefId && v.is_published)
            .OrderBy(v => v.version_no, OrderByType.Desc)
            .First();
        if (published != null) return published;
        return _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == processDefId)
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

    private static List<(string UserId, string? DisplayName)> ResolveAssignees(NodeVm node, string fallbackUserId)
    {
        var outList = new List<(string UserId, string? DisplayName)>();
        var arr = node.Properties["assigneeStrategies"] as JArray;
        if (arr != null)
        {
            foreach (var jo in arr.OfType<JObject>())
            {
                var kind = (jo["kind"]?.ToString() ?? "").Trim().ToLowerInvariant();
                var value = (jo["value"]?.ToString() ?? "").Trim();
                var label = (jo["label"]?.ToString() ?? "").Trim();
                if (kind == "user" && value.Length > 0)
                    outList.Add((value, label.Length > 0 ? label : value));
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

        return outList.GroupBy(x => x.UserId, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First())
            .ToList();
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

    private List<TaskPlan> BuildNewTaskPlansForNodes(List<NodeVm> nodes, string fallbackUserId)
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

            foreach (var a in ResolveAssignees(node, fallbackUserId))
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
        return plans;
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
                result.NewTaskPlans = BuildNewTaskPlansForNodes(new List<NodeVm> { backNode }, ctx["starterUserId"]?.ToString() ?? "");
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

        result.NewTaskPlans = BuildNewTaskPlansForNodes(runNodes, ctx["starterUserId"]?.ToString() ?? "");
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
        string starterUserId,
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
        Add("starter_user_id", starterUserId);
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
        Add("initiator", starterUserId);
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

