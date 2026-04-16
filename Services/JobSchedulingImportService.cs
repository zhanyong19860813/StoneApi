using System.Data;
using System.Globalization;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using SqlSugar;

namespace StoneApi.Services;

/// <summary>
/// 排班作业 Excel 导入：对齐老系统 ImportData.JobSchedulingExtraOperation + Import_TMP_JobScheduling +
/// dbo.Import_JobScheduling_CheckFunction + dbo.Import_JobScheduling_Procedure。
/// </summary>
public class JobSchedulingImportService
{
    private readonly string _connStr;
    private const string ZeroUuid = "00000000-0000-0000-0000-000000000000";

    public JobSchedulingImportService(SqlSugarClient db)
    {
        _connStr = db.CurrentConnectionConfig.ConnectionString;
    }

    public record ImportCheckError(string? ItemId, string? ItemName, string? ItemDetail, string? Reason);

    public class PreviewResult
    {
        public List<ImportCheckError> Errors { get; set; } = new();
        public int RowCount { get; set; }
        public bool CanCommit { get; set; }
    }

    public async Task<PreviewResult> PreviewAsync(Stream excelStream, string fileName, string operatorName,
        string operatorEmpId, string mark, CancellationToken ct = default)
    {
        var result = new PreviewResult();
        operatorName = (operatorName ?? "").Trim();
        operatorEmpId = (operatorEmpId ?? "").Trim();
        mark = (mark ?? "1042").Trim();
        if (mark.Length > 5) mark = mark[..5];

        if (string.IsNullOrEmpty(operatorName))
        {
            result.Errors.Add(new ImportCheckError("", "", "", "操作人姓名不能为空"));
            return result;
        }

        await using var conn = new SqlConnection(_connStr);
        await conn.OpenAsync(ct);

        var sheet = LoadSheet(excelStream, fileName);
        if (sheet == null)
        {
            result.Errors.Add(new ImportCheckError("", "", "", "无法读取 Excel（请使用 .xls 或 .xlsx）"));
            return result;
        }

        var headerRow = sheet.GetRow(0);
        if (headerRow == null || headerRow.LastCellNum < 1)
        {
            result.Errors.Add(new ImportCheckError("", "", "", "表头为空"));
            return result;
        }

        var colNames = new List<string>();
        for (var c = 0; c < headerRow.LastCellNum; c++)
            colNames.Add(GetCellValue(headerRow.GetCell(c)));

        var source = new DataTable();
        var uniqueHeaders = new List<string>();
        for (var c = 0; c < colNames.Count; c++)
        {
            var h = (colNames[c] ?? "").Trim();
            if (string.IsNullOrEmpty(h)) h = $"__col{c}";
            if (!source.Columns.Contains(h)) source.Columns.Add(h, typeof(string));
            uniqueHeaders.Add(h);
        }

        for (var r = 1; r <= sheet.LastRowNum; r++)
        {
            var row = sheet.GetRow(r);
            if (row == null) continue;
            var allEmpty = true;
            for (var c = 0; c < uniqueHeaders.Count; c++)
            {
                if (!string.IsNullOrWhiteSpace(GetCellValue(row.GetCell(c))))
                {
                    allEmpty = false;
                    break;
                }
            }
            if (allEmpty) continue;

            var dr = source.NewRow();
            for (var c = 0; c < uniqueHeaders.Count && c < source.Columns.Count; c++)
                dr[source.Columns[c]!.ColumnName] = GetCellValue(row.GetCell(c));
            source.Rows.Add(dr);
        }

        if (source.Rows.Count == 0)
        {
            result.Errors.Add(new ImportCheckError("", "", "", "没有数据行"));
            return result;
        }

        var outTitleMap = new Dictionary<string, string>();
        for (var i = 1; i <= 31; i++)
            outTitleMap["D" + i] = "D" + i + "id";

        var monthStr = "";
        foreach (DataColumn col in source.Columns.Cast<DataColumn>().ToList())
        {
            var columnNameNumber = Regex.Replace(col.ColumnName, @"[^0-9\-]+", "");
            if (!DateTime.TryParse(columnNameNumber, CultureInfo.CurrentCulture, DateTimeStyles.None, out var colDate))
                continue;
            var newName = "D" + colDate.Day;
            if (source.Columns.Contains(newName)) continue;
            col.ColumnName = newName;
            monthStr = colDate.ToString("yyyyMM", CultureInfo.InvariantCulture);
        }

        if (!source.Columns.Contains("月份"))
        {
            source.Columns.Add("月份", typeof(string));
            foreach (DataRow row in source.Rows)
                row["月份"] = monthStr;
        }
        else
        {
            monthStr = (source.Rows[0]["月份"]?.ToString() ?? "").Trim().Replace("-", "");
        }

        if (string.IsNullOrWhiteSpace(monthStr) || monthStr.Length != 6)
        {
            result.Errors.Add(new ImportCheckError("", "", "",
                "无法确定排班月份：请提供「月份」列或带日期的列头（如 2026-04-01）"));
            return result;
        }

        foreach (DataRow row in source.Rows)
            row["月份"] = monthStr;

        if (!source.Columns.Contains("工号"))
        {
            result.Errors.Add(new ImportCheckError("", "", "", "数据源中缺少「工号」列"));
            return result;
        }

        foreach (var kv in outTitleMap)
        {
            if (!source.Columns.Contains(kv.Value))
                source.Columns.Add(kv.Value, typeof(Guid));
            if (!source.Columns.Contains(kv.Key))
                source.Columns.Add(kv.Key, typeof(string));
        }

        var jobList = await LoadJobListAsync(conn, ct);
        var shiftsOk = await LoadShiftPermissionsAsync(conn, operatorEmpId, ct);
        var powerList = await LoadPowerEmpIdsAsync(conn, operatorName, ct);

        var rulesByEmp = await LoadShiftsRulesByEmpAsync(conn, source, ct);
        CheckImportShiftsRules(source, outTitleMap, monthStr, rulesByEmp, result.Errors);

        foreach (DataRow row in source.Rows)
        {
            var rowIndex = source.Rows.IndexOf(row) + 2;
            foreach (var kv in outTitleMap)
            {
                var jobName = (row[kv.Key]?.ToString() ?? "").Trim();
                if (string.IsNullOrEmpty(jobName))
                {
                    row[kv.Value] = Guid.Parse(ZeroUuid);
                    continue;
                }

                if (!jobList.TryGetValue(jobName, out var fid))
                {
                    result.Errors.Add(new ImportCheckError("", jobName, $"第{rowIndex}行", "班次数据库里无此班次！"));
                    continue;
                }

                row[kv.Value] = fid;
                if (!shiftsOk.Contains(fid.ToString("D"), StringComparer.OrdinalIgnoreCase))
                {
                    result.Errors.Add(new ImportCheckError("", jobName, "班次权限异常", "您无此班次权限，无法排班！"));
                }
            }

            var empId = (row["工号"]?.ToString() ?? "").Trim();
            if (!powerList.Contains(empId))
            {
                result.Errors.Add(new ImportCheckError("", empId, $"第{rowIndex}行",
                    "当前登陆用户没有权限管理此员工的排班！"));
            }
        }

        await AppendJoinLeaveErrorsAsync(conn, source, monthStr, result.Errors, ct);
        if (result.Errors.Count > 0)
            return result;

        var bulk = BuildBulkTable(source, mark, operatorName);
        await ClearTempAsync(conn, mark, operatorName, ct);
        await BulkInsertTempAsync(conn, bulk, ct);

        result.Errors.AddRange(await ReadCheckFunctionAsync(conn, mark, operatorName, ct));

        if (result.Errors.Count > 0)
        {
            // 有库端校验错误时不保留临时表，避免误提交；用户修正文件后重新预览即可
            await ClearTempAsync(conn, mark, operatorName, ct);
            result.RowCount = 0;
            result.CanCommit = false;
            return result;
        }

        result.RowCount = source.Rows.Count;
        result.CanCommit = true;
        return result;
    }

    public async Task<(bool Ok, string Message)> CommitAsync(string operatorName, string mark,
        CancellationToken ct = default)
    {
        operatorName = (operatorName ?? "").Trim();
        mark = (mark ?? "1042").Trim();
        if (mark.Length > 5) mark = mark[..5];
        await using var conn = new SqlConnection(_connStr);
        await conn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await conn.BeginTransactionAsync(ct);
        try
        {
            await using (var cmd = new SqlCommand("dbo.Import_JobScheduling_Procedure", conn, tx))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@opname", operatorName.Length > 20 ? operatorName[..20] : operatorName);
                cmd.Parameters.AddWithValue("@mark", mark);
                await cmd.ExecuteNonQueryAsync(ct);
            }

            await using (var del = new SqlCommand(
                             "DELETE FROM dbo.Import_TMP_JobScheduling WHERE Mark = @mark AND OPName = @opname",
                             conn, tx))
            {
                del.Parameters.AddWithValue("@mark", mark);
                del.Parameters.AddWithValue("@opname", operatorName);
                await del.ExecuteNonQueryAsync(ct);
            }

            await tx.CommitAsync(ct);
            return (true, "");
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync(ct);
            return (false, ex.Message);
        }
    }

    private static ISheet? LoadSheet(Stream stream, string fileName)
    {
        stream.Position = 0;
        try
        {
            if (fileName.EndsWith(".xls", StringComparison.OrdinalIgnoreCase) &&
                !fileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                var wb = new HSSFWorkbook(stream);
                return wb.GetSheetAt(0);
            }

            var xwb = new XSSFWorkbook(stream);
            return xwb.GetSheetAt(0);
        }
        catch
        {
            return null;
        }
    }

    private static string GetCellValue(ICell? cell)
    {
        if (cell == null) return "";
        try
        {
            switch (cell.CellType)
            {
                case CellType.String:
                    return cell.StringCellValue?.Trim() ?? "";
                case CellType.Numeric:
                    if (DateUtil.IsCellDateFormatted(cell))
                    {
                        var jd = DateUtil.GetJavaDate(cell.NumericCellValue);
                        return jd.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                    }
                    return cell.NumericCellValue.ToString(CultureInfo.InvariantCulture);
                case CellType.Boolean:
                    return cell.BooleanCellValue ? "TRUE" : "FALSE";
                case CellType.Formula:
                    try
                    {
                        if (cell.CachedFormulaResultType == CellType.String)
                            return cell.StringCellValue?.Trim() ?? "";
                        if (cell.CachedFormulaResultType == CellType.Numeric)
                        {
                            if (DateUtil.IsCellDateFormatted(cell))
                            {
                                var jd = DateUtil.GetJavaDate(cell.NumericCellValue);
                                return jd.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                            }
                            return cell.NumericCellValue.ToString(CultureInfo.InvariantCulture);
                        }
                    }
                    catch { /* ignore */ }

                    return cell.ToString()?.Trim() ?? "";
                default:
                    return cell.ToString()?.Trim() ?? "";
            }
        }
        catch
        {
            return "";
        }
    }

    private static async Task<Dictionary<string, DataRow>> LoadShiftsRulesByEmpAsync(SqlConnection conn,
        DataTable source, CancellationToken ct)
    {
        var codes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (DataRow row in source.Rows)
        {
            var c = (row["工号"]?.ToString() ?? "").Trim();
            if (!string.IsNullOrEmpty(c)) codes.Add(c);
        }

        var dict = new Dictionary<string, DataRow>(StringComparer.OrdinalIgnoreCase);
        if (codes.Count == 0) return dict;

        var inList = string.Join(",", codes.Select(c => "'" + c.Replace("'", "''") + "'"));
        var sql = $"""
                   SELECT RTRIM(e.code) AS code, s.MaxShiftsDays, s.MinRestDays, s.is_MinRest, s.is_MaxRest
                   FROM dbo.t_base_employee e
                   LEFT JOIN dbo.att_lst_ShiftsRules s ON e.dept_id = s.DPM_ID
                   WHERE RTRIM(e.code) IN ({inList})
                   """;
        await using var cmd = new SqlCommand(sql, conn);
        using var ad = new Microsoft.Data.SqlClient.SqlDataAdapter(cmd);
        var dt = new DataTable();
        ad.Fill(dt);
        foreach (DataRow r in dt.Rows)
        {
            var code = (r["code"]?.ToString() ?? "").Trim();
            if (!string.IsNullOrEmpty(code))
                dict[code] = r;
        }

        return dict;
    }

    /// <summary>老系统 AttLstJobScheduling.CheckImportJobScheduling：每行独立 RestDayDt。</summary>
    private static void CheckImportShiftsRules(DataTable source, Dictionary<string, string> outTitleDictionary,
        string month, Dictionary<string, DataRow> rulesByEmp, List<ImportCheckError> errors)
    {
        if (!DateTime.TryParseExact(month + "01", "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None,
                out var monthStart))
            return;
        var date1 = monthStart.AddDays(1 - monthStart.Day);
        var date2 = monthStart.AddMonths(1).AddDays(-1);

        foreach (DataRow row in source.Rows)
        {
            var emp = (row["工号"]?.ToString() ?? "").Trim();
            if (string.IsNullOrEmpty(emp)) continue;
            if (!rulesByEmp.TryGetValue(emp, out var ruleRow) || ruleRow == null) continue;

            var isMaxRest = ruleRow["is_MaxRest"] != DBNull.Value && Convert.ToBoolean(ruleRow["is_MaxRest"]);
            var isMinRest = ruleRow["is_MinRest"] != DBNull.Value && Convert.ToBoolean(ruleRow["is_MinRest"]);
            var maxShiftsDays = isMaxRest && ruleRow["MaxShiftsDays"] != DBNull.Value
                ? Convert.ToInt32(ruleRow["MaxShiftsDays"])
                : 0;
            var minRestDays = isMinRest && ruleRow["MinRestDays"] != DBNull.Value
                ? Convert.ToInt32(ruleRow["MinRestDays"])
                : 0;
            if (!isMaxRest && !isMinRest) continue;

            var restDayDt = new DataTable();
            restDayDt.Columns.Add("daynum", typeof(decimal));
            restDayDt.Columns.Add("SUPPLIER", typeof(string));

            foreach (var item in outTitleDictionary)
            {
                var jobName = (row[item.Key]?.ToString() ?? "").Trim();
                if (jobName == ZeroUuid || string.IsNullOrEmpty(jobName))
                {
                    var dayRow = restDayDt.NewRow();
                    var dayNum = decimal.Parse(Regex.Replace(item.Key, @"[^\d]", ""), CultureInfo.InvariantCulture);
                    dayRow["daynum"] = dayNum;
                    dayRow["SUPPLIER"] = "D" + dayNum + "_ID";
                    restDayDt.Rows.Add(dayRow);
                }
            }

            var check = CheckRestDay(restDayDt, emp, date1, date2, false, maxShiftsDays, minRestDays);
            if (check != null)
                errors.Add(new ImportCheckError("", emp, "第" + (source.Rows.IndexOf(row) + 1) + "行", check));
        }
    }

    private static string? CheckRestDay(DataTable restDayDt, string emp, DateTime date1, DateTime date2,
        bool excludeSat, int maxShiftsDays, int minRestDays)
    {
        if (restDayDt.Rows.Count == 0 && !excludeSat)
            return "工号" + emp.Trim() + "排班出错，连续上班天数大于" + maxShiftsDays + "天，请核对后再进行排班！！！";

        var minRestDay = restDayDt.AsEnumerable()
            .Where(p => p.Field<decimal>("daynum") < date1.Day)
            .Select(p => p.Field<decimal>("daynum")).ToList();
        var maxRestDay = restDayDt.AsEnumerable()
            .Where(p => p.Field<decimal>("daynum") > date2.Day)
            .Select(p => p.Field<decimal>("daynum")).ToList();

        if (maxRestDay.Count == 0)
        {
            var days = (DateTime.DaysInMonth(date2.Year, date2.Month) + 1).ToString();
            var dr = restDayDt.NewRow();
            dr["daynum"] = decimal.Parse(days, CultureInfo.InvariantCulture);
            dr["SUPPLIER"] = "Day" + days + "_ID";
            restDayDt.Rows.Add(dr);
        }

        if (minRestDay.Count == 0)
        {
            var dr = restDayDt.NewRow();
            dr["daynum"] = 0m;
            dr["SUPPLIER"] = "Day0_ID";
            restDayDt.Rows.Add(dr);
        }

        var ordered = restDayDt.AsEnumerable()
            .GroupBy(p => p.Field<decimal>("daynum"))
            .Select(g => g.First())
            .OrderBy(p => p.Field<decimal>("daynum"))
            .ToList();
        if (ordered.Count == 0)
            return null;

        if (minRestDays > 0 && ordered.Count < minRestDays && !excludeSat)
            return "工号" + emp.Trim() + "排班出错，累计休息天数小于" + minRestDays + "天，请核对后再进行排班！！！";

        if (maxShiftsDays > 0)
        {
            for (var i = 0; i < ordered.Count - 1; i++)
            {
                var a = (int)ordered[i].Field<decimal>("daynum");
                var b = (int)ordered[i + 1].Field<decimal>("daynum");
                if (b - a > maxShiftsDays + 1)
                    return "工号" + emp.Trim() + "排班出错，连续上班天数大于" + maxShiftsDays + "天，请核对后再进行排班！！！";
            }
        }

        return null;
    }

    private static async Task<Dictionary<string, Guid>> LoadJobListAsync(SqlConnection conn, CancellationToken ct)
    {
        var map = new Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase);
        await using var cmd = new SqlCommand(
            "SELECT FID, RTRIM(code_name) AS code_name FROM dbo.att_lst_BC_set_code WHERE parent_id IS NOT NULL",
            conn);
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            var name = rd.GetString(1);
            var id = rd.GetGuid(0);
            if (!string.IsNullOrWhiteSpace(name))
                map[name.Trim()] = id;
        }

        return map;
    }

    private static async Task<HashSet<string>> LoadShiftPermissionsAsync(SqlConnection conn, string operatorEmpId,
        CancellationToken ct)
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (string.IsNullOrWhiteSpace(operatorEmpId)) return set;
        await using var cmd = new SqlCommand(
            "SELECT RTRIM(CAST(BCID AS NVARCHAR(36))) FROM dbo.v_att_lst_ShiftsSetting WHERE RTRIM(EMP_ID) = @e",
            conn);
        cmd.Parameters.AddWithValue("@e", operatorEmpId.Trim());
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            if (!rd.IsDBNull(0)) set.Add(rd.GetString(0).Trim());
        }

        return set;
    }

    private static async Task<HashSet<string>> LoadPowerEmpIdsAsync(SqlConnection conn, string operatorDisplayName,
        CancellationToken ct)
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var sql = """
                  SELECT RTRIM(EMP_ID) AS EMP_ID
                  FROM dbo.att_Func_GetPower((SELECT TOP 1 RTRIM(code) FROM dbo.v_t_base_employee WHERE RTRIM(name) = @name))
                  """;
        await using var cmd = new SqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@name", operatorDisplayName);
        try
        {
            await using var rd = await cmd.ExecuteReaderAsync(ct);
            while (await rd.ReadAsync(ct))
            {
                if (!rd.IsDBNull(0)) set.Add(rd.GetString(0).Trim());
            }
        }
        catch
        {
            /* 函数不可用时返回空，后续全部报无权限；与老系统尽量一致 */
        }

        return set;
    }

    private static async Task AppendJoinLeaveErrorsAsync(SqlConnection conn, DataTable source, string month,
        List<ImportCheckError> errors, CancellationToken ct)
    {
        var empList = source.AsEnumerable()
            .Select(r => (r["工号"]?.ToString() ?? "").Trim())
            .Where(x => !string.IsNullOrEmpty(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        if (empList.Count == 0) return;

        var inList = string.Join(",", empList.Select(c => "'" + c.Replace("'", "''") + "'"));
        if (!DateTime.TryParseExact(month + "01", "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None,
                out var startDate))
            return;
        var endDate = startDate.AddMonths(1);

        var sql = $"""
                   SELECT RTRIM(code) AS code, frist_join_date, leave_time
                   FROM dbo.t_base_employee
                   WHERE RTRIM(code) IN ({inList})
                     AND (frist_join_date > @start OR leave_time < @end)
                   """;
        await using var cmd = new SqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@start", startDate);
        cmd.Parameters.AddWithValue("@end", endDate);
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            var codeOut = rd.GetString(0).Trim();
            var startDateOut = rd.GetDateTime(1);
            var leaveRaw = rd.IsDBNull(2) ? null : rd.GetValue(2);
            var endDateOut = leaveRaw == null || leaveRaw == DBNull.Value
                ? new DateTime(2099, 1, 1)
                : Convert.ToDateTime(leaveRaw, CultureInfo.InvariantCulture);

            foreach (DataRow erow in source.Rows)
            {
                if (!codeOut.Equals((erow["工号"]?.ToString() ?? "").Trim(), StringComparison.OrdinalIgnoreCase))
                    continue;

                if (startDate < startDateOut)
                {
                    var day = (startDateOut - startDate).Days;
                    for (; day > 0; day--)
                    {
                        var idCol = "D" + day + "id";
                        if (!source.Columns.Contains(idCol)) continue;
                        var v = erow[idCol]?.ToString() ?? "";
                        if (!string.IsNullOrEmpty(v) && v != ZeroUuid)
                        {
                            errors.Add(new ImportCheckError("", codeOut, startDate.Month + "月" + day + "号",
                                "该员工的入职时间为" + startDateOut.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) +
                                "无法对更早时间进行排班！"));
                        }
                    }
                }

                if (endDate > endDateOut)
                {
                    var day = endDateOut.Day + 1;
                    for (; day < 32; day++)
                    {
                        var idCol = "D" + day + "id";
                        if (!source.Columns.Contains(idCol)) continue;
                        var v = erow[idCol]?.ToString() ?? "";
                        if (!string.IsNullOrEmpty(v) && v != ZeroUuid)
                        {
                            errors.Add(new ImportCheckError("", codeOut, startDate.Month + "月" + day + "号",
                                "该员工的离职时间为" + endDateOut.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) +
                                "无法对更晚时间进行排班！"));
                        }
                    }
                }
            }
        }
    }

    private static DataTable BuildBulkTable(DataTable source, string mark, string opName)
    {
        var t = new DataTable();
        t.Columns.Add("Mark", typeof(string));
        t.Columns.Add("OPName", typeof(string));
        t.Columns.Add("EMP_ID", typeof(string));
        t.Columns.Add("JS_Month", typeof(string));
        for (var i = 1; i <= 31; i++)
        {
            t.Columns.Add("Day" + i + "_ID", typeof(Guid));
            t.Columns.Add("Day" + i + "_Name", typeof(string));
        }

        foreach (DataRow row in source.Rows)
        {
            var nr = t.NewRow();
            nr["Mark"] = mark;
            nr["OPName"] = opName;
            nr["EMP_ID"] = (row["工号"]?.ToString() ?? "").Trim();
            nr["JS_Month"] = (row["月份"]?.ToString() ?? "").Trim();
            for (var i = 1; i <= 31; i++)
            {
                var idCol = "D" + i + "id";
                var nameCol = "D" + i;
                if (source.Columns.Contains(idCol) && row[idCol] != DBNull.Value)
                    nr["Day" + i + "_ID"] = (Guid)row[idCol];
                else
                    nr["Day" + i + "_ID"] = Guid.Parse(ZeroUuid);
                nr["Day" + i + "_Name"] = source.Columns.Contains(nameCol)
                    ? (row[nameCol]?.ToString() ?? "").Trim()
                    : "";
            }

            t.Rows.Add(nr);
        }

        return t;
    }

    private static async Task ClearTempAsync(SqlConnection conn, string mark, string opName, CancellationToken ct)
    {
        await using var cmd = new SqlCommand(
            "DELETE FROM dbo.Import_TMP_JobScheduling WHERE Mark = @mark AND OPName = @op", conn);
        cmd.Parameters.AddWithValue("@mark", mark);
        cmd.Parameters.AddWithValue("@op", opName);
        await cmd.ExecuteNonQueryAsync(ct);
    }

    private static async Task BulkInsertTempAsync(SqlConnection conn, DataTable table, CancellationToken ct)
    {
        using var bulk = new SqlBulkCopy(conn)
        {
            DestinationTableName = "dbo.Import_TMP_JobScheduling",
            BulkCopyTimeout = 600,
        };
        foreach (DataColumn c in table.Columns)
            bulk.ColumnMappings.Add(c.ColumnName, c.ColumnName);
        await bulk.WriteToServerAsync(table, ct);
    }

    private static async Task<List<ImportCheckError>> ReadCheckFunctionAsync(SqlConnection conn, string mark,
        string opName, CancellationToken ct)
    {
        var list = new List<ImportCheckError>();
        var sql = """
                  SELECT TOP 100 ItemID, ItemName, ItemDetail, Reason
                  FROM dbo.Import_JobScheduling_CheckFunction(@mark, @opname)
                  ORDER BY 1
                  """;
        await using var cmd = new SqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@mark", mark);
        cmd.Parameters.AddWithValue("@opname", opName.Length > 20 ? opName[..20] : opName);
        await using var rd = await cmd.ExecuteReaderAsync(ct);
        while (await rd.ReadAsync(ct))
        {
            list.Add(new ImportCheckError(
                rd.IsDBNull(0) ? null : rd.GetValue(0)?.ToString(),
                rd.IsDBNull(1) ? null : rd.GetValue(1)?.ToString(),
                rd.IsDBNull(2) ? null : rd.GetValue(2)?.ToString(),
                rd.IsDBNull(3) ? null : rd.GetValue(3)?.ToString()));
        }

        return list;
    }
}
