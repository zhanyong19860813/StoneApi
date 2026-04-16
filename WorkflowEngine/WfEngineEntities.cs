using SqlSugar;

namespace StoneApi.WorkflowEngine;

[SugarTable("wf_process_category")]
public class wf_process_category
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "parent_id", IsNullable = true)]
    public Guid? parent_id { get; set; }

    [SugarColumn(ColumnName = "folder_code", IsNullable = true)]
    public string? folder_code { get; set; }

    public string name { get; set; } = "";

    [SugarColumn(ColumnName = "sort_no")]
    public int sort_no { get; set; }

    public byte status { get; set; } = 1;

    [SugarColumn(IsNullable = true)]
    public string? remark { get; set; }

    [SugarColumn(IsNullable = true)]
    public string? created_by { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }

    [SugarColumn(IsNullable = true)]
    public string? updated_by { get; set; }

    [SugarColumn(ColumnName = "updated_at")]
    public DateTime updated_at { get; set; }
}

[SugarTable("wf_process_def")]
public class wf_process_def
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "process_code")]
    public string process_code { get; set; } = "";

    [SugarColumn(ColumnName = "process_name")]
    public string process_name { get; set; } = "";

    [SugarColumn(ColumnName = "category_id", IsNullable = true)]
    public Guid? category_id { get; set; }

    [SugarColumn(ColumnName = "category_code", IsNullable = true)]
    public string? category_code { get; set; }

    public byte status { get; set; }

    [SugarColumn(ColumnName = "latest_version")]
    public int latest_version { get; set; } = 1;

    [SugarColumn(IsNullable = true)]
    public string? created_by { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }

    [SugarColumn(IsNullable = true)]
    public string? updated_by { get; set; }

    [SugarColumn(ColumnName = "updated_at")]
    public DateTime updated_at { get; set; }
}

[SugarTable("wf_process_def_ver")]
public class wf_process_def_ver
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "process_def_id")]
    public Guid process_def_id { get; set; }

    [SugarColumn(ColumnName = "version_no")]
    public int version_no { get; set; }

    [SugarColumn(ColumnName = "is_published")]
    public bool is_published { get; set; }

    [SugarColumn(ColumnName = "published_at", IsNullable = true)]
    public DateTime? published_at { get; set; }

    [SugarColumn(ColumnName = "definition_json")]
    public string definition_json { get; set; } = "";

    [SugarColumn(ColumnName = "engine_model_json", IsNullable = true)]
    public string? engine_model_json { get; set; }

    [SugarColumn(ColumnName = "checksum", IsNullable = true)]
    public string? checksum { get; set; }

    [SugarColumn(IsNullable = true)]
    public string? created_by { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }
}

[SugarTable("wf_node_def")]
public class wf_node_def
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "process_def_ver_id")]
    public Guid process_def_ver_id { get; set; }

    [SugarColumn(ColumnName = "node_id")]
    public string node_id { get; set; } = "";

    [SugarColumn(ColumnName = "node_name", IsNullable = true)]
    public string? node_name { get; set; }

    [SugarColumn(ColumnName = "node_type")]
    public string node_type { get; set; } = "";

    [SugarColumn(ColumnName = "assignee_rule_json", IsNullable = true)]
    public string? assignee_rule_json { get; set; }

    [SugarColumn(ColumnName = "form_code", IsNullable = true)]
    public string? form_code { get; set; }

    [SugarColumn(ColumnName = "form_name", IsNullable = true)]
    public string? form_name { get; set; }

    [SugarColumn(ColumnName = "field_rules_json", IsNullable = true)]
    public string? field_rules_json { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }
}

[SugarTable("wf_edge_def")]
public class wf_edge_def
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "process_def_ver_id")]
    public Guid process_def_ver_id { get; set; }

    [SugarColumn(ColumnName = "edge_id")]
    public string edge_id { get; set; } = "";

    [SugarColumn(ColumnName = "source_node_id")]
    public string source_node_id { get; set; } = "";

    [SugarColumn(ColumnName = "target_node_id")]
    public string target_node_id { get; set; } = "";

    [SugarColumn(ColumnName = "priority")]
    public int priority { get; set; } = 100;

    [SugarColumn(ColumnName = "rule_json", IsNullable = true)]
    public string? rule_json { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }
}

