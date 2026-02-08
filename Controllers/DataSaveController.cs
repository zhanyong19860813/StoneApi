using Microsoft.AspNetCore.Mvc;
using System.Data;
using YourNamespace.Helpers;

[ApiController]
[Route("api/[controller]")]
public class DataSaveController : ControllerBase
{
    private readonly SqlSugarDynamicBatchHelper _batchHelper;

    public DataSaveController()
    {
        // 这里填你的数据库连接字符串
        string connStr = "Server=localhost;Database=SJHRsalarySystemDb;User Id=sa;Password=123456;TrustServerCertificate=true;";
        _batchHelper = new SqlSugarDynamicBatchHelper(connStr);
    }

    //[HttpPost("save")]
    //public IActionResult Save([FromBody] SaveBatchRequest request)
    //{
    //    try
    //    {
    //        // 将 Data 转成 DataTable
    //        var dataTable = ConvertToDataTable(request.Data); 
    //        var deleteTable = ConvertToDataTable(request.DeleteRows);

    //        _batchHelper.SaveBatch(request.TableName, dataTable, request.PrimaryKey, deleteTable);

    //        return Ok(new { success = true, message = "保存成功" });
    //    }
    //    catch (Exception ex)
    //    {
    //        return BadRequest(new { success = false, message = ex.Message });
    //    }
    //}

    [HttpPost("datasave")]
    public IActionResult Save([FromBody] SaveBatchRequest request)
    {
        if (request == null || request.data == null || request.data.Count == 0)
            return BadRequest("没有数据");

        string tableName = request.tableName;
        string primaryKey = request.primaryKey;

        // 将前端传来的 List<Dictionary<string, object>> 转成 DataTable
        DataTable dt = ConvertToDataTable(request.data, primaryKey);

        // 将 deleteRows 转成 DataTable（如果有）
        DataTable deleteDt = null;
        if (request.deleteRows != null && request.deleteRows.Count > 0)
        {
            deleteDt = ConvertToDataTable(request.deleteRows, primaryKey);
        }

        // 调用批量保存
        string connStr = "Server=localhost;Database=SJHRsalarySystemDb;User Id=sa;Password=123456;TrustServerCertificate=true;";
        SqlSugarDynamicBatchHelper helper = new SqlSugarDynamicBatchHelper(connStr);
        helper.SaveBatch(tableName, dt, primaryKey, deleteDt);

       // return Ok("保存成功");

        return Ok(new
        {
            code = 0,
            data =new { 
                message= "保存成功"
            }
          }
    );
    }

    //private DataTable ConvertToDataTable(List<Dictionary<string, object>> list)
    //{
    //    var dt = new DataTable();
    //    if (list == null || list.Count == 0) return dt;

    //    // 构建列，统一使用 object 类型
    //    foreach (var key in list[0].Keys)
    //    {
    //        if (!dt.Columns.Contains(key))
    //            dt.Columns.Add(key, typeof(object));
    //    }

    //    // 构建行
    //    foreach (var dict in list)
    //    {
    //        var row = dt.NewRow();
    //        foreach (var kv in dict)
    //        {
    //            row[kv.Key] = kv.Value ?? DBNull.Value;
    //        }
    //        dt.Rows.Add(row);
    //    }

    //    // ✅ 不再调用 SetAdded() / SetModified()
    //    // SqlSugar 会根据你传入的 DataTable 或 List<Dictionary<string, object>> 自动处理新增/修改

    //    return dt;
    //}

    private DataTable ConvertToDataTable(List<Dictionary<string, object>> list, string primaryKey)
    {
        var dt = new DataTable();
        if (list == null || list.Count == 0) return dt;

        // 构建列
        foreach (var key in list[0].Keys)
        {
            dt.Columns.Add(key, typeof(object));
        }

        // 如果主键列不存在，手动添加
        if (!dt.Columns.Contains(primaryKey))
            dt.Columns.Add(primaryKey, typeof(string));

        // 构建行
        foreach (var dict in list)
        {
            var row = dt.NewRow();
            foreach (var kv in dict)
            {
                row[kv.Key] = kv.Value ?? DBNull.Value;
            }
            dt.Rows.Add(row);
        }

        // 设置所有行状态为 Added（默认）
        foreach (DataRow row in dt.Rows)
        {
            if (row.RowState == DataRowState.Detached)
                row.SetAdded();
        }

        return dt;
    }


}



public class SaveBatchRequest
{
    // 表名
    public string tableName { get; set; }

    // 主键列名
    public string primaryKey { get; set; }

    // 新增/修改的数据列表
    public List<Dictionary<string, object>> data { get; set; }

    // 删除的数据列表，可为空
    public List<Dictionary<string, object>> deleteRows { get; set; }
}
