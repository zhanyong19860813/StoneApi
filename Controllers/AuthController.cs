using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using SqlSugar;
using StoneApi.Controllers.com;
using static Org.BouncyCastle.Math.EC.ECCurve;

namespace StoneApi.Controllers
{

    public class LoginRequest
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }

    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        

        private readonly SqlSugarClient _db;
        private readonly IConfiguration _config;


        public AuthController(SqlSugarClient db,IConfiguration config)
        {
            _db = db;
            _config = config;
        }

        [HttpPost("Login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
            {
                return Ok(new { code = 400, msg = "用户名或密码不能为空" });
            }

            // 只按用户名查
            var user = _db.Queryable<dynamic>()
                .AS("t_sys_user")
                .Where("username=@username")
                .AddParameters(new
                {
                    username = request.Username
                })
                .Select("username, password, employee_id")
                .First();

            if (user == null)
            {
                return Ok(new
                {
                    code = 401,
                    msg = "用户名不存在"
                });
            }

            // dynamic → string
            string dbPassword = Convert.ToString(user.password);
            string inputPassword = request.Password;

            // 用静态方式调用扩展方法（避开 dynamic 调度）
            bool ok = ExtendMethods.VerifyMd5Hash(inputPassword, dbPassword);

            if (!ok)
            {
                return Ok(new
                {
                    code = 401,
                    msg = "密码错误"
                });
            }

            return Ok(new
            {
                code = 0,
                msg = "登录成功",
                employee_id = user.employee_id
            });
        }




        [HttpPost("jwtlogin")]
        public IActionResult JwtLogin([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest("用户名或密码不能为空");

            // 查询数据库用户
            var user = _db.Queryable<dynamic>()
                .AS("t_sys_user")
                .Where("username=@username")
                .AddParameters(new { username = request.Username })
                .Select("employee_id, username, password")
                .First();

            if (user == null)
                return Unauthorized("用户名或密码错误");

            // 验证 MD5 密码
            string inputPasswordMd5 = request.Password.GetMd5Hash(); // 使用你之前的扩展方法
            string dbPassword = Convert.ToString(user.password);

            if (!inputPasswordMd5.Equals(dbPassword, StringComparison.OrdinalIgnoreCase))
                return Unauthorized("用户名或密码错误");

            //int employeeId = Convert.ToInt32(user.employee_id);
            //// 生成 JWT
            //string token = JwtHelper.GenerateToken(
            //employeeId,
            //user.username,
            //_config["JwtSettings:Secret"],
            //int.Parse(_config["JwtSettings:AccessTokenExpirationMinutes"])
            //  );
            //// 生成 JWT
            string token = JwtHelper.GenerateToken(
                user.employee_id,
                user.username,
                _config["JwtSettings:Secret"],
                int.Parse(_config["JwtSettings:AccessTokenExpirationMinutes"])
            );

            return Ok(new
            {
                code = 0,
                data = new
                {
                    msg = "登录成功",
                    accessToken = token
                }
            });
        }
    }
}
    
