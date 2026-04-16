using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SqlSugar;

namespace StoneApi.WorkflowEngine;

/// <summary>
/// 1020 流程定义层：目录 + wf_process_def / wf_process_def_ver / wf_node_def / wf_edge_def
/// 路由前缀：/api/workflow-engine/process/...
/// </summary>
[ApiController]
[Authorize]
[Route("api/workflow-engine")]
public class WorkflowEngineProcessController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public WorkflowEngineProcessController(SqlSugarClient db)
    {
        _db = db;
    }

    private string CurrentUserId() =>
        User?.FindFirst("UserId")?.Value
        ?? User?.FindFirst("employee_id")?.Value
        ?? User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User?.Identity?.Name
        ?? "";

    /// <summary>左侧树：目录 + 流程叶子</summary>
    [HttpGet("tree")]
    public IActionResult GetTree()
    {
        var cats = _db.Queryable<wf_process_category>()
            .Where(c => c.status == 1)
            .OrderBy("parent_id asc, sort_no asc, id asc")
            .ToList();

        var defs = _db.Queryable<wf_process_def>()
            .OrderBy(d => d.process_name)
            .ToList();

        return Ok(new
        {
            code = 0,
            data = new
            {
                categories = cats.Select(c => new
                {
                    id = c.id,
                    parentId = c.parent_id,
                    folderCode = c.folder_code,
                    name = c.name,
                    sortNo = c.sort_no,
                    status = c.status
                }).ToList(),
                processes = defs.Select(d => new
                {
                    id = d.id,
                    categoryId = d.category_id,
                    processCode = d.process_code,
                    processName = d.process_name,
                    status = d.status,
                    latestVersion = d.latest_version
                }).ToList()
            }
        });
    }

    /// <summary>取流程定义 + 最新一条版本（含 definition_json 字符串）</summary>
    [HttpGet("process/{processDefId:guid}")]
    public IActionResult GetProcess(Guid processDefId)
    {
        var def = _db.Queryable<wf_process_def>().InSingle(processDefId);
        if (def == null)
            return Ok(new { code = 404, message = "流程不存在" });

        var ver = _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == processDefId)
            .OrderBy(v => v.version_no, OrderByType.Desc)
            .First();

        return Ok(new
        {
            code = 0,
            data = new
            {
                processDef = new
                {
                    id = def.id,
                    processCode = def.process_code,
                    processName = def.process_name,
                    categoryId = def.category_id,
                    categoryCode = def.category_code,
                    status = def.status,
                    latestVersion = def.latest_version,
                    updatedAt = def.updated_at
                },
                version = ver == null
                    ? null
                    : new
                    {
                        id = ver.id,
                        versionNo = ver.version_no,
                        isPublished = ver.is_published,
                        publishedAt = ver.published_at,
                        definitionJson = ver.definition_json,
                        engineModelJson = ver.engine_model_json,
                        createdAt = ver.created_at
                    }
            }
        });
    }

    public class CreateProcessRequest
    {
        public string ProcessCode { get; set; } = "";
        public string ProcessName { get; set; } = "";
        public Guid? CategoryId { get; set; }
    }

    [HttpPost("process/create")]
    public IActionResult CreateProcess([FromBody] CreateProcessRequest req)
    {
        var code = (req.ProcessCode ?? "").Trim();
        var name = (req.ProcessName ?? "").Trim();
        if (code.Length == 0 || name.Length == 0)
            return Ok(new { code = 400, message = "processCode/processName 不能为空" });

        if (_db.Queryable<wf_process_def>().Any(d => d.process_code == code))
            return Ok(new { code = 409, message = "流程编码已存在" });

        if (req.CategoryId != null &&
            !_db.Queryable<wf_process_category>().Any(c => c.id == req.CategoryId.Value))
            return Ok(new { code = 400, message = "categoryId 无效" });

        var now = DateTime.Now;
        var uid = CurrentUserId();
        var id = Guid.NewGuid();

        var row = new wf_process_def
        {
            id = id,
            process_code = code,
            process_name = name,
            category_id = req.CategoryId,
            category_code = null,
            status = 0,
            latest_version = 0,
            created_by = uid,
            created_at = now,
            updated_by = uid,
            updated_at = now
        };
        _db.Insertable(row).ExecuteCommand();

        return Ok(new { code = 0, data = new { processDefId = id } });
    }

    public class SaveProcessDefinitionRequest
    {
        /// <summary>必填，对应 wf_process_def.id</summary>
        public Guid ProcessDefId { get; set; }
        public string ProcessName { get; set; } = "";
        public Guid? CategoryId { get; set; }
        /// <summary>与静态页 wfMeta 一致的可选扩展</summary>
        public string? InitiatorScope { get; set; }
        public string? Remark { get; set; }
        /// <summary>设计器 getWorkflowDraftSnapshot 整包 JSON（对象）</summary>
        public JsonElement? Definition { get; set; }
    }

    [HttpPost("process/save")]
    public IActionResult SaveProcess([FromBody] SaveProcessDefinitionRequest req)
    {
        var uid = CurrentUserId();
        var now = DateTime.Now;

        if (req.ProcessDefId == Guid.Empty)
            return Ok(new { code = 400, message = "processDefId 不能为空" });

        var def = _db.Queryable<wf_process_def>().InSingle(req.ProcessDefId);
        if (def == null)
            return Ok(new { code = 404, message = "流程不存在" });

        var name = (req.ProcessName ?? "").Trim();
        if (name.Length == 0)
            return Ok(new { code = 400, message = "processName 不能为空" });

        if (req.CategoryId != null &&
            !_db.Queryable<wf_process_category>().Any(c => c.id == req.CategoryId.Value))
            return Ok(new { code = 400, message = "categoryId 无效" });

        JObject definitionObj;
        if (req.Definition == null || req.Definition.Value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
            definitionObj = new JObject();
        else
            definitionObj = JObject.Parse(req.Definition.Value.GetRawText());
        // 顶层与基础信息对齐
        definitionObj["processCode"] = def.process_code;
        definitionObj["processName"] = name;
        if (!string.IsNullOrWhiteSpace(req.InitiatorScope))
            definitionObj["initiatorScope"] = req.InitiatorScope;
        if (!string.IsNullOrWhiteSpace(req.Remark))
            definitionObj["remark"] = req.Remark;

        var definitionJson = definitionObj.ToString(Formatting.None);
        var engineToken = definitionObj["engineModel"];
        var engineModelJson = engineToken == null || !engineToken.HasValues
            ? null
            : engineToken.ToString(Formatting.None);

        var lastVer = _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == def.id)
            .OrderBy(v => v.version_no, OrderByType.Desc)
            .First();
        var nextNo = (lastVer?.version_no ?? 0) + 1;

        var verId = Guid.NewGuid();
        var verRow = new wf_process_def_ver
        {
            id = verId,
            process_def_id = def.id,
            version_no = nextNo,
            is_published = false,
            published_at = null,
            definition_json = definitionJson,
            engine_model_json = engineModelJson,
            checksum = null,
            created_by = uid,
            created_at = now
        };

        _db.Ado.BeginTran();
        try
        {
            _db.Insertable(verRow).ExecuteCommand();

            var newCat = req.CategoryId ?? def.category_id;
            _db.Updateable<wf_process_def>()
                .SetColumns(d => d.process_name == name)
                .SetColumns(d => d.category_id == newCat)
                .SetColumns(d => d.latest_version == nextNo)
                .SetColumns(d => d.updated_at == now)
                .SetColumns(d => d.updated_by == uid)
                .Where(d => d.id == def.id)
                .ExecuteCommand();

            SyncNodeEdgeFromDefinition(verId, definitionObj);

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
                processDefId = def.id,
                versionId = verId,
                versionNo = nextNo
            }
        });
    }

    public class PublishRequest
    {
        public Guid ProcessDefId { get; set; }
        public int VersionNo { get; set; }
    }

    [HttpPost("process/publish")]
    public IActionResult Publish([FromBody] PublishRequest req)
    {
        var uid = CurrentUserId();
        var now = DateTime.Now;

        var ver = _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == req.ProcessDefId && v.version_no == req.VersionNo)
            .First();
        if (ver == null)
            return Ok(new { code = 404, message = "版本不存在" });

        _db.Ado.BeginTran();
        try
        {
            _db.Updateable<wf_process_def_ver>()
                .SetColumns(v => v.is_published == false)
                .Where(v => v.process_def_id == req.ProcessDefId)
                .ExecuteCommand();

            _db.Updateable<wf_process_def_ver>()
                .SetColumns(v => v.is_published == true)
                .SetColumns(v => v.published_at == now)
                .Where(v => v.id == ver.id)
                .ExecuteCommand();

            _db.Updateable<wf_process_def>()
                .SetColumns(d => d.status == (byte)1)
                .SetColumns(d => d.updated_at == now)
                .SetColumns(d => d.updated_by == uid)
                .Where(d => d.id == req.ProcessDefId)
                .ExecuteCommand();

            _db.Ado.CommitTran();
        }
        catch (Exception ex)
        {
            _db.Ado.RollbackTran();
            return Ok(new { code = 500, message = ex.Message });
        }

        return Ok(new { code = 0, data = new { processDefId = req.ProcessDefId, versionNo = req.VersionNo } });
    }

    public class CreateCategoryRequest
    {
        public Guid? ParentId { get; set; }
        public string Name { get; set; } = "";
        public string? FolderCode { get; set; }
        public int? SortNo { get; set; }
    }

    [HttpPost("category/create")]
    public IActionResult CreateCategory([FromBody] CreateCategoryRequest req)
    {
        var name = (req.Name ?? "").Trim();
        if (name.Length == 0)
            return Ok(new { code = 400, message = "name 不能为空" });
        if (req.ParentId != null &&
            !_db.Queryable<wf_process_category>().Any(c => c.id == req.ParentId.Value))
            return Ok(new { code = 400, message = "parentId 无效" });

        var folderCode = (req.FolderCode ?? "").Trim();
        if (folderCode.Length == 0)
            folderCode = "CAT_" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();

        if (_db.Queryable<wf_process_category>().Any(c =>
                c.parent_id == req.ParentId && c.folder_code == folderCode))
            return Ok(new { code = 409, message = "同级目录下 folderCode 已存在" });

        var now = DateTime.Now;
        var uid = CurrentUserId();
        var id = Guid.NewGuid();
        _db.Insertable(new wf_process_category
        {
            id = id,
            parent_id = req.ParentId,
            folder_code = folderCode,
            name = name,
            sort_no = req.SortNo ?? 0,
            status = 1,
            remark = null,
            created_by = uid,
            created_at = now,
            updated_by = uid,
            updated_at = now
        }).ExecuteCommand();

        return Ok(new { code = 0, data = new { categoryId = id } });
    }

    public class UpdateCategoryRequest
    {
        public Guid CategoryId { get; set; }
        public string Name { get; set; } = "";
        public string? FolderCode { get; set; }
        public int? SortNo { get; set; }
    }

    [HttpPost("category/update")]
    public IActionResult UpdateCategory([FromBody] UpdateCategoryRequest req)
    {
        var cat = _db.Queryable<wf_process_category>().InSingle(req.CategoryId);
        if (cat == null)
            return Ok(new { code = 404, message = "目录不存在" });
        var name = (req.Name ?? "").Trim();
        if (name.Length == 0)
            return Ok(new { code = 400, message = "name 不能为空" });

        var folderCode = (req.FolderCode ?? "").Trim();
        if (folderCode.Length == 0)
            folderCode = (cat.folder_code ?? "").Trim();
        if (folderCode.Length == 0)
            folderCode = "CAT_" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();

        if (_db.Queryable<wf_process_category>().Any(c =>
                c.id != req.CategoryId && c.parent_id == cat.parent_id && c.folder_code == folderCode))
            return Ok(new { code = 409, message = "同级目录下 folderCode 已存在" });

        var now = DateTime.Now;
        var uid = CurrentUserId();
        _db.Updateable<wf_process_category>()
            .SetColumns(c => c.name == name)
            .SetColumns(c => c.folder_code == folderCode)
            .SetColumns(c => c.sort_no == (req.SortNo ?? cat.sort_no))
            .SetColumns(c => c.updated_at == now)
            .SetColumns(c => c.updated_by == uid)
            .Where(c => c.id == req.CategoryId)
            .ExecuteCommand();

        return Ok(new { code = 0, data = new { categoryId = req.CategoryId } });
    }

    public class DeleteCategoryRequest
    {
        public Guid CategoryId { get; set; }
    }

    [HttpPost("category/delete")]
    public IActionResult DeleteCategory([FromBody] DeleteCategoryRequest req)
    {
        if (_db.Queryable<wf_process_category>().Any(c => c.parent_id == req.CategoryId))
            return Ok(new { code = 409, message = "存在子目录，无法删除" });
        if (_db.Queryable<wf_process_def>().Any(d => d.category_id == req.CategoryId))
            return Ok(new { code = 409, message = "目录下存在流程，无法删除" });
        var n = _db.Deleteable<wf_process_category>().Where(c => c.id == req.CategoryId).ExecuteCommand();
        if (n == 0)
            return Ok(new { code = 404, message = "目录不存在" });
        return Ok(new { code = 0, data = new { } });
    }

    public class UpdateProcessMetaRequest
    {
        public Guid ProcessDefId { get; set; }
        public string ProcessName { get; set; } = "";
        public Guid? CategoryId { get; set; }
    }

    [HttpPost("process/update-meta")]
    public IActionResult UpdateProcessMeta([FromBody] UpdateProcessMetaRequest req)
    {
        var def = _db.Queryable<wf_process_def>().InSingle(req.ProcessDefId);
        if (def == null)
            return Ok(new { code = 404, message = "流程不存在" });
        var name = (req.ProcessName ?? "").Trim();
        if (name.Length == 0)
            return Ok(new { code = 400, message = "processName 不能为空" });
        if (req.CategoryId != null &&
            !_db.Queryable<wf_process_category>().Any(c => c.id == req.CategoryId.Value))
            return Ok(new { code = 400, message = "categoryId 无效" });

        var now = DateTime.Now;
        var uid = CurrentUserId();
        _db.Updateable<wf_process_def>()
            .SetColumns(d => d.process_name == name)
            .SetColumns(d => d.category_id == req.CategoryId)
            .SetColumns(d => d.updated_at == now)
            .SetColumns(d => d.updated_by == uid)
            .Where(d => d.id == req.ProcessDefId)
            .ExecuteCommand();

        return Ok(new { code = 0, data = new { processDefId = req.ProcessDefId } });
    }

    public class DeleteProcessRequest
    {
        public Guid ProcessDefId { get; set; }
    }

    [HttpPost("process/delete")]
    public IActionResult DeleteProcess([FromBody] DeleteProcessRequest req)
    {
        try
        {
            var instCount = Convert.ToInt32(
                _db.Ado.GetScalar(
                    "SELECT COUNT(1) FROM dbo.wf_instance WHERE process_def_id = @pid",
                    new SugarParameter("@pid", req.ProcessDefId)) ?? 0);
            if (instCount > 0)
                return Ok(new { code = 409, message = "该流程已存在运行实例，无法删除" });
        }
        catch
        {
            // 若库中尚无新引擎 wf_instance.process_def_id 列，则跳过实例校验
        }

        var def = _db.Queryable<wf_process_def>().InSingle(req.ProcessDefId);
        if (def == null)
            return Ok(new { code = 404, message = "流程不存在" });

        var verIds = _db.Queryable<wf_process_def_ver>()
            .Where(v => v.process_def_id == req.ProcessDefId)
            .Select(v => v.id)
            .ToList();

        _db.Ado.BeginTran();
        try
        {
            if (verIds.Count > 0)
            {
                _db.Deleteable<wf_edge_def>().Where(e => verIds.Contains(e.process_def_ver_id)).ExecuteCommand();
                _db.Deleteable<wf_node_def>().Where(n => verIds.Contains(n.process_def_ver_id)).ExecuteCommand();
                _db.Deleteable<wf_process_def_ver>().Where(v => v.process_def_id == req.ProcessDefId)
                    .ExecuteCommand();
            }

            _db.Deleteable<wf_process_def>().Where(d => d.id == req.ProcessDefId).ExecuteCommand();
            _db.Ado.CommitTran();
        }
        catch (Exception ex)
        {
            _db.Ado.RollbackTran();
            return Ok(new { code = 500, message = ex.Message });
        }

        return Ok(new { code = 0, data = new { } });
    }

    /// <summary>演示：人事/行政目录 + 三个空流程（无版本行，保存后才有）</summary>
    [HttpPost("seed/demo-tree")]
    public IActionResult SeedDemoTree()
    {
        if (_db.Queryable<wf_process_category>().Any())
            return Ok(new { code = 0, message = "已有目录数据，跳过", data = new { skipped = true } });

        var now = DateTime.Now;
        var uid = CurrentUserId();

        var catHr = Guid.NewGuid();
        var catAdm = Guid.NewGuid();
        _db.Insertable(new wf_process_category
        {
            id = catHr,
            parent_id = null,
            folder_code = "CAT_HR",
            name = "人事流程",
            sort_no = 0,
            status = 1,
            remark = null,
            created_by = uid,
            created_at = now,
            updated_by = uid,
            updated_at = now
        }).ExecuteCommand();

        _db.Insertable(new wf_process_category
        {
            id = catAdm,
            parent_id = null,
            folder_code = "CAT_ADMIN",
            name = "行政流程",
            sort_no = 1,
            status = 1,
            remark = null,
            created_by = uid,
            created_at = now,
            updated_by = uid,
            updated_at = now
        }).ExecuteCommand();

        void InsProc(Guid id, string code, string name, Guid cat)
        {
            _db.Insertable(new wf_process_def
            {
                id = id,
                process_code = code,
                process_name = name,
                category_id = cat,
                category_code = null,
                status = 0,
                latest_version = 0,
                created_by = uid,
                created_at = now,
                updated_by = uid,
                updated_at = now
            }).ExecuteCommand();
        }

        InsProc(Guid.NewGuid(), "HR_LEAVE", "请假流程", catHr);
        InsProc(Guid.NewGuid(), "HR_OT", "加班流程", catHr);
        InsProc(Guid.NewGuid(), "ADM_CAR", "用车申请", catAdm);

        return Ok(new { code = 0, data = new { skipped = false } });
    }

    private void SyncNodeEdgeFromDefinition(Guid processDefVerId, JObject definitionObj)
    {
        _db.Deleteable<wf_node_def>().Where(n => n.process_def_ver_id == processDefVerId).ExecuteCommand();
        _db.Deleteable<wf_edge_def>().Where(e => e.process_def_ver_id == processDefVerId).ExecuteCommand();

        var graph = definitionObj["graphData"] as JObject
                    ?? definitionObj["graph"] as JObject;
        var nodes = graph?["nodes"] as JArray ?? new JArray();
        var edges = graph?["edges"] as JArray ?? new JArray();
        var now = DateTime.Now;

        foreach (var n in nodes)
        {
            var jo = n as JObject;
            if (jo == null) continue;
            var nodeId = jo["id"]?.ToString() ?? "";
            if (string.IsNullOrWhiteSpace(nodeId)) continue;

            var textVal = jo["text"]?["value"]?.ToString() ?? jo["text"]?.ToString() ?? "";
            var props = jo["properties"] as JObject ?? new JObject();
            var biz = props["bizType"]?.ToString()?.Trim().ToLowerInvariant() ?? "";
            var nodeType = biz switch
            {
                "start" => "start",
                "end" => "end",
                "condition" => "condition",
                "cc" => "cc",
                _ => "approve"
            };

            string? assigneeJson = props.Count > 0 ? props.ToString(Formatting.None) : null;

            var fb = props["formBinding"] as JObject;
            var formCode = fb?["formCode"]?.ToString();
            var formName = fb?["formName"]?.ToString();
            string? fieldRules = null;
            if (props["fieldRules"] != null)
                fieldRules = props["fieldRules"]!.ToString(Formatting.None);

            _db.Insertable(new wf_node_def
            {
                id = Guid.NewGuid(),
                process_def_ver_id = processDefVerId,
                node_id = nodeId,
                node_name = string.IsNullOrWhiteSpace(textVal) ? nodeId : textVal,
                node_type = nodeType,
                assignee_rule_json = assigneeJson,
                form_code = string.IsNullOrWhiteSpace(formCode) ? null : formCode,
                form_name = string.IsNullOrWhiteSpace(formName) ? null : formName,
                field_rules_json = fieldRules,
                created_at = now
            }).ExecuteCommand();
        }

        foreach (var e in edges)
        {
            var jo = e as JObject;
            if (jo == null) continue;
            var edgeId = jo["id"]?.ToString() ?? Guid.NewGuid().ToString("N");
            var src = jo["sourceNodeId"]?.ToString() ?? "";
            var tgt = jo["targetNodeId"]?.ToString() ?? "";
            var prio = jo["properties"]?["priority"]?.Value<int?>() ?? 100;
            var ruleJson = jo["properties"] != null
                ? jo["properties"]!.ToString(Formatting.None)
                : null;

            _db.Insertable(new wf_edge_def
            {
                id = Guid.NewGuid(),
                process_def_ver_id = processDefVerId,
                edge_id = edgeId,
                source_node_id = src,
                target_node_id = tgt,
                priority = prio,
                rule_json = ruleJson,
                created_at = now
            }).ExecuteCommand();
        }
    }
}
