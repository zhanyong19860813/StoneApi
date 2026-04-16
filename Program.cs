// 引入必要的命名空间
using SqlSugar;  // SqlSugar ORM 框架，用于简化数据库操作
using System.Text;  // 用于字符串编码操作

using Microsoft.AspNetCore.Authentication.JwtBearer;  // JWT 认证相关
using Microsoft.IdentityModel.Tokens;  // JWT token 验证相关


// 创建 ASP.NET Core 应用程序构建器
// WebApplication.CreateBuilder(args) 是 ASP.NET Core 6+ 的简化主机模型
// 它会自动配置默认设置，包括配置、日志、依赖注入容器等
var builder = WebApplication.CreateBuilder(args);

// ==================== 添加服务到依赖注入容器 ====================

// 添加控制器服务
// 这是 MVC 模式的核心，用于处理 HTTP 请求并返回响应
builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();

// 添加 API 终结点和 Swagger/OpenAPI 服务
// 1. AddEndpointsApiExplorer(): 启用 API 终结点元数据，为 Swagger 提供支持
// 2. AddSwaggerGen(): 集成 Swagger（OpenAPI）文档生成器
// 这两个服务一起工作，为 API 提供交互式文档
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ==================== JWT（JSON Web Token）认证配置 ====================

// 从 appsettings.json 配置文件读取 JWT 设置
// Configuration.GetSection("JwtSettings") 获取配置文件中名为 "JwtSettings" 的节点
var jwtSettings = builder.Configuration.GetSection("JwtSettings");

// 将 JWT 密钥从字符串转换为字节数组
// JWT 签名需要字节数组格式的密钥
var key = Encoding.UTF8.GetBytes(jwtSettings["Secret"]);

// 配置认证服务
// Authentication 是 ASP.NET Core 的身份验证系统
builder.Services.AddAuthentication(options =>
{
    // 设置默认的认证方案为 JwtBearer
    // 当用户尝试访问受保护的资源时，系统会使用此方案进行认证
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;

    // 设置默认的挑战方案为 JwtBearer
    // 当用户未认证时，系统会使用此方案发起认证挑战
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
// 添加 JWT Bearer 认证处理器
// 这会配置中间件如何验证传入的 JWT token
.AddJwtBearer(options =>
{
    // 配置 token 验证参数
    options.TokenValidationParameters = new TokenValidationParameters
    {
        // ValidateIssuer: 验证 token 的颁发者 (Issuer)
        // 设置为 true 表示会检查 token 的签发者是否与 ValidIssuer 匹配
        ValidateIssuer = true,

        // ValidateAudience: 验证 token 的受众 (Audience)
        // 设置为 true 表示会检查 token 的目标接收者是否与 ValidAudience 匹配
        ValidateAudience = true,

        // ValidateLifetime: 验证 token 的生命周期
        // 设置为 true 表示会检查 token 是否在有效期内（检查 exp 和 nbf 声明）
        ValidateLifetime = true,

        // ValidateIssuerSigningKey: 验证 token 的签名密钥
        // 设置为 true 表示会验证 token 的签名是否有效
        ValidateIssuerSigningKey = true,

        // ValidIssuer: 合法的颁发者
        // 从配置文件读取，必须与 token 中的 "iss" 声明匹配
        ValidIssuer = jwtSettings["Issuer"],

        // ValidAudience: 合法的受众
        // 从配置文件读取，必须与 token 中的 "aud" 声明匹配
        ValidAudience = jwtSettings["Audience"],

        // IssuerSigningKey: 用于验证签名的密钥
        // 使用对称密钥（同一个密钥用于签名和验证）
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

// ==================== CORS（跨源资源共享）配置 ====================

// 添加 CORS 服务到依赖注入容器
// CORS 是一种安全机制，允许或限制不同源的 Web 应用访问资源
builder.Services.AddCors(options =>
{
    // 定义一个名为 "AllowAll" 的 CORS 策略
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .AllowAnyOrigin()    // 允许任何来源（域名）访问
                                 // 注意：AllowAnyOrigin() 与 AllowCredentials() 不能同时使用
                                 // 如果需要凭证（cookies、认证头），应指定具体的源

            .AllowAnyHeader()    // 允许任何 HTTP 请求头
                                 // 包括自定义头如 Authorization、Content-Type 等

            .AllowAnyMethod();   // 允许任何 HTTP 方法
                                 // 包括 GET、POST、PUT、DELETE、PATCH、OPTIONS 等
    });
});

// ==================== SqlSugar 数据库配置 ====================

StoneApi.Controllers.OperationLogController.SetConnectionString(builder.Configuration.GetConnectionString("DefaultConnection"));

// 排班 Excel 导入（临时表 + 校验函数 + 落库过程）
builder.Services.AddScoped<StoneApi.Services.JobSchedulingImportService>();

// 钉钉部门 oapi（HttpClient，与旧服务 SyncHrmToDingTalkJob 调用的接口一致）
builder.Services.AddHttpClient<StoneApi.Services.DingTalkOapiDepartmentService>();
builder.Services.AddHttpClient<StoneApi.Services.DingTalkOapiUserService>();

// 注册 SqlSugarClient 为作用域服务
// Scoped 生命周期：每个 HTTP 请求创建一个新实例，请求结束时销毁
builder.Services.AddScoped<SqlSugarClient>(sp =>
{
    var connStr = builder.Configuration.GetConnectionString("DefaultConnection");
    var cmdTimeout = builder.Configuration.GetValue<int?>("SqlCommandTimeoutSeconds") ?? 180;
    if (cmdTimeout <= 0) cmdTimeout = 180;
    var httpAccessor = sp.GetService<Microsoft.AspNetCore.Http.IHttpContextAccessor>();
    var config = new ConnectionConfig()
    {
        ConnectionString = connStr,
        DbType = DbType.SqlServer,
        IsAutoCloseConnection = true
    };
    var client = new SqlSugarClient(config);
    client.Ado.CommandTimeOut = cmdTimeout;
    client.Aop.OnLogExecuting = (sql, pars) =>
    {
        if (string.IsNullOrEmpty(sql) || sql.IndexOf("vben_sys_operation_log", StringComparison.OrdinalIgnoreCase) >= 0)
            return;
        try
        {
            var httpContext = httpAccessor?.HttpContext;
            var userId = httpContext?.User?.FindFirst("employeeId")?.Value ?? httpContext?.User?.FindFirst("sub")?.Value ?? "";
            var userName = httpContext?.User?.Identity?.Name ?? httpContext?.User?.FindFirst("name")?.Value ?? "";
            var endpoint = httpContext != null ? $"{httpContext.Request.Method} {httpContext.Request.Path}" : "";
            var ip = httpContext?.Connection?.RemoteIpAddress?.ToString() ?? "";
            var forwarded = httpContext?.Request?.Headers["X-Forwarded-For"].FirstOrDefault();
            if (!string.IsNullOrEmpty(forwarded)) ip = forwarded;
            var sqlWithParams = pars != null && pars.Length > 0
                ? sql + " -- " + string.Join(", ", pars.Select(p => $"{p.ParameterName}={p.Value}"))
                : sql;
            // 异步写入，不阻塞主 SQL 执行
            _ = System.Threading.Tasks.Task.Run(() =>
            {
                try { StoneApi.Controllers.OperationLogHelper.TryWriteSqlLog(userId, userName, sqlWithParams, endpoint, ip, null); } catch { }
            });
        }
        catch { }
    };
    return client;
});

// ==================== 构建应用程序 ====================

// 使用配置的服务构建应用程序实例
// 这一步会创建依赖注入容器，注册所有服务，配置中间件管道
var app = builder.Build();

// ==================== 配置 HTTP 请求处理管道 ====================

// Swagger：Development 默认开启；发布为 Production 时由 EnableSwaggerInProduction 控制（本机双击 exe 调试可开，公网生产建议 false）
var enableSwagger =
    app.Environment.IsDevelopment()
    || app.Configuration.GetValue<bool>("EnableSwaggerInProduction");
if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ==================== 配置中间件管道 ====================

//// 启用 CORS 中间件，使用名为 "AllowAll" 的策略
//// 位置很重要：CORS 应该在认证和授权中间件之前，但在路由之后
//app.UseCors("AllowAll");

//// 启用授权中间件
//// 这会检查 [Authorize] 特性，验证用户是否有权限访问资源
//// 注意：这里缺少了 app.UseAuthentication()，应该添加：
//// app.UseAuthentication(); // 启用认证中间件，验证用户身份
//app.UseAuthorization();

//// 映射控制器路由
//// 将 HTTP 请求路由到相应的控制器和 Action 方法
//app.MapControllers();



// 仅监听 HTTP（如双击 exe）时 appsettings 里 EnableHttpsRedirection=false，避免 HttpsRedirection 警告
if (app.Configuration.GetValue<bool>("EnableHttpsRedirection", true))
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles(); // wwwroot，含员工照片 images/employeePhotos
app.UseCors("AllowAll");
app.UseAuthentication();    // 👈 必须要有这个
app.UseAuthorization();     // 👈 这个也要有
app.MapControllers();
 
// ==================== 运行应用程序 ====================

// 启动应用程序，开始监听 HTTP 请求
// 这是一个阻塞调用，会一直运行直到应用程序关闭
app.Run();