using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SqlSugar;
using System.Data;

namespace StoneApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class WorkflowController : ControllerBase
    {
        private readonly SqlSugarClient _db;
        private static bool _tablesEnsured = false;
        private static readonly object _tableLock = new();

        public WorkflowController(SqlSugarClient db)
        {
            _db = db;
        }

        [HttpPost("definition/save")]
        public IActionResult SaveDefinition([FromBody] SaveWorkflowDefinitionRequest req)
        {
            EnsureWorkflowTables();
            if (string.IsNullOrWhiteSpace(req.ProcessCode) || string.IsNullOrWhiteSpace(req.ProcessName) || string.IsNullOrWhiteSpace(req.DefinitionJson))
                return Ok(new { code = 400, message = "processCode/processName/definitionJson 不能为空" });

            var now = DateTime.Now;
            var userId = CurrentUserId();

            var latest = _db.Queryable<wf_definition_version>()
                .Where(x => x.process_code == req.ProcessCode)
                .OrderBy(x => x.version, OrderByType.Desc)
                .First();

            var nextVersion = (latest?.version ?? 0) + 1;
            var versionId = Guid.NewGuid();

            _db.Insertable(new wf_definition_version
            {
                id = versionId,
                process_code = req.ProcessCode,
                process_name = req.ProcessName,
                version = nextVersion,
                status = "draft",
                definition_json = req.DefinitionJson,
                created_by = userId,
                created_at = now
            }).ExecuteCommand();

            var def = _db.Queryable<wf_definition>().InSingle(req.ProcessCode);
            if (def == null)
            {
                _db.Insertable(new wf_definition
                {
                    process_code = req.ProcessCode,
                    process_name = req.ProcessName,
                    latest_version = nextVersion,
                    published_version = null,
                    status = "draft",
                    updated_by = userId,
                    updated_at = now
                }).ExecuteCommand();
            }
            else
            {
                _db.Updateable<wf_definition>()
                    .SetColumns(x => x.process_name == req.ProcessName)
                    .SetColumns(x => x.latest_version == nextVersion)
                    .SetColumns(x => x.status == "draft")
                    .SetColumns(x => x.updated_by == userId)
                    .SetColumns(x => x.updated_at == now)
                    .Where(x => x.process_code == req.ProcessCode)
                    .ExecuteCommand();
            }

            return Ok(new { code = 0, data = new { processCode = req.ProcessCode, version = nextVersion, status = "draft" } });
        }

        [HttpPost("definition/publish")]
        public IActionResult PublishDefinition([FromBody] PublishWorkflowDefinitionRequest req)
        {
            EnsureWorkflowTables();
            if (string.IsNullOrWhiteSpace(req.ProcessCode))
                return Ok(new { code = 400, message = "processCode 不能为空" });

            var versionEntity = _db.Queryable<wf_definition_version>()
                .Where(x => x.process_code == req.ProcessCode && (req.Version == null || x.version == req.Version.Value))
                .OrderBy(x => x.version, OrderByType.Desc)
                .First();

            if (versionEntity == null)
                return Ok(new { code = 404, message = "未找到可发布版本" });

            var now = DateTime.Now;
            var userId = CurrentUserId();

            _db.Updateable<wf_definition_version>()
                .SetColumns(x => x.status == "published")
                .SetColumns(x => x.published_at == now)
                .SetColumns(x => x.published_by == userId)
                .Where(x => x.id == versionEntity.id)
                .ExecuteCommand();

            _db.Updateable<wf_definition>()
                .SetColumns(x => x.process_name == versionEntity.process_name)
                .SetColumns(x => x.published_version == versionEntity.version)
                .SetColumns(x => x.status == "published")
                .SetColumns(x => x.updated_by == userId)
                .SetColumns(x => x.updated_at == now)
                .Where(x => x.process_code == req.ProcessCode)
                .ExecuteCommand();

            return Ok(new { code = 0, data = new { processCode = req.ProcessCode, version = versionEntity.version, status = "published" } });
        }

        [HttpGet("definition/get")]
        public IActionResult GetDefinition([FromQuery] string processCode, [FromQuery] int? version)
        {
            EnsureWorkflowTables();
            if (string.IsNullOrWhiteSpace(processCode))
                return Ok(new { code = 400, message = "processCode 不能为空" });

            wf_definition_version? entity = null;
            if (version != null)
            {
                entity = _db.Queryable<wf_definition_version>()
                    .Where(x => x.process_code == processCode && x.version == version.Value)
                    .First();
            }
            else
            {
                // 优先已发布；无发布版本时再取该流程最新一条（通常为草稿），避免流程管理页用 HR_* 编码拉取时误报「不存在」
                // 注意：不要在同一 baseQuery 上多次 OrderBy，SqlServer 会报「排序依据列表中的列必须唯一」
                entity = _db.Queryable<wf_definition_version>()
                    .Where(x => x.process_code == processCode && x.status == "published")
                    .OrderBy(x => x.version, OrderByType.Desc)
                    .First();
                if (entity == null)
                {
                    entity = _db.Queryable<wf_definition_version>()
                        .Where(x => x.process_code == processCode)
                        .OrderBy(x => x.version, OrderByType.Desc)
                        .First();
                }
            }

            if (entity == null)
                return Ok(new { code = 404, message = "流程定义不存在" });

            return Ok(new
            {
                code = 0,
                data = new
                {
                    entity.process_code,
                    entity.process_name,
                    entity.version,
                    entity.status,
                    entity.definition_json,
                    entity.published_at
                }
            });
        }

        [HttpGet("definition/published-list")]
        public IActionResult GetPublishedDefinitions()
        {
            EnsureWorkflowTables();
            var list = _db.Queryable<wf_definition>()
                .Where(x => x.status == "published" && x.published_version != null)
                .OrderBy(x => x.updated_at, OrderByType.Desc)
                .Select(x => new
                {
                    processCode = x.process_code,
                    processName = x.process_name,
                    publishedVersion = x.published_version,
                    updatedAt = x.updated_at
                })
                .ToList();

            return Ok(new { code = 0, data = list });
        }

        [HttpGet("definition/all-list")]
        public IActionResult GetAllDefinitions()
        {
            EnsureWorkflowTables();
            var list = _db.Queryable<wf_definition_version>()
                .OrderBy(x => x.created_at, OrderByType.Desc)
                .Select(x => new
                {
                    processCode = x.process_code,
                    processName = x.process_name,
                    version = x.version,
                    status = x.status,
                    createdAt = x.created_at,
                    publishedAt = x.published_at
                })
                .Take(500)
                .ToList();

            return Ok(new { code = 0, data = list });
        }

        [HttpGet("form-schema/list")]
        public IActionResult GetFormSchemaList([FromQuery] string? keyword)
        {
            EnsureWorkflowTables();
            var k = (keyword ?? "").Trim();
            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 500
                  CAST(id AS varchar(50)) AS id,
                  code,
                  title,
                  schema_json AS schemaJson,
                  updated_at AS updatedAt
                FROM dbo.vben_form_desinger WITH (NOLOCK)
                WHERE (@k = '' OR code LIKE '%' + @k + '%' OR title LIKE '%' + @k + '%')
                ORDER BY updated_at DESC
                """,
                new SugarParameter("@k", k));
            var data = dt.Rows.Cast<DataRow>().Select(r => new
            {
                id = r["id"]?.ToString(),
                code = r["code"]?.ToString(),
                title = r["title"]?.ToString(),
                schemaJson = r["schemaJson"]?.ToString(),
                updatedAt = r["updatedAt"] == DBNull.Value ? null : r["updatedAt"]
            }).ToList();

            return Ok(new { code = 0, data });
        }

        [HttpPost("binding/save")]
        public IActionResult SaveWorkflowFormBinding([FromBody] SaveWorkflowFormBindingRequest req)
        {
            EnsureWorkflowTables();
            if (string.IsNullOrWhiteSpace(req.ProcessCode) || req.ProcessVersion <= 0 || string.IsNullOrWhiteSpace(req.FormCode))
                return Ok(new { code = 400, message = "processCode/processVersion/formCode 不能为空" });

            var def = _db.Queryable<wf_definition_version>()
                .Where(x => x.process_code == req.ProcessCode && x.version == req.ProcessVersion)
                .First();
            if (def == null)
                return Ok(new { code = 404, message = "流程定义版本不存在" });

            var formDt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1
                  CAST(id AS varchar(50)) AS id,
                  code,
                  title,
                  schema_json AS schemaJson
                FROM dbo.vben_form_desinger WITH (NOLOCK)
                WHERE (@id IS NOT NULL AND id = @id)
                   OR (@id IS NULL AND code = @code)
                ORDER BY updated_at DESC
                """,
                new SugarParameter("@id", req.FormRecordId == null || req.FormRecordId == Guid.Empty ? DBNull.Value : req.FormRecordId.Value),
                new SugarParameter("@code", req.FormCode.Trim()));
            if (formDt.Rows.Count == 0)
                return Ok(new { code = 404, message = "表单 schema 不存在" });
            var fr = formDt.Rows[0];
            var formId = Guid.Parse(fr["id"]?.ToString() ?? Guid.Empty.ToString());
            var formCode = fr["code"]?.ToString() ?? req.FormCode.Trim();
            var formSchemaJson = fr["schemaJson"]?.ToString() ?? "{}";

            var now = DateTime.Now;
            var userId = CurrentUserId();
            var exists = _db.Queryable<wf_form_binding>()
                .Where(x => x.process_code == req.ProcessCode && x.process_version == req.ProcessVersion)
                .OrderBy(x => x.created_at, OrderByType.Desc)
                .First();

            if (exists == null)
            {
                var row = new wf_form_binding
                {
                    id = Guid.NewGuid(),
                    process_code = req.ProcessCode,
                    process_version = req.ProcessVersion,
                    form_code = formCode,
                    form_record_id = formId,
                    workflow_definition_json = def.definition_json,
                    form_schema_json = formSchemaJson,
                    created_at = now,
                    created_by = userId,
                    updated_at = now,
                    updated_by = userId,
                };
                _db.Insertable(row).ExecuteCommand();
            }
            else
            {
                _db.Updateable<wf_form_binding>()
                    .SetColumns(x => x.form_code == formCode)
                    .SetColumns(x => x.form_record_id == formId)
                    .SetColumns(x => x.workflow_definition_json == def.definition_json)
                    .SetColumns(x => x.form_schema_json == formSchemaJson)
                    .SetColumns(x => x.updated_at == now)
                    .SetColumns(x => x.updated_by == userId)
                    .Where(x => x.id == exists.id)
                    .ExecuteCommand();
            }

            return Ok(new
            {
                code = 0,
                data = new
                {
                    processCode = req.ProcessCode,
                    processVersion = req.ProcessVersion,
                    formCode = formCode,
                    formRecordId = formId,
                }
            });
        }

        [HttpGet("binding/get")]
        public IActionResult GetWorkflowFormBinding([FromQuery] string processCode, [FromQuery] int? processVersion)
        {
            EnsureWorkflowTables();
            if (string.IsNullOrWhiteSpace(processCode))
                return Ok(new { code = 400, message = "processCode 不能为空" });

            var q = _db.Queryable<wf_form_binding>().Where(x => x.process_code == processCode);
            if (processVersion != null) q = q.Where(x => x.process_version == processVersion.Value);
            var row = q.OrderBy(x => x.updated_at, OrderByType.Desc).First();
            if (row == null) return Ok(new { code = 404, message = "未配置绑定" });

            return Ok(new
            {
                code = 0,
                data = new
                {
                    processCode = row.process_code,
                    processVersion = row.process_version,
                    formCode = row.form_code,
                    formRecordId = row.form_record_id,
                    workflowDefinitionJson = row.workflow_definition_json,
                    formSchemaJson = row.form_schema_json,
                    updatedAt = row.updated_at,
                    updatedBy = row.updated_by,
                }
            });
        }

        [HttpPost("instance/start")]
        public IActionResult StartInstance([FromBody] StartWorkflowInstanceRequest req)
        {
            EnsureWorkflowTables();
            if (string.IsNullOrWhiteSpace(req.ProcessCode))
                return Ok(new { code = 400, message = "processCode 不能为空" });

            var def = _db.Queryable<wf_definition_version>()
                .Where(x => x.process_code == req.ProcessCode && x.status == "published")
                .OrderBy(x => x.version, OrderByType.Desc)
                .First();
            if (def == null)
                return Ok(new { code = 404, message = "未找到已发布流程定义" });

            JObject graph;
            try
            {
                graph = JObject.Parse(def.definition_json);
            }
            catch
            {
                return Ok(new { code = 400, message = "流程定义 JSON 无效" });
            }

            var now = DateTime.Now;
            var userId = CurrentUserId();
            var instanceId = Guid.NewGuid();

            _db.Ado.BeginTran();
            try
            {
                _db.Insertable(new wf_instance
                {
                    id = instanceId,
                    process_code = req.ProcessCode,
                    process_name = def.process_name,
                    definition_version = def.version,
                    business_key = req.BusinessKey,
                    status = "running",
                    current_node_id = "",
                    current_node_name = "",
                    initiator = userId,
                    form_data_json = req.FormDataJson ?? "{}",
                    created_at = now,
                    updated_at = now
                }).ExecuteCommand();

                var startNode = FindStartNode(graph);
                if (startNode == null)
                    throw new Exception("流程图没有开始节点");

                var formData = ParseFormData(req.FormDataJson);
                var nextNode = ResolveNextExecutableNode(graph, startNode["id"]?.ToString() ?? "", formData);
                if (nextNode == null)
                {
                    MarkInstanceFinished(instanceId, "流程无审批节点，自动结束");
                }
                else
                {
                    CreatePendingTask(instanceId, nextNode);
                    UpdateInstanceCurrentNode(instanceId, nextNode["id"]?.ToString() ?? "", nextNode["text"]?.ToString() ?? "");
                }

                AddLog(instanceId, "start", $"发起流程：{req.ProcessCode}", userId, req.Comment);
                _db.Ado.CommitTran();
            }
            catch (Exception ex)
            {
                _db.Ado.RollbackTran();
                return Ok(new { code = 500, message = ex.Message });
            }

            return Ok(new { code = 0, data = new { instanceId } });
        }

        [HttpGet("task/todo")]
        public IActionResult GetTodoTasks()
        {
            EnsureWorkflowTables();
            var userId = CurrentUserId();
            var userName = User?.Identity?.Name ?? "";

            var data = _db.Queryable<wf_task, wf_instance>((t, i) => t.instance_id == i.id)
                .Where((t, i) => t.status == "pending" && (t.assignee == userId || t.assignee == userName || t.assignee == "待设置"))
                .OrderBy((t, i) => t.created_at, OrderByType.Desc)
                .Select((t, i) => new
                {
                    taskId = t.id,
                    instanceId = t.instance_id,
                    t.node_id,
                    t.node_name,
                    t.assignee,
                    t.created_at,
                    i.process_code,
                    i.process_name,
                    i.business_key,
                    i.initiator,
                    i.status
                })
                .Take(200)
                .ToList();

            return Ok(new { code = 0, data });
        }

        [HttpPost("task/approve")]
        public IActionResult ApproveTask([FromBody] ActionTaskRequest req)
        {
            return HandleTaskAction(req, "approve");
        }

        [HttpPost("task/reject")]
        public IActionResult RejectTask([FromBody] ActionTaskRequest req)
        {
            return HandleTaskAction(req, "reject");
        }

        private IActionResult HandleTaskAction(ActionTaskRequest req, string action)
        {
            EnsureWorkflowTables();
            if (req.TaskId == Guid.Empty)
                return Ok(new { code = 400, message = "taskId 不能为空" });

            var task = _db.Queryable<wf_task>().InSingle(req.TaskId);
            if (task == null) return Ok(new { code = 404, message = "任务不存在" });
            if (task.status != "pending") return Ok(new { code = 400, message = "任务已处理" });

            var instance = _db.Queryable<wf_instance>().InSingle(task.instance_id);
            if (instance == null) return Ok(new { code = 404, message = "流程实例不存在" });

            var userId = CurrentUserId();
            var userName = (User?.Identity?.Name ?? "").Trim();
            var taskAssignee = (task.assignee ?? "").Trim();
            if (!CanOperateTask(taskAssignee, userId, userName))
            {
                return Ok(new { code = 403, message = "无权限处理该任务（仅任务办理人可操作）" });
            }
            var now = DateTime.Now;

            _db.Ado.BeginTran();
            try
            {
                _db.Updateable<wf_task>()
                    .SetColumns(x => x.status == (action == "approve" ? "approved" : "rejected"))
                    .SetColumns(x => x.action_by == userId)
                    .SetColumns(x => x.action_time == now)
                    .SetColumns(x => x.comment == req.Comment)
                    .Where(x => x.id == req.TaskId)
                    .ExecuteCommand();

                if (action == "reject")
                {
                    _db.Updateable<wf_instance>()
                        .SetColumns(x => x.status == "rejected")
                        .SetColumns(x => x.updated_at == now)
                        .Where(x => x.id == instance.id)
                        .ExecuteCommand();
                    AddLog(instance.id, "reject", "任务驳回，流程结束", userId, req.Comment);
                }
                else
                {
                    var def = _db.Queryable<wf_definition_version>()
                        .Where(x => x.process_code == instance.process_code && x.version == instance.definition_version)
                        .First();
                    if (def == null)
                        throw new Exception("流程定义版本不存在");

                    var graph = JObject.Parse(def.definition_json);
                    var formData = ParseFormData(instance.form_data_json);
                    var nextNode = ResolveNextExecutableNode(graph, task.node_id, formData);

                    if (nextNode == null || IsEndNode(nextNode))
                    {
                        MarkInstanceFinished(instance.id, req.Comment);
                        AddLog(instance.id, "approve", "审批通过，流程结束", userId, req.Comment);
                    }
                    else
                    {
                        CreatePendingTask(instance.id, nextNode);
                        UpdateInstanceCurrentNode(instance.id, nextNode["id"]?.ToString() ?? "", nextNode["text"]?.ToString() ?? "");
                        AddLog(instance.id, "approve", $"审批通过，流转到：{nextNode["text"]}", userId, req.Comment);
                    }
                }

                _db.Ado.CommitTran();
            }
            catch (Exception ex)
            {
                _db.Ado.RollbackTran();
                return Ok(new { code = 500, message = ex.Message });
            }

            return Ok(new { code = 0, message = "处理成功" });
        }

        private static bool CanOperateTask(string taskAssignee, string userId, string userName)
        {
            var assignee = (taskAssignee ?? "").Trim();
            if (assignee.Length == 0) return false;
            if (string.Equals(assignee, "待设置", StringComparison.Ordinal)) return false;
            if (string.Equals(assignee, (userId ?? "").Trim(), StringComparison.OrdinalIgnoreCase)) return true;
            if (string.Equals(assignee, (userName ?? "").Trim(), StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        private void EnsureWorkflowTables()
        {
            if (_tablesEnsured) return;
            lock (_tableLock)
            {
                if (_tablesEnsured) return;
                var sql = @"
IF OBJECT_ID('dbo.wf_definition','U') IS NULL
BEGIN
  CREATE TABLE dbo.wf_definition(
    process_code NVARCHAR(100) NOT NULL PRIMARY KEY,
    process_name NVARCHAR(200) NOT NULL,
    latest_version INT NOT NULL DEFAULT(1),
    published_version INT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT('draft'),
    updated_by NVARCHAR(100) NULL,
    updated_at DATETIME NOT NULL DEFAULT(GETDATE())
  );
END;
IF OBJECT_ID('dbo.wf_definition_version','U') IS NULL
BEGIN
  CREATE TABLE dbo.wf_definition_version(
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    process_code NVARCHAR(100) NOT NULL,
    process_name NVARCHAR(200) NOT NULL,
    version INT NOT NULL,
    status NVARCHAR(20) NOT NULL,
    definition_json NVARCHAR(MAX) NOT NULL,
    created_by NVARCHAR(100) NULL,
    created_at DATETIME NOT NULL DEFAULT(GETDATE()),
    published_by NVARCHAR(100) NULL,
    published_at DATETIME NULL
  );
  CREATE UNIQUE INDEX UX_wf_def_ver_code_ver ON dbo.wf_definition_version(process_code,version);
END;
IF OBJECT_ID('dbo.wf_instance','U') IS NULL
BEGIN
  CREATE TABLE dbo.wf_instance(
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    process_code NVARCHAR(100) NOT NULL,
    process_name NVARCHAR(200) NOT NULL,
    definition_version INT NOT NULL,
    business_key NVARCHAR(120) NULL,
    status NVARCHAR(20) NOT NULL,
    current_node_id NVARCHAR(100) NULL,
    current_node_name NVARCHAR(200) NULL,
    initiator NVARCHAR(100) NULL,
    form_data_json NVARCHAR(MAX) NULL,
    created_at DATETIME NOT NULL DEFAULT(GETDATE()),
    updated_at DATETIME NOT NULL DEFAULT(GETDATE())
  );
END;
IF OBJECT_ID('dbo.wf_task','U') IS NULL
BEGIN
  CREATE TABLE dbo.wf_task(
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    instance_id UNIQUEIDENTIFIER NOT NULL,
    node_id NVARCHAR(100) NOT NULL,
    node_name NVARCHAR(200) NOT NULL,
    assignee NVARCHAR(100) NULL,
    status NVARCHAR(20) NOT NULL,
    comment NVARCHAR(500) NULL,
    action_by NVARCHAR(100) NULL,
    action_time DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT(GETDATE())
  );
  CREATE INDEX IX_wf_task_instance ON dbo.wf_task(instance_id);
  CREATE INDEX IX_wf_task_assignee_status ON dbo.wf_task(assignee,status);
END;
IF OBJECT_ID('dbo.wf_instance_log','U') IS NULL
BEGIN
  CREATE TABLE dbo.wf_instance_log(
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    instance_id UNIQUEIDENTIFIER NOT NULL,
    action NVARCHAR(30) NOT NULL,
    message NVARCHAR(500) NULL,
    operator NVARCHAR(100) NULL,
    comment NVARCHAR(500) NULL,
    created_at DATETIME NOT NULL DEFAULT(GETDATE())
  );
  CREATE INDEX IX_wf_log_instance ON dbo.wf_instance_log(instance_id);
END;
IF OBJECT_ID('dbo.wf_form_binding','U') IS NULL
BEGIN
  CREATE TABLE dbo.wf_form_binding(
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    process_code NVARCHAR(100) NOT NULL,
    process_version INT NOT NULL,
    form_code NVARCHAR(120) NOT NULL,
    form_record_id UNIQUEIDENTIFIER NULL,
    workflow_definition_json NVARCHAR(MAX) NOT NULL,
    form_schema_json NVARCHAR(MAX) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT(GETDATE()),
    created_by NVARCHAR(100) NULL,
    updated_at DATETIME NOT NULL DEFAULT(GETDATE()),
    updated_by NVARCHAR(100) NULL
  );
  CREATE UNIQUE INDEX UX_wf_form_binding_process_ver ON dbo.wf_form_binding(process_code, process_version);
END;";
                _db.Ado.ExecuteCommand(sql);
                _tablesEnsured = true;
            }
        }

        private string CurrentUserId()
        {
            return User?.FindFirst("UserId")?.Value
                ?? User?.FindFirst("employee_id")?.Value
                ?? User?.Identity?.Name
                ?? "";
        }

        private JToken? FindStartNode(JObject graph)
        {
            var nodes = graph["graphData"]?["nodes"] as JArray ?? graph["nodes"] as JArray ?? new JArray();
            return nodes.FirstOrDefault(n => (n["properties"]?["bizType"]?.ToString() ?? "").Equals("start", StringComparison.OrdinalIgnoreCase))
                ?? nodes.FirstOrDefault();
        }

        private bool IsEndNode(JToken node)
        {
            return (node["properties"]?["bizType"]?.ToString() ?? "").Equals("end", StringComparison.OrdinalIgnoreCase);
        }

        private JToken? FindNextNode(JObject graph, string currentNodeId)
        {
            var root = graph["graphData"] as JObject ?? graph;
            var nodes = root["nodes"] as JArray ?? new JArray();
            var edges = root["edges"] as JArray ?? new JArray();

            var nextEdge = edges.FirstOrDefault(e => e["sourceNodeId"]?.ToString() == currentNodeId);
            var targetId = nextEdge?["targetNodeId"]?.ToString();
            if (string.IsNullOrWhiteSpace(targetId)) return null;
            return nodes.FirstOrDefault(n => n["id"]?.ToString() == targetId);
        }

        private JToken? ResolveNextExecutableNode(JObject graph, string fromNodeId, JObject formData)
        {
            var root = graph["graphData"] as JObject ?? graph;
            var nodes = root["nodes"] as JArray ?? new JArray();
            var currentId = fromNodeId;

            // 最多跳转 20 次，避免错误配置导致死循环
            for (var i = 0; i < 20; i++)
            {
                var nextNode = FindNextNodeByRule(root, nodes, currentId, formData);
                if (nextNode == null) return null;
                if (!IsConditionNode(nextNode)) return nextNode;
                currentId = nextNode["id"]?.ToString() ?? "";
                if (string.IsNullOrWhiteSpace(currentId)) return null;
            }
            return null;
        }

        private JToken? FindNextNodeByRule(JObject root, JArray nodes, string currentNodeId, JObject formData)
        {
            var edges = root["edges"] as JArray ?? new JArray();
            var candidates = edges
                .Where(e => e["sourceNodeId"]?.ToString() == currentNodeId)
                .OrderBy(e => e["properties"]?["priority"]?.Value<int?>() ?? 0)
                .ToList();

            foreach (var edge in candidates)
            {
                if (!EvaluateEdgeCondition(edge, formData)) continue;
                var targetId = edge["targetNodeId"]?.ToString();
                if (string.IsNullOrWhiteSpace(targetId)) continue;
                var target = nodes.FirstOrDefault(n => n["id"]?.ToString() == targetId);
                if (target != null) return target;
            }
            return null;
        }

        private bool IsConditionNode(JToken node)
        {
            return (node["properties"]?["bizType"]?.ToString() ?? "").Equals("condition", StringComparison.OrdinalIgnoreCase);
        }

        private JObject ParseFormData(string? json)
        {
            if (string.IsNullOrWhiteSpace(json)) return new JObject();
            try
            {
                var token = JToken.Parse(json);
                if (token is JObject obj) return obj;
                return new JObject();
            }
            catch
            {
                return new JObject();
            }
        }

        private bool EvaluateEdgeCondition(JToken edge, JObject formData)
        {
            var props = edge["properties"] as JObject;
            var anyOf = props?["ruleGroups"]?["anyOf"] as JArray;
            if (anyOf is { Count: > 0 })
            {
                foreach (var group in anyOf)
                {
                    var allOf = group["allOf"] as JArray;
                    if (allOf == null || allOf.Count == 0) continue;
                    var groupOk = true;
                    foreach (var rule in allOf)
                    {
                        if (EvaluateStructuredEdgeRule(rule, formData)) continue;
                        groupOk = false;
                        break;
                    }

                    if (groupOk) return true;
                }

                return false;
            }

            var rules = props?["rules"] as JArray;
            if (rules is { Count: > 0 })
            {
                foreach (var rule in rules)
                {
                    if (!EvaluateStructuredEdgeRule(rule, formData))
                        return false;
                }

                return true;
            }

            // 支持优先从 properties.condition 取，兼容 text/label 兜底
            var cond = edge["properties"]?["condition"]?.ToString()
                ?? edge["text"]?["value"]?.ToString()
                ?? edge["text"]?.ToString();

            if (string.IsNullOrWhiteSpace(cond)) return true;
            cond = cond.Trim();

            // true / false 常量
            if (bool.TryParse(cond, out var boolConst)) return boolConst;

            // 支持：a >= 100 / dept == "IT" / title contains "经理"
            var ops = new[] { ">=", "<=", "==", "!=", ">", "<", " contains ", " startsWith ", " endsWith " };
            foreach (var op in ops)
            {
                var idx = cond.IndexOf(op, StringComparison.Ordinal);
                if (idx <= 0) continue;

                var left = cond.Substring(0, idx).Trim();
                var right = cond.Substring(idx + op.Length).Trim().Trim('"', '\'');
                var actualToken = formData.SelectToken(left);
                var actual = actualToken?.ToString() ?? "";

                if (op.Trim() == "contains")
                    return actual.Contains(right, StringComparison.OrdinalIgnoreCase);
                if (op.Trim() == "startsWith")
                    return actual.StartsWith(right, StringComparison.OrdinalIgnoreCase);
                if (op.Trim() == "endsWith")
                    return actual.EndsWith(right, StringComparison.OrdinalIgnoreCase);

                if (decimal.TryParse(actual, out var lNum) && decimal.TryParse(right, out var rNum))
                {
                    return op switch
                    {
                        ">=" => lNum >= rNum,
                        "<=" => lNum <= rNum,
                        ">" => lNum > rNum,
                        "<" => lNum < rNum,
                        "==" => lNum == rNum,
                        "!=" => lNum != rNum,
                        _ => false
                    };
                }

                var compare = string.Compare(actual, right, StringComparison.OrdinalIgnoreCase);
                return op switch
                {
                    "==" => compare == 0,
                    "!=" => compare != 0,
                    ">=" => compare >= 0,
                    "<=" => compare <= 0,
                    ">" => compare > 0,
                    "<" => compare < 0,
                    _ => false
                };
            }

            // 无法解析条件时默认 false，避免误流转
            return false;
        }

        /// <summary>
        /// 设计器写入的 properties.rules：单条 scope=key op value；发起流程时请在 formData 中带 $initiator。
        /// </summary>
        private static bool EvaluateStructuredEdgeRule(JToken rule, JObject formData)
        {
            var scope = rule["scope"]?.ToString() ?? "form";
            var key = rule["key"]?.ToString() ?? "";
            var op = rule["op"]?.ToString() ?? "==";
            if (string.IsNullOrWhiteSpace(key)) return false;

            var expected = rule["value"];

            JToken? actual = null;
            if (scope.Equals("form", StringComparison.OrdinalIgnoreCase))
                actual = formData.SelectToken(key);
            else if (scope.Equals("initiator", StringComparison.OrdinalIgnoreCase))
            {
                if (formData["$initiator"] is not JObject ini) return false;
                actual = ini.SelectToken(key);
            }
            else return false;

            return CompareRuleValue(actual, op, expected);
        }

        private static bool CompareRuleValue(JToken? actual, string op, JToken? expected)
        {
            var actualStr = actual?.Type == JTokenType.Null ? "" : actual?.ToString() ?? "";

            switch (op)
            {
                case "in":
                case "notIn":
                    if (expected is not JArray arr)
                        return op == "in" ? false : true;
                    var set = new HashSet<string>(arr.Select(x => x.ToString()), StringComparer.OrdinalIgnoreCase);
                    var hit = set.Contains(actualStr);
                    return op == "in" ? hit : !hit;

                case "containsAny":
                    if (actual is not JArray aList || expected is not JArray eList) return false;
                    var aSet = new HashSet<string>(aList.Select(x => x.ToString()), StringComparer.OrdinalIgnoreCase);
                    return eList.Any(x => aSet.Contains(x.ToString()));

                case "contains":
                    return actualStr.Contains(expected?.ToString() ?? "", StringComparison.OrdinalIgnoreCase);
                case "startsWith":
                    return actualStr.StartsWith(expected?.ToString() ?? "", StringComparison.OrdinalIgnoreCase);
                case "endsWith":
                    return actualStr.EndsWith(expected?.ToString() ?? "", StringComparison.OrdinalIgnoreCase);
            }

            var rightRaw = expected?.ToString() ?? "";

            if (decimal.TryParse(actualStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var lNum)
                && decimal.TryParse(rightRaw, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var rNum))
            {
                return op switch
                {
                    ">=" => lNum >= rNum,
                    "<=" => lNum <= rNum,
                    ">" => lNum > rNum,
                    "<" => lNum < rNum,
                    "==" => lNum == rNum,
                    "!=" => lNum != rNum,
                    _ => false
                };
            }

            var compare = string.Compare(actualStr, rightRaw, StringComparison.OrdinalIgnoreCase);
            return op switch
            {
                "==" => compare == 0,
                "!=" => compare != 0,
                ">=" => compare >= 0,
                "<=" => compare <= 0,
                ">" => compare > 0,
                "<" => compare < 0,
                _ => false
            };
        }

        private void CreatePendingTask(Guid instanceId, JToken node)
        {
            _db.Insertable(new wf_task
            {
                id = Guid.NewGuid(),
                instance_id = instanceId,
                node_id = node["id"]?.ToString() ?? "",
                node_name = node["text"]?.ToString() ?? "未命名节点",
                assignee = node["properties"]?["assignee"]?.ToString() ?? "待设置",
                status = "pending",
                created_at = DateTime.Now
            }).ExecuteCommand();
        }

        private void MarkInstanceFinished(Guid instanceId, string? comment)
        {
            _db.Updateable<wf_instance>()
                .SetColumns(x => x.status == "finished")
                .SetColumns(x => x.current_node_id == "")
                .SetColumns(x => x.current_node_name == "")
                .SetColumns(x => x.updated_at == DateTime.Now)
                .Where(x => x.id == instanceId)
                .ExecuteCommand();
            AddLog(instanceId, "finish", "流程结束", CurrentUserId(), comment);
        }

        private void UpdateInstanceCurrentNode(Guid instanceId, string nodeId, string nodeName)
        {
            _db.Updateable<wf_instance>()
                .SetColumns(x => x.current_node_id == nodeId)
                .SetColumns(x => x.current_node_name == nodeName)
                .SetColumns(x => x.updated_at == DateTime.Now)
                .Where(x => x.id == instanceId)
                .ExecuteCommand();
        }

        private void AddLog(Guid instanceId, string action, string message, string? op, string? comment)
        {
            _db.Insertable(new wf_instance_log
            {
                id = Guid.NewGuid(),
                instance_id = instanceId,
                action = action,
                message = message,
                @operator = op,
                comment = comment,
                created_at = DateTime.Now
            }).ExecuteCommand();
        }
    }

    public class SaveWorkflowDefinitionRequest
    {
        public string ProcessCode { get; set; } = "";
        public string ProcessName { get; set; } = "";
        public string DefinitionJson { get; set; } = "";
    }

    public class PublishWorkflowDefinitionRequest
    {
        public string ProcessCode { get; set; } = "";
        public int? Version { get; set; }
    }

    public class StartWorkflowInstanceRequest
    {
        public string ProcessCode { get; set; } = "";
        public string? BusinessKey { get; set; }
        public string? FormDataJson { get; set; }
        public string? Comment { get; set; }
    }

    public class ActionTaskRequest
    {
        public Guid TaskId { get; set; }
        public string? Comment { get; set; }
    }

    public class SaveWorkflowFormBindingRequest
    {
        public string ProcessCode { get; set; } = "";
        public int ProcessVersion { get; set; }
        public string FormCode { get; set; } = "";
        public Guid? FormRecordId { get; set; }
    }

    [SugarTable("wf_definition")]
    public class wf_definition
    {
        [SugarColumn(IsPrimaryKey = true, ColumnName = "process_code")]
        public string process_code { get; set; } = "";
        public string process_name { get; set; } = "";
        public int latest_version { get; set; }
        public int? published_version { get; set; }
        public string status { get; set; } = "";
        public string? updated_by { get; set; }
        public DateTime updated_at { get; set; }
    }

    [SugarTable("wf_definition_version")]
    public class wf_definition_version
    {
        [SugarColumn(IsPrimaryKey = true)]
        public Guid id { get; set; }
        public string process_code { get; set; } = "";
        public string process_name { get; set; } = "";
        public int version { get; set; }
        public string status { get; set; } = "";
        public string definition_json { get; set; } = "";
        public string? created_by { get; set; }
        public DateTime created_at { get; set; }
        public string? published_by { get; set; }
        public DateTime? published_at { get; set; }
    }

    [SugarTable("wf_instance")]
    public class wf_instance
    {
        [SugarColumn(IsPrimaryKey = true)]
        public Guid id { get; set; }
        public string process_code { get; set; } = "";
        public string process_name { get; set; } = "";
        public int definition_version { get; set; }
        public string? business_key { get; set; }
        public string status { get; set; } = "";
        public string? current_node_id { get; set; }
        public string? current_node_name { get; set; }
        public string? initiator { get; set; }
        public string? form_data_json { get; set; }
        public DateTime created_at { get; set; }
        public DateTime updated_at { get; set; }
    }

    [SugarTable("wf_task")]
    public class wf_task
    {
        [SugarColumn(IsPrimaryKey = true)]
        public Guid id { get; set; }
        public Guid instance_id { get; set; }
        public string node_id { get; set; } = "";
        public string node_name { get; set; } = "";
        public string? assignee { get; set; }
        public string status { get; set; } = "";
        public string? comment { get; set; }
        public string? action_by { get; set; }
        public DateTime? action_time { get; set; }
        public DateTime created_at { get; set; }
    }

    [SugarTable("wf_instance_log")]
    public class wf_instance_log
    {
        [SugarColumn(IsPrimaryKey = true)]
        public Guid id { get; set; }
        public Guid instance_id { get; set; }
        public string action { get; set; } = "";
        public string? message { get; set; }
        public string? @operator { get; set; }
        public string? comment { get; set; }
        public DateTime created_at { get; set; }
    }

    [SugarTable("wf_form_binding")]
    public class wf_form_binding
    {
        [SugarColumn(IsPrimaryKey = true)]
        public Guid id { get; set; }
        public string process_code { get; set; } = "";
        public int process_version { get; set; }
        public string form_code { get; set; } = "";
        public Guid? form_record_id { get; set; }
        public string workflow_definition_json { get; set; } = "";
        public string form_schema_json { get; set; } = "";
        public DateTime created_at { get; set; }
        public string? created_by { get; set; }
        public DateTime updated_at { get; set; }
        public string? updated_by { get; set; }
    }
}
