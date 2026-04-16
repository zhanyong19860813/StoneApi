using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using System.Data;

namespace StoneApi.Controllers;

/// <summary>
/// 表单联动：根据选中项查询关联数据，用于「选用户带出工号、性别」等场景
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FormLookupController : ControllerBase
{
    private readonly SqlSugarClient _db;

    public FormLookupController(SqlSugarClient db)
    {
        _db = db;
    }

    /// <summary>
    /// 员工 Lookup：根据姓名/工号/ID 查询一条员工记录，返回工号、性别等，供表单联动填充
    /// GET /api/FormLookup/Employee?value=张三 或 ?value=001
    /// 返回：{ "code": 0, "data": { "name": "张三", "code": "001", "gender": "男", ... } }（列名以实际表为准）
    /// </summary>
    [HttpGet("Employee")]
    public IActionResult Employee([FromQuery] string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return Ok(new { code = 0, data = (object?)null });

        var v = value.Trim();
        try
        {
            // 查询员工表：支持按 姓名/工号/id 匹配，返回整行供前端按列名映射到表单字段（工号、性别等）
            const string table = "t_base_employee";
            var sql = $@"SELECT TOP 1 * FROM [{table}] WHERE [name]=@p0 OR [code]=@p0 OR [id]=@p0 OR [employee_code]=@p0";
            var dt = _db.Ado.GetDataTable(sql, new SugarParameter("@p0", v));
            if (dt == null || dt.Rows.Count == 0)
                return Ok(new { code = 0, data = (object?)null });

            var row = dt.Rows[0];
            var dict = new Dictionary<string, object?>();
            foreach (DataColumn col in dt.Columns)
            {
                var val = row[col.ColumnName];
                if (val == DBNull.Value) val = null;
                dict[col.ColumnName] = val;
            }
            return Ok(new { code = 0, data = dict });
        }
        catch (Exception ex)
        {
            return Ok(new { code = -1, message = ex.Message, data = (object?)null });
        }
    }
}
