using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using Microsoft.AspNetCore.Authorization;
using System.IdentityModel.Tokens.Jwt;

namespace StoneApi.Controllers
{
     

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly ISqlSugarClient _db;

    public UserController(SqlSugarClient db)
    {
        _db = db;
    }

        /// <summary>
        /// 查询用户信息
        /// </summary>
        /// <returns></returns>
    [HttpGet("info")]
    [Authorize] // JWT 校验
    public IActionResult GetUserInfo()
    {
        var identity = HttpContext.User;
        var employeeIdClaim = identity.FindFirst("employeeId")?.Value;

        if (string.IsNullOrEmpty(employeeIdClaim))
            return Unauthorized();

        string employeeId =  employeeIdClaim;

        var user = _db.Queryable<dynamic>()
            .AS("t_sys_user")
            .Where("employee_id=@employeeId")
            .AddParameters(new { employeeId })
            .Select("employee_id, username")
            .First();

        return Ok(new
        {
            code = 0,
            data= new
            {
                employee_id = user.employee_id,
                username = user.username
            } 
             
        });
    }

        /// <summary>
        /// 根据用户名查权限
        /// </summary>
        /// <returns></returns>
        [HttpGet("codes")]
    [Authorize]
    public IActionResult GetUserCodes()
    {
        var identity = HttpContext.User;
        var username = identity.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        // 根据用户名查权限
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