using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace StoneApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProcedureController : ControllerBase
    {
        private readonly SqlSugarClient _db;

        // 可按需扩展：默认仅允许这些前缀，避免任意执行高危过程
        private static readonly string[] AllowedPrefixes = new[]
        {
            "att_pro_",
            "att_set_",
            "Import_"
        };

        public ProcedureController(SqlSugarClient db)
        {
            _db = db;
        }

        [HttpPost("execute")]
        public IActionResult Execute([FromBody] ExecuteProcedureRequest req)
        {
            if (req == null || string.IsNullOrWhiteSpace(req.ProcedureName))
                return BadRequest(new { code = -1, message = "procedureName 不能为空" });

            var normalized = NormalizeProcedureName(req.ProcedureName);
            if (normalized == null)
                return BadRequest(new { code = -1, message = "procedureName 格式非法。仅支持 dbo.proc 或 proc" });

            var (schema, procName, fullName) = normalized.Value;
            if (!IsAllowedProcedure(schema, procName))
                return BadRequest(new { code = -1, message = $"不允许执行该存储过程: {fullName}" });

            try
            {
                using var conn = new SqlConnection(_db.CurrentConnectionConfig.ConnectionString);
                using var cmd = new SqlCommand(fullName, conn)
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandTimeout = req.TimeoutSeconds is > 0 and <= 600 ? req.TimeoutSeconds.Value : 120,
                };

                if (req.Parameters != null)
                {
                    foreach (var kv in req.Parameters)
                    {
                        var name = NormalizeParamName(kv.Key);
                        if (string.IsNullOrWhiteSpace(name)) continue;
                        var value = ConvertJsonValue(kv.Value);
                        cmd.Parameters.AddWithValue(name, value ?? DBNull.Value);
                    }
                }

                conn.Open();

                if (req.ReturnData == true)
                {
                    using var da = new Microsoft.Data.SqlClient.SqlDataAdapter(cmd);
                    var dt = new DataTable();
                    da.Fill(dt);
                    var rows = DataTableToDictionaryList(dt);
                    return Ok(new
                    {
                        code = 0,
                        data = new
                        {
                            procedure = fullName,
                            rowCount = rows.Count,
                            rows
                        }
                    });
                }
                else
                {
                    var affected = cmd.ExecuteNonQuery();
                    return Ok(new
                    {
                        code = 0,
                        data = new
                        {
                            procedure = fullName,
                            rowsAffected = affected
                        }
                    });
                }
            }
            catch (Exception ex)
            {
                return BadRequest(new { code = -1, message = ex.Message });
            }
        }

        private static (string Schema, string ProcName, string FullName)? NormalizeProcedureName(string raw)
        {
            var s = raw.Trim();
            // 支持 proc 或 schema.proc；禁止空格/分号等
            if (!Regex.IsMatch(s, @"^[A-Za-z_][A-Za-z0-9_\.]*$")) return null;
            var parts = s.Split('.', StringSplitOptions.RemoveEmptyEntries);
            string schema = "dbo";
            string proc = s;
            if (parts.Length == 2)
            {
                schema = parts[0];
                proc = parts[1];
            }
            else if (parts.Length == 1)
            {
                proc = parts[0];
            }
            else
            {
                return null;
            }
            var full = $"{schema}.{proc}";
            return (schema, proc, full);
        }

        private static bool IsAllowedProcedure(string schema, string procName)
        {
            if (!schema.Equals("dbo", StringComparison.OrdinalIgnoreCase)) return false;
            return AllowedPrefixes.Any(p => procName.StartsWith(p, StringComparison.OrdinalIgnoreCase));
        }

        private static string NormalizeParamName(string name)
        {
            var n = (name ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(n)) return n;
            if (!n.StartsWith("@")) n = "@" + n;
            return n;
        }

        private static object? ConvertJsonValue(object? value)
        {
            if (value == null) return null;
            if (value is JsonElement je)
            {
                return je.ValueKind switch
                {
                    JsonValueKind.Null => null,
                    JsonValueKind.String => je.GetString(),
                    JsonValueKind.Number => je.TryGetInt64(out var l) ? l
                        : je.TryGetDecimal(out var d) ? d
                        : je.GetDouble(),
                    JsonValueKind.True => true,
                    JsonValueKind.False => false,
                    _ => je.ToString(),
                };
            }
            return value;
        }

        private static List<Dictionary<string, object?>> DataTableToDictionaryList(DataTable dt)
        {
            var list = new List<Dictionary<string, object?>>(dt.Rows.Count);
            foreach (DataRow row in dt.Rows)
            {
                var item = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                foreach (DataColumn col in dt.Columns)
                {
                    var v = row[col];
                    item[col.ColumnName] = v == DBNull.Value ? null : v;
                }
                list.Add(item);
            }
            return list;
        }
    }

    public class ExecuteProcedureRequest
    {
        public string ProcedureName { get; set; } = "";
        public Dictionary<string, object>? Parameters { get; set; }
        public bool? ReturnData { get; set; } = false;
        public int? TimeoutSeconds { get; set; }
    }
}

