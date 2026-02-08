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

// 注册 SqlSugarClient 为作用域服务
// Scoped 生命周期：每个 HTTP 请求创建一个新实例，请求结束时销毁
builder.Services.AddScoped<SqlSugarClient>(sp =>
{
    // 创建数据库连接配置
    var config = new ConnectionConfig()
    {
        // 从配置文件获取数据库连接字符串
        // 格式示例："Server=localhost;Database=MyDb;User Id=sa;Password=123456;"
        ConnectionString = builder.Configuration.GetConnectionString("DefaultConnection"),

        // 设置数据库类型为 SQL Server
        // SqlSugar 支持多种数据库：SqlServer、MySql、Oracle、PostgreSQL 等
        DbType = DbType.SqlServer,

        // 设置为 true 表示自动关闭数据库连接
        // 当数据库操作完成后，SqlSugar 会自动释放连接，避免连接泄漏
        IsAutoCloseConnection = true

        // 注意：AdoType 属性已不存在于新版本 SqlSugar 中
        // 旧版本可能需要指定 AdoType 为 SqlServer，新版本已简化
    };

    // 创建并返回 SqlSugarClient 实例
    // SqlSugarClient 是主要的数据库操作对象，提供 CRUD、事务、查询等功能
    return new SqlSugarClient(config);
});

// ==================== 构建应用程序 ====================

// 使用配置的服务构建应用程序实例
// 这一步会创建依赖注入容器，注册所有服务，配置中间件管道
var app = builder.Build();

// ==================== 配置 HTTP 请求处理管道 ====================

// 配置开发环境的 Swagger 中间件
// 中间件是处理 HTTP 请求的组件，按顺序执行
if (app.Environment.IsDevelopment())
{
    // UseSwagger(): 启用 Swagger JSON 端点
    // 生成 OpenAPI 规范文档，可通过 /swagger/v1/swagger.json 访问
    app.UseSwagger();

    // UseSwaggerUI(): 启用 Swagger UI 界面
    // 提供交互式的 API 文档，可通过 /swagger 访问
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



app.UseHttpsRedirection();  // 可选
app.UseCors("AllowAll");
app.UseAuthentication();    // 👈 必须要有这个
app.UseAuthorization();     // 👈 这个也要有
app.MapControllers();
 
// ==================== 运行应用程序 ====================

// 启动应用程序，开始监听 HTTP 请求
// 这是一个阻塞调用，会一直运行直到应用程序关闭
app.Run();