using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SqlSugar;

namespace StoneApi.Controllers
{


   
    [Route("api/[controller]")]
    [ApiController]
    public class MenuController : ControllerBase
    {


        private readonly SqlSugarClient _db;



        public MenuController(SqlSugarClient db)
        {
            _db = db;
        }
        /// <summary>
        /// 获取菜单
        /// </summary>
        //[HttpGet("GetMenu")]
        //public IActionResult GetMenu()
        //{
        //    var menus = new[]
        //    {
        //        new
        //        {
        //            path = "/demo",
        //            name = "Demo",
        //            meta = new
        //            {
        //                title = "示例",
        //                icon = "ant-design:appstore-outlined",
        //                orderNo = 10
        //            },
        //            children = new[]
        //            {
        //                new
        //                {
        //                    path = "simple-table",
        //                    name = "SimpleTable",
        //                    component = "/demos/simple-table/index",
        //                    meta = new
        //                    {
        //                        title = "简单表格2"
        //                    }
        //                },
        //                new
        //                {
        //                    path = "url-table",
        //                    name = "UrlTable",
        //                    component = "/demos/simple-table/urltable",
        //                    meta = new
        //                    {
        //                        title = "表格后台数据1"
        //                    }
        //                }
        //            }
        //        }
        //    };

        //    return Ok(new
        //    {
        //        code = 0,
        //        data = menus
        //    });
        //    //return Ok(menus);
        //}


        //    /// <summary>
        //    /// 获取菜单
        //    /// </summary>
        //    [HttpGet("GetMenu")]
        //    public IActionResult GetMenu()
        //    {
        //        var menus = new[]
        //        {
        //    new
        //    {
        //        path = "/demo",
        //        name = "Demo",
        //        component = "BasicLayout",
        //        meta = new
        //        {
        //            title = "示例",
        //            icon = "ant-design:appstore-outlined",
        //            orderNo = 10
        //        },
        //        children = new[]
        //        {
        //            new
        //            {
        //                path = "simple-table",
        //                name = "SimpleTable",
        //                component = "demos/simple-table/index",
        //                meta = new { title = "简单表格2" }
        //            },
        //            new
        //            {
        //                path = "url-table",
        //                name = "UrlTable",
        //                component = "demos/simple-table/urltable",
        //                meta = new { title = "表格后台数据1" }
        //            }
        //        }
        //    }
        //};

        //        return Ok(new
        //        {
        //            code = 0,
        //            data = menus
        //        });
        //    }


        /// <summary>
        /// 获取菜单
        /// </summary>
        [HttpGet("GetMenu")]
        public IActionResult GetMenu()
        {
            var menus = new[]
            {
        new
        {
            meta = new
            {
                order = -1,
                title = "page.dashboard.title"
            },
            name = "Dashboard",
            path = "/",
            redirect = "/analytics",
            children = new object[]
            {
                new
                {
                    name = "Analytics",
                    path = "/analytics",
                    component = "/dashboard/analytics/index",
                    meta = new
                    {
                        affixTab = true,
                        title = "test"
                    }
                },
                new
                {
                    name = "Workspace",
                    path = "/workspace",
                    component = "/dashboard/workspace/index",
                    meta = new
                    {
                        title = "tetttttt"
                    }
                },
                new
                {
                    path = "simple-table",
                    name = "SimpleTable",
                    component = "demos/simple-table/index",
                    meta = new
                    {
                        title = "简单表格"
                    }
                },
                new
                {
                    path = "url-table",
                    name = "UrlTable",
                    component = "demos/simple-table/urltable",
                    meta = new
                    {
                        affixTab = true,
                        title = "表格后台数据"
                    }
                }
            }
        }
    };


            return Ok(new
            {
                code = 0,
                data = menus
            });

           // return Ok(menus);
        }




