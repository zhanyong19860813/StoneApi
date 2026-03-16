using SqlSugar;

namespace StoneApi.Controllers.service
{
    public static class VbenSchemaBuilder
    {
        public static object Build(SqlSugarClient _db, Guid userid, Guid menuId, EntityList entity, List<EntityColumn> columns)
        {
            //Guid roleId = Guid.Parse("55555555-5555-5555-5555-555555555551");
            //Guid menuId = Guid.Parse("5A5AE6D5-7785-4C91-8A2A-114948D6B284");

            //            var roleMenuActions = _db.Query<VbenRoleMenuAction>(@"
            //    select *
            //    from vben_v_role_menu_actions
            //    where role_id = @roleId
            //      and menu_id = @menuId
            //", new { roleId, menuId }).ToList();


            //var roleMenuActions = _db.Queryable<VbenRoleMenuAction>()
            //    .Where(m => m.Role_Id == roleId && m.Menu_Id == menuId)
            //    .ToList();

            var roleMenuActions = _db.Queryable<VbenUserRoleMenuAction>()
               .Where(m => m.userid == userid && m.Menu_Id == menuId)
               .ToList();



            {
                return new
                {
                    entityListId=entity.Id,
                    title = entity.Title,
                    tableName = entity.TableName,
                    // primaryKey = entity.PrimaryKey,
                    actionModule = entity.actionModule,
                    deleteEntityName = entity.DeleteEntityName,
                    saveEntityName=entity.saveEntityName,
                    //自定义按钮 栏 配置
                    //toolbar = new
                    //{
                    //    actions = new List<ToolbarAction>
                    //  {
                    //      new ToolbarAction("add", "新增schema","primary","add"),
                    //      new ToolbarAction("reload", "刷新schema","default","reload"),
                    //      new ToolbarAction("delete", "删除schema","default","deleteSelected"),

                    //  }
                    //},
                    toolbar = BuildToolbar(roleMenuActions),
                    form = BuildForm(columns),
                    grid = BuildGrid(columns,entity.sortFieldName,entity.sortType),

                    api = new
                    {
                        query = "http://127.0.0.1:5155/api/DynamicQueryBeta/queryforvben",
                        delete = "http://localhost:5155/api/DataBatchDelete/BatchDelete",
                        export = "http://127.0.0.1:5155/api/DynamicQueryBeta/ExportExcel"
                    }
                };
            }
        }




        private static object BuildToolbar(
     
    List<VbenUserRoleMenuAction> actions
)
        {
            var toolbarActions = actions
                .Select(a => new ToolbarAction(
                    a.Action_Key,
                    a.Label,
                    a.Button_Type ?? "default",
                    a.Action
                ))
                .ToList();

            return new
            {
                actions = toolbarActions
            };
        }

        private static object BuildForm(List<EntityColumn> columns)
        {
            var formSchema = columns
                .Where(c => c.Used_In_Form)
                .OrderBy(c => c.Form_Order)
                .Select(c => new
                {
                    component = c.Form_Component,
                    fieldName = c.Field,
                    label = c.Title
                });

            return new
            {
                collapsed = false,
                submitOnChange = true,
                schema = formSchema
            };
        }

        private static object BuildGrid(List<EntityColumn> columns,string sortFieldName,string sortType)
        {
            var gridColumns = new List<object>();

            foreach (var c in columns.Where(c => c.Used_In_List))
            {
                // checkbox / seq
                if (c.Column_Type == "checkbox")
                {
                    gridColumns.Add(new { type = "checkbox", width = c.Width });
                    continue;
                }

                if (c.Column_Type == "seq")
                {
                    gridColumns.Add(new { type = "seq", width = c.Width });
                    continue;
                }

                // 普通字段
                gridColumns.Add(new
                {
                    field = c.Field,
                    title = c.Title,
                    minWidth = c.Width,
                    sortable = c.Sortable
                });
            }


            //string sortField = columns.FirstOrDefault(c => c.Sortable)?.Field;
            //string sortType=  .Sortable == true ? "asc" : "desc";

            return new
            {
                columns = gridColumns,
                pagerConfig = new { enabled = true, pageSize = 10 },
                sortConfig = new
                {
                    remote = true,
                    defaultSort = new { field = sortFieldName, order =sortType }
                }
            };

            //return new
            //{
            //    columns = gridColumns,
            //    pagerConfig = new { enabled = true, pageSize = 10 },
            //    sortConfig=new {
            //      remote= true,
            //     defaultSort=new  { field="Name", order= "asc"} 
            //    }
            // };
        }
    }


    // 定义一个具名类用于表示工具栏动作
public class ToolbarAction
{
    public string Key { get; set; }
    public string Label { get; set; }
    public string Type { get; set; }
    public string Action { get; set; }

    // 构造函数，提供默认值以增强健壮性
    public ToolbarAction(string key, string label, string type = "default", string action = "")
    {
        Key = key ?? throw new ArgumentNullException(nameof(key));
        Label = label ?? throw new ArgumentNullException(nameof(label));
        Type = type;
        Action = action;
    }
}


    [SugarTable("vben_v_role_menu_actions")]
    public class VbenRoleMenuAction
    {
        public Guid Role_Id { get; set; }
        public Guid Menu_Id { get; set; }

        public Guid  Id { get; set; }
        public string Action_Key { get; set; } = "";
        public string Label { get; set; } = "";
        public string Button_Type { get; set; } = "default";
        public string Action { get; set; } = "";
        public string? Confirm_Text { get; set; }
    }

    [SugarTable("vben_v_user_role_menu_actions")]
    public class VbenUserRoleMenuAction
    {
        public Guid Role_Id { get; set; }

        public Guid userid { get; set; }


        public Guid Menu_Id { get; set; }

        public Guid Id { get; set; }
        public string Action_Key { get; set; } = "";
        public string Label { get; set; } = "";
        public string Button_Type { get; set; } = "default";
        public string Action { get; set; } = "";
        public string? Confirm_Text { get; set; }
    }
}
