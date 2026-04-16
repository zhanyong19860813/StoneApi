using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using System.Data;
using System.IdentityModel.Tokens.Jwt;

namespace StoneApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly SqlSugarClient _db;

        public UserController(SqlSugarClient db)
        {
            _db = db;
        }

        private static bool IsGuidLike(string? s)
        {
            if (string.IsNullOrWhiteSpace(s)) return false;
            var t = s.Trim();
            var inner = t.Length >= 2 && t[0] == '{' && t[^1] == '}'
                ? t.Substring(1, t.Length - 2)
                : t;
            return Guid.TryParse(inner, out _);
        }

        /// <summary>
        /// 查询用户信息（含 vben_t_sys_user 姓名、员工主数据部门/岗位）
        /// </summary>
        [HttpGet("info")]
        [Authorize]
        public IActionResult GetUserInfo()
        {
            var identity = HttpContext.User;
            var employeeIdClaim = identity.FindFirst("employeeId")?.Value;

            if (string.IsNullOrEmpty(employeeIdClaim))
                return Unauthorized();

            string employeeId = employeeIdClaim;

            var dt = _db.Ado.GetDataTable(
                """
                SELECT TOP 1
                  CAST(u.id AS varchar(50)) AS userId,
                  u.employee_id AS employee_id,
                  u.username AS username,
                  u.name AS user_name,
                  e.name AS emp_name,
                  e.code AS emp_code,
                  d.name AS dept_name,
                  d.long_name AS dept_long_name,
                  du.name AS duty_name
                FROM dbo.vben_t_sys_user u WITH (NOLOCK)
                LEFT JOIN dbo.t_base_employee e WITH (NOLOCK)
                  ON (e.code = u.employee_id OR (u.username IS NOT NULL AND e.username = u.username))
                LEFT JOIN dbo.t_base_department d WITH (NOLOCK) ON d.id = e.dept_id
                LEFT JOIN dbo.t_base_duty du WITH (NOLOCK) ON du.id = e.duty_id
                WHERE u.employee_id = @eid OR CAST(u.id AS varchar(50)) = @eid
                """,
                new SugarParameter("@eid", employeeId));

            if (dt.Rows.Count == 0)
                return Unauthorized();

            var r = dt.Rows[0];
            static string Cell(DataRow row, string col)
            {
                if (!row.Table.Columns.Contains(col)) return "";
                var o = row[col];
                return o == null || o == DBNull.Value ? "" : o.ToString()!.Trim();
            }

            var userName = Cell(r, "user_name");
            var empName = Cell(r, "emp_name");
            var realName = !string.IsNullOrEmpty(userName) ? userName : empName;
            var deptLong = Cell(r, "dept_long_name");
            var deptShort = Cell(r, "dept_name");
            var deptDisplay = !string.IsNullOrEmpty(deptLong) ? deptLong : deptShort;
            var dutyName = Cell(r, "duty_name");

            var empCode = Cell(r, "emp_code");
            var rawEmployeeId = Cell(r, "employee_id");
            var usernameVal = Cell(r, "username");
            /** 业务工号：优先员工档案 code；若 user.employee_id 存的是 GUID 则用登录名作展示工号 */
            var employeeCode = !string.IsNullOrEmpty(empCode)
                ? empCode
                : (IsGuidLike(rawEmployeeId) ? usernameVal : rawEmployeeId);

            return Ok(new
            {
                code = 0,
                data = new
                {
                    userId = Cell(r, "userId"),
                    username = usernameVal,
                    realName = realName,
                    name = realName,
                    employee_id = rawEmployeeId,
                    employeeCode = employeeCode,
                    deptName = deptDisplay,
                    deptLongName = deptLong,
                    positionName = dutyName,
                    dutyName = dutyName,
                }
            });
        }

        /// <summary>
        /// 根据用户名查权限
        /// </summary>
        [HttpGet("codes")]
        [Authorize]
        public IActionResult GetUserCodes()
        {
            var identity = HttpContext.User;
            var username = identity.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

            var codes = _db.Queryable<dynamic>()
                .AS("t_sys_user_codes")
                .Where("username=@username")
                .AddParameters(new { username })
                .Select("code")
                .ToList();

            return Ok(new { code = 0, codes });
        }
    }
}
