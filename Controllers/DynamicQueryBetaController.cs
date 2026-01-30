using Dm;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SqlSugar;
using StoneApi.Controllers.QueryModel;
using StoneApi.QueryBuilder;
using System.Data;
using System.Text;

[ApiController]
[Route("api/[controller]")]
public class DynamicQueryBetaController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public DynamicQueryBetaController(SqlSugarClient db)
    {
        _db = db;
    }

    /// <summary>
    /// ❌ 不支持 WhereNode
    ///✅只走 SimpleWhere
    /// GET /api/dynamicquery/queryforvben-get? tableName=vben_menus&page=1&pageSize=20&sortBy=code&sortOrder=desc&name=系统&status=1
    /// </summary>
    /// <param name="request"></param>
    /// <returns></returns>
    [HttpGet("query")]
    public IActionResult QueryGet([FromQuery] DynamicQueryRequest request)
    {
        var builder = new DynamicQuerySqlBuilder(_db);
        var result = builder.ExecuteQuery(request);
        return Ok(new { code = 0,
             data = result 
        });
    }

    /// <summary>
    /// 查询第一行第一列
    /// </summary>
    /// <param name="request"></param>
    /// <returns></returns>
    [HttpGet("scalar")]
    public IActionResult GetScalar([FromQuery] DynamicQueryRequest request)
    {
        var builder = new DynamicQuerySqlBuilder(_db);
        var value = builder.ExecuteScalar(request);
        return Ok(new { code = 0, data = value });
    }


    /// <summary>
    /// 批量查询  用于列表查询
    /// </summary>
    /// <param name="request"></param>
    /// <returns></returns>
    [HttpPost("queryforvben")]
    public IActionResult QueryPostForVben([FromBody] DynamicQueryRequest request)
    {
        try
        {
            var builder = new DynamicQuerySqlBuilder(_db);
            var result = builder.ExecuteQuery(  request );
            return Ok(new
            {
                code = 0,
                data = result   
            });
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    
   /// <summary>
   ///  导出Excel
   /// </summary>
   /// <param name="request"></param>
   /// <returns></returns>
    [HttpPost("ExportExcel")]
    public IActionResult ExportExcel([FromBody] DynamicQueryRequest request)
    {
        try
        {
            var builder = new DynamicQuerySqlBuilder(_db);

            DataTable data = builder.ExecuteQueryForExport(  request );

            var fileBytes = ExcelHelper.ExportDataTableToExcel(data);

            var fileName = $"{request.TableName}_{DateTime.Now:yyyyMMddHHmmss}.xlsx";

            return File(
                fileBytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }


}