        [Authorize]
        [HttpGet("GetMenuFromDb")]
        public IActionResult GetMenuFromDb()
        {
            //获得当前登录人
           // var userId = User.FindFirst("employee_id")?.Value;

            //当前登录人ID 
             string employeeId = User.FindFirst("employeeId").Value;

            string userId = User.FindFirst("UserId").Value;
            

            //查询当前登录人的菜单数据
            //var menus = _db.Queryable<vben_menus_new>() vben_v_user_menu
            //    .Where(m => m.Status == 1)  // 仅获取启用的菜单
            //    .OrderBy(m => m.Id)  // 根据 Id 排序
            //    .ToList();

            // 使用 SqlSugar 查询启用的菜单数据  vben_v_user_role_menus
            //var menus = _db.Queryable<vben_menus_new>()
            //    .Where(m => m.Status == 1)  // 仅获取启用的菜单
            //    .OrderBy(m => m.Id)  // 根据 Id 排序
            //    .ToList();

            var menus = _db.Queryable<vben_v_user_role_menus>()
              .Where(m => m.userid== userId && m.Status == 1)  // 仅获取启用的菜单
              .OrderBy(m => m.Id)  // 根据 Id 排序
              .ToList();

            // 将数据库中的菜单数据转换为前端需要的格式
            //var result = menus
            //    .Where(m => m.parent_id == null)  // 获取顶级菜单（parent_id 为 null）
            //    .Select(m => new
            //    {
            //        meta = new
            //        {
            //            order = GetMetaValue(m.Meta, "order", -1),
            //            title = GetMetaValue(m.Meta, "title", "Untitled")
            //        },
            //        name = m.Name,
            //        path = m.Path,
            //        children = GetChildrenMenus(menus, m.Id)  // 获取子菜单
            //    })
            //    .ToList();


            var result = menus
    .Where(m => m.parent_id == null)  // 顶级菜单
    .Select(m => new
    {
        name = m.Name,
        path = m.Path,
        //component = m.Component,
        meta = ParseMeta(m.Meta),
        children = GetChildrenMenus(menus, m.Id)
    })
    .ToList();

            return Ok(new
            {
                code = 0,
                data = result
            });
        }

        // 递归获取子菜单
        private List<object> GetChildrenMenus(List<vben_v_user_role_menus> menus, string parentId)
        {
            var children = menus
                .Where(m => m.parent_id == parentId)   // ✅ 这里必须用 parentId
                .Select(m => new
                {
                    name = m.Name,
                    path = m.Path,
                    component = m.Component,
                    meta = ParseMeta(m.Meta),
                    children = GetChildrenMenus(menus, m.Id) // 递归
                })
                .ToList<object>();

            return children;
        }

        private object ParseMeta(string meta)
        {
            if (string.IsNullOrWhiteSpace(meta))
                return new { };

            try
            {
                var jObj = JObject.Parse(meta);

                return new
                {
                    title = jObj["title"]?.ToString(),
                    icon = jObj["icon"]?.ToString(),
                    affixTab = jObj["affixTab"]?.ToObject<bool?>()
                };
            }
            catch
            {
                return new { };
            }
        }


        // 获取 Meta 中的特定值（如 "order", "title"）
        private T GetMetaValue<T>(string meta, string key, T defaultValue)
        {
            try
            {
                var jsonMeta = JsonConvert.DeserializeObject<dynamic>(meta);  // 解析 JSON 字符串
                return jsonMeta[key] ?? defaultValue;  // 获取指定 key 的值
            }
            catch
            {
                return defaultValue;  // 如果解析失败，则返回默认值
            }
        }

    }


    public class vben_menus
    {
        public int Id { get; set; }  // 菜单的 ID
        public string Name { get; set; }  // 菜单名称
        public string Path { get; set; }  // 菜单路径
        public string Component { get; set; }  // 组件路径
        public string Meta { get; set; }  // 存储菜单附加信息 (如 JSON 格式)
        public int? parent_id { get; set; }  // 父菜单 ID
        public int Status { get; set; }  // 菜单状态：1 启用，0 禁用
        public string Type { get; set; }  // 菜单类型：menu 或 catalog
         
    }

    public class vben_menus_new
    {
        public string Id { get; set; }  // 菜单的 ID
        public string Name { get; set; }  // 菜单名称
        public string Path { get; set; }  // 菜单路径
        public string Component { get; set; }  // 组件路径
        public string Meta { get; set; }  // 存储菜单附加信息 (如 JSON 格式)
        public string? parent_id { get; set; }  // 父菜单 ID
        public int Status { get; set; }  // 菜单状态：1 启用，0 禁用
        public string Type { get; set; }  // 菜单类型：menu 或 catalog

    }

    public class vben_v_user_role_menus
    {

        public string username { get; set; } // 用户名

        public string userid { get; set; } // 用户id


        public string rolename { get; set; } // 用户名

        public string roleid { get; set; } // 用户id

        public string Id { get; set; }  // 菜单的 ID
        public string Name { get; set; }  // 菜单名称
        public string Path { get; set; }  // 菜单路径
        public string Component { get; set; }  // 组件路径
        public string Meta { get; set; }  // 存储菜单附加信息 (如 JSON 格式)
        public string? parent_id { get; set; }  // 父菜单 ID
        public int Status { get; set; }  // 菜单状态：1 启用，0 禁用
        public string Type { get; set; }  // 菜单类型：menu 或 catalog

    }
}