[SugarTable("wf_instance")]
public class wf_instance
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "instance_no")]
    public string instance_no { get; set; } = "";

    [SugarColumn(ColumnName = "process_def_id")]
    public Guid process_def_id { get; set; }

    [SugarColumn(ColumnName = "process_def_ver_id")]
    public Guid process_def_ver_id { get; set; }

    [SugarColumn(ColumnName = "business_key", IsNullable = true)]
    public string? business_key { get; set; }

    [SugarColumn(IsNullable = true)]
    public string? title { get; set; }

    [SugarColumn(ColumnName = "starter_user_id")]
    public string starter_user_id { get; set; } = "";

    [SugarColumn(ColumnName = "starter_dept_id", IsNullable = true)]
    public string? starter_dept_id { get; set; }

    public byte status { get; set; } = 0;

    [SugarColumn(ColumnName = "current_node_ids", IsNullable = true)]
    public string? current_node_ids { get; set; }

    [SugarColumn(ColumnName = "started_at")]
    public DateTime started_at { get; set; }

    [SugarColumn(ColumnName = "ended_at", IsNullable = true)]
    public DateTime? ended_at { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }

    [SugarColumn(ColumnName = "updated_at")]
    public DateTime updated_at { get; set; }
}

[SugarTable("wf_instance_data")]
public class wf_instance_data
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "instance_id")]
    public Guid instance_id { get; set; }

    [SugarColumn(ColumnName = "node_id")]
    public string node_id { get; set; } = "";

    [SugarColumn(ColumnName = "form_code", IsNullable = true)]
    public string? form_code { get; set; }

    [SugarColumn(ColumnName = "main_form_json", IsNullable = true)]
    public string? main_form_json { get; set; }

    [SugarColumn(ColumnName = "tabs_data_json", IsNullable = true)]
    public string? tabs_data_json { get; set; }

    [SugarColumn(ColumnName = "snapshot_at")]
    public DateTime snapshot_at { get; set; }

    [SugarColumn(ColumnName = "operator_user_id", IsNullable = true)]
    public string? operator_user_id { get; set; }
}

[SugarTable("wf_task")]
public class wf_task
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "task_no")]
    public string task_no { get; set; } = "";

    [SugarColumn(ColumnName = "instance_id")]
    public Guid instance_id { get; set; }

    [SugarColumn(ColumnName = "node_id")]
    public string node_id { get; set; } = "";

    [SugarColumn(ColumnName = "node_name")]
    public string node_name { get; set; } = "";

    [SugarColumn(ColumnName = "assignee_user_id")]
    public string assignee_user_id { get; set; } = "";

    [SugarColumn(ColumnName = "assignee_name", IsNullable = true)]
    public string? assignee_name { get; set; }

    [SugarColumn(ColumnName = "task_type")]
    public byte task_type { get; set; } = 1;

    public byte status { get; set; } = 0;

    [SugarColumn(ColumnName = "sign_mode", IsNullable = true)]
    public string? sign_mode { get; set; }

    [SugarColumn(ColumnName = "batch_no", IsNullable = true)]
    public int? batch_no { get; set; }

    [SugarColumn(ColumnName = "source_task_id", IsNullable = true)]
    public Guid? source_task_id { get; set; }

    [SugarColumn(ColumnName = "tenant_id", IsNullable = true)]
    public Guid? tenant_id { get; set; }

    [SugarColumn(ColumnName = "received_at")]
    public DateTime received_at { get; set; }

    [SugarColumn(ColumnName = "completed_at", IsNullable = true)]
    public DateTime? completed_at { get; set; }

    [SugarColumn(ColumnName = "due_at", IsNullable = true)]
    public DateTime? due_at { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }

    [SugarColumn(ColumnName = "updated_at")]
    public DateTime updated_at { get; set; }
}

[SugarTable("wf_action_log")]
public class wf_action_log
{
    [SugarColumn(IsPrimaryKey = true)]
    public Guid id { get; set; }

    [SugarColumn(ColumnName = "instance_id")]
    public Guid instance_id { get; set; }

    [SugarColumn(ColumnName = "task_id", IsNullable = true)]
    public Guid? task_id { get; set; }

    [SugarColumn(ColumnName = "node_id")]
    public string node_id { get; set; } = "";

    [SugarColumn(ColumnName = "action_type")]
    public string action_type { get; set; } = "";

    [SugarColumn(ColumnName = "action_result", IsNullable = true)]
    public string? action_result { get; set; }

    [SugarColumn(ColumnName = "operator_user_id")]
    public string operator_user_id { get; set; } = "";

    [SugarColumn(ColumnName = "operator_name", IsNullable = true)]
    public string? operator_name { get; set; }

    [SugarColumn(IsNullable = true)]
    public string? comment { get; set; }

    [SugarColumn(ColumnName = "payload_json", IsNullable = true)]
    public string? payload_json { get; set; }

    [SugarColumn(ColumnName = "action_at")]
    public DateTime action_at { get; set; }

    [SugarColumn(ColumnName = "created_at")]
    public DateTime created_at { get; set; }
}
