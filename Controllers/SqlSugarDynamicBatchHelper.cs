using Microsoft.Data.SqlClient;
using NPOI.SS.Formula.Functions;
using SqlSugar;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace YourNamespace.Helpers
{
    public class SqlSugarDynamicBatchHelper
    {
        private readonly SqlSugarClient _db;
        private readonly string _logFilePath;

        public SqlSugarDynamicBatchHelper(string connStr, string logFilePath = null)
        {
            _logFilePath = logFilePath ?? "SqlSugarLog.txt";

            _db = new SqlSugarClient(new ConnectionConfig
            {
                ConnectionString = connStr,
                DbType = SqlSugar.DbType.SqlServer,
                IsAutoCloseConnection = true
            });

            // SQL 日志记录
            _db.Aop.OnLogExecuting = (sql, pars) =>
            {
                try
                {
                    string paramStr = "";
                    if (pars != null && pars.Length > 0)
                        paramStr = string.Join(", ", pars.Select(p => $"{p.ParameterName}={p.Value}"));

                    var log = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss}  SQL: {sql}";
                    if (!string.IsNullOrEmpty(paramStr))
                        log += "  Parameters: " + paramStr;

                    File.AppendAllText(_logFilePath, log + Environment.NewLine);
                }
                catch { }
            };
        }

        /// <summary>
        /// 批量保存（新增 / 修改 / 删除）
        /// 后台自动识别新增/修改，支持 GUID 或字符串主键，大小写不敏感
        /// </summary>
        public void SaveBatch(
            string tableName,
            DataTable data,
            string primaryKey,
            DataTable deleteRows = null)
        {
            if (string.IsNullOrWhiteSpace(tableName))
                throw new ArgumentException("表名不能为空");

            if (string.IsNullOrWhiteSpace(primaryKey))
                throw new ArgumentException("主键不能为空");

            if (!IsValidIdentifier(tableName) || !IsValidIdentifier(primaryKey))
                throw new ArgumentException("表名或主键名非法");

            _db.Ado.BeginTran();
            try
            {
                // ========= 删除 =========
                if (deleteRows != null && deleteRows.Rows.Count > 0)
                {
                    if (!deleteRows.Columns.Contains(primaryKey))
                        throw new ArgumentException($"删除表不包含主键列 {primaryKey}");

                    var ids = deleteRows.AsEnumerable()
                        .Select(r => r[primaryKey])
                        .Where(v => v != null && v != DBNull.Value)
                        .Select(v => v.ToString().ToUpper())
                        .ToList();

                    if (ids.Count > 0)
                    {
                        _db.Deleteable<object>()
                           .AS(tableName)
                           .In(primaryKey, ids)
                           .ExecuteCommand();
                    }
                }

                if (data == null || data.Rows.Count == 0)
                {
                    _db.Ado.CommitTran();
                    return;
                }

                if (!data.Columns.Contains(primaryKey))
                    data.Columns.Add(primaryKey, typeof(string)); // 确保主键列存在

                // ========= 获取数据库已存在的主键 =========
                var allIds = data.AsEnumerable()
                                 .Select(r => r[primaryKey])
                                 .Where(v => v != null && v != DBNull.Value)
                                 .Select(v => v.ToString().ToUpper())
                                 .ToList();

                List<string> existIds = new List<string>();
                if (allIds.Count > 0)
                {
                    var idsStr = string.Join(",", allIds.Select(a => $"'{a}'"));
                    var dt = _db.Ado.GetDataTable($"SELECT {primaryKey} FROM {tableName} WHERE {primaryKey} IN ({idsStr})");
                    existIds = dt.AsEnumerable()
                                 .Select(r => r[primaryKey].ToString().ToUpper())
                                 .ToList();
                }

                var insertList = new List<Dictionary<string, object>>();
                var updateList = new List<Dictionary<string, object>>();

                foreach (DataRow row in data.Rows)
                {
                    var dict = new Dictionary<string, object>();
                    foreach (DataColumn col in data.Columns)
                    {
                        var val = row[col];
                        if (val == DBNull.Value)
                        {
                            dict[col.ColumnName] = null;
                        }
                        else if (val is JsonElement je)
                        {
                            dict[col.ColumnName] = je.ValueKind switch
                            {
                                JsonValueKind.String => je.GetString(),
                                JsonValueKind.Number => je.GetRawText(),
                                JsonValueKind.True => true,
                                JsonValueKind.False => false,
                                _ => je.GetRawText()
                            };
                        }
                        else
                        {
                            dict[col.ColumnName] = val;
                        }
                    }

                    var idObj = row[primaryKey];
                    string idStr = idObj != null && idObj != DBNull.Value ? idObj.ToString().ToUpper() : null;

                    if (string.IsNullOrEmpty(idStr) || !existIds.Contains(idStr))
                    {
                        // 新增，如果为空生成 GUID
                        if (string.IsNullOrEmpty(idStr))
                        {
                            var newId = Guid.NewGuid().ToString();
                            dict[primaryKey] = newId;
                            row[primaryKey] = newId;
                        }
                        insertList.Add(dict);
                    }
                    else
                    {
                        // 修改
                        updateList.Add(dict);
                    }
                }

                // ========= 新增 =========
                if (insertList.Count > 0)
                {
                    _db.Insertable(insertList)
                       .AS(tableName)
                       .ExecuteCommand();
                }

                // ========= 修改 =========
                if (updateList.Count > 0)
                {
                    _db.Updateable(updateList)
                       .AS(tableName)
                       .WhereColumns(primaryKey)
                       .ExecuteCommand();
                }

                _db.Ado.CommitTran();
            }
            catch
            {
                _db.Ado.RollbackTran();
                throw;
            }
        }

        private bool IsValidIdentifier(string name)
        {
            return Regex.IsMatch(name, @"^[a-zA-Z_][a-zA-Z0-9_]*$");
        }



        /**************************************************** 批量保存数据 支持多表 begin*******************************/

        public void SaveBatchMultiHighPerformance(List<BatchTableDto> tables)
        {
            if (tables == null || tables.Count == 0)
                throw new ArgumentException("tables不能为空");

            _db.Ado.BeginTran();

            try
            {
                foreach (var table in tables)
                {
                    ProcessTableHighPerformance(
                        table.TableName,
                        table.PrimaryKey,
                        table.Data,
                        table.DeleteRows
                    );
                }

                _db.Ado.CommitTran();
            }
            catch
            {
                _db.Ado.RollbackTran();
                throw;
            }
        }


        private void ProcessTableHighPerformance(
    string tableName,
    string primaryKey,
    DataTable data,
    DataTable deleteRows)
        {
            if (!IsValidIdentifier(tableName) || !IsValidIdentifier(primaryKey))
                throw new ArgumentException("非法表名或主键");

            // ========= 1️⃣ 删除 =========
            if (deleteRows != null && deleteRows.Rows.Count > 0)
            {
                var deleteIds = deleteRows.AsEnumerable()
                    .Select(r => r[primaryKey])
                    .Where(v => v != null && v != DBNull.Value)
                    .Select(v => v.ToString())
                    .ToList();

                foreach (var batch in SplitList(deleteIds, 1000))
                {
                    _db.Deleteable<object>()
                       .AS(tableName)
                       .In(primaryKey, batch)
                       .ExecuteCommand();
                }
            }

            if (data == null || data.Rows.Count == 0)
                return;

            var insertList = new List<Dictionary<string, object>>();
            var updateList = new List<Dictionary<string, object>>();

            foreach (DataRow row in data.Rows)
            {
                var dict = ConvertRowToDictionary(row);

                var idObj = row[primaryKey];
                string idStr = idObj?.ToString();

                if (string.IsNullOrWhiteSpace(idStr))
                {
                    var newId = Guid.NewGuid().ToString();
                    dict[primaryKey] = newId;
                    row[primaryKey] = newId;
                    insertList.Add(dict);
                }
                else
                {
                    updateList.Add(dict);
                }
            }

            // ========= 2️⃣ 批量新增 =========
            foreach (var batch in SplitList(insertList, 1000))
            {
                _db.Insertable(batch)
                   .AS(tableName)
                   .ExecuteCommand();
            }

            // ========= 3️⃣ 批量更新 =========
            foreach (var batch in SplitList(updateList, 1000))
            {
                _db.Updateable(batch)
                   .AS(tableName)
                   .WhereColumns(primaryKey)
                   .ExecuteCommand();
            }
        }

        private Dictionary<string, object> ConvertRowToDictionary(DataRow row)
        {
            var dict = new Dictionary<string, object>();

            foreach (DataColumn col in row.Table.Columns)
            {
                var val = row[col];

                if (val == DBNull.Value)
                {
                    dict[col.ColumnName] = null;
                }
                else if (val is JsonElement je)
                {
                    dict[col.ColumnName] = je.ValueKind switch
                    {
                        JsonValueKind.String => je.GetString(),
                        JsonValueKind.Number => je.GetRawText(),
                        JsonValueKind.True => true,
                        JsonValueKind.False => false,
                        _ => je.GetRawText()
                    };
                }
                else
                {
                    dict[col.ColumnName] = val;
                }
            }

            return dict;
        }

        private List<List<T>> SplitList<T>(List<T> source, int batchSize)
        {
            var result = new List<List<T>>();

            for (int i = 0; i < source.Count; i += batchSize)
            {
                result.Add(source.Skip(i).Take(batchSize).ToList());
            }

            return result;
        }

        /**************************************************** 批量保存数据 支持多表 begin*******************************/

        /**************************************************** 批量保存数据 第二 版本 支持多表 begin*******************************/

        public void SaveBatchMultiUltimate(List<BatchTableDto> tables)
        {
            if (tables == null || tables.Count == 0)
                throw new ArgumentException("tables不能为空");

            _db.Ado.BeginTran();

            try
            {
                foreach (var table in tables)
                {
                    ProcessTableMerge(table);
                }

                _db.Ado.CommitTran();
            }
            catch
            {
                _db.Ado.RollbackTran();
                throw;
            }
        }



        //        private void ProcessTableMerge(BatchTableDto table)
        //        {
        //            if (!IsValidIdentifier(table.TableName) || !IsValidIdentifier(table.PrimaryKey))
        //                throw new ArgumentException("非法表名或主键");

        //            // ========= 1️⃣ 删除 =========
        //            if (table.DeleteRows != null && table.DeleteRows.Rows.Count > 0)
        //            {
        //                var deleteIds = table.DeleteRows.AsEnumerable()
        //                    .Select(r => r[table.PrimaryKey]?.ToString())
        //                    .Where(x => !string.IsNullOrWhiteSpace(x))
        //                    .ToList();

        //                if (deleteIds.Count > 0)
        //                {
        //                    _db.Deleteable<object>()
        //                       .AS(table.TableName)
        //                       .In(table.PrimaryKey, deleteIds)
        //                       .ExecuteCommand();
        //                }
        //            }

        //            if (table.Data == null || table.Data.Rows.Count == 0)
        //                return;

        //            // ========= 2️⃣ 自动生成ID + 转 JSON =========
        //            var list = new List<Dictionary<string, object>>();

        //            foreach (DataRow row in table.Data.Rows)
        //            {
        //                var id = row[table.PrimaryKey]?.ToString();

        //                if (string.IsNullOrWhiteSpace(id))
        //                {
        //                    id = Guid.NewGuid().ToString();
        //                    row[table.PrimaryKey] = id;
        //                }

        //                var dict = table.Data.Columns.Cast<DataColumn>()
        //                    .ToDictionary(
        //                        c => c.ColumnName,
        //                        c => row[c] == DBNull.Value ? null : row[c]
        //                    );

        //                list.Add(dict);
        //            }

        //            string json = System.Text.Json.JsonSerializer.Serialize(list);

        //            // ========= 3️⃣ 构建 MERGE SQL =========
        //            var columns = table.Data.Columns.Cast<DataColumn>()
        //                .Select(c => c.ColumnName)
        //                .ToList();

        //            var nonPkColumns = columns.Where(c => c != table.PrimaryKey).ToList();

        //            string updateSet = string.Join(",",
        //                nonPkColumns.Select(c => $"TARGET.[{c}] = SOURCE.[{c}]"));

        //            string insertCols = string.Join(",", columns.Select(c => $"[{c}]"));

        //            string insertVals = string.Join(",",
        //                columns.Select(c =>
        //                    c == table.PrimaryKey
        //                        ? $"ISNULL(SOURCE.[{c}], NEWID())"
        //                        : $"SOURCE.[{c}]"
        //                ));

        //            // 主键按 UNIQUEIDENTIFIER，其它先按 NVARCHAR(MAX)
        //            string withColumns = string.Join(",",
        //                columns.Select(c =>
        //                    c == table.PrimaryKey
        //                        ? $"[{c}] UNIQUEIDENTIFIER '$.{c}'"
        //                        : $"[{c}] NVARCHAR(MAX) '$.{c}'"
        //                ));

        //            string sql = $@"
        //MERGE INTO [{table.TableName}] AS TARGET
        //USING (
        //    SELECT *
        //    FROM OPENJSON(@json)
        //    WITH (
        //        {withColumns}
        //    )
        //) AS SOURCE
        //ON TARGET.[{table.PrimaryKey}] = SOURCE.[{table.PrimaryKey}]
        //WHEN MATCHED THEN
        //    UPDATE SET {updateSet}
        //WHEN NOT MATCHED THEN
        //    INSERT ({insertCols})
        //    VALUES ({insertVals});";

        //            // ========= 4️⃣ 执行 =========
        //            _db.Ado.ExecuteCommand(sql,
        //                new SugarParameter("@json", json));
        //        }



        //CREATE TYPE dbo.DynamicBatchType AS TABLE
        //(
        //Id NVARCHAR(50) NULL,
        //JsonData NVARCHAR(MAX) NULL
        //)
        /// <summary>
        /// 
        /// </summary>
        /// <param name="table"></param>
        /// <exception cref="ArgumentException"></exception>
        private void ProcessTableMerge(BatchTableDto table)
        {
            if (!IsValidIdentifier(table.TableName) || !IsValidIdentifier(table.PrimaryKey))
                throw new ArgumentException("非法表名或主键");

            // =====================================================
            // 1️⃣ 删除（独立执行，不依赖 Data）
            // =====================================================
            if (table.DeleteRows != null && table.DeleteRows.Rows.Count > 0)
            {
                var deleteIds = new List<Guid>();

                foreach (DataRow row in table.DeleteRows.Rows)
                {
                    // 保险处理：优先按主键列名取
                    object rawValue = null;

                    if (table.DeleteRows.Columns.Contains(table.PrimaryKey))
                    {
                        rawValue = row[table.PrimaryKey];
                    }
                    else if (table.DeleteRows.Columns.Count > 0)
                    {
                        // 如果前端只传了一列，直接取第一列
                        rawValue = row[0];
                    }

                    var value = rawValue?.ToString();

                    if (!string.IsNullOrWhiteSpace(value) && Guid.TryParse(value, out var guid))
                    {
                        deleteIds.Add(guid);
                    }
                }

                if (deleteIds.Count > 0)
                {
                    _db.Deleteable<object>()
                       .AS(table.TableName)
                       .In(table.PrimaryKey, deleteIds)
                       .ExecuteCommand();
                }
            }

            // =====================================================
            // 2️⃣ 如果没有新增/修改数据，直接结束
            // =====================================================
            if (table.Data == null || table.Data.Rows.Count == 0)
                return;

            // =====================================================
            // 3️⃣ 自动生成ID + 转 JSON
            // =====================================================
            var list = new List<Dictionary<string, object>>();

            foreach (DataRow row in table.Data.Rows)
            {
                var id = row[table.PrimaryKey]?.ToString();

                if (string.IsNullOrWhiteSpace(id))
                {
                    id = Guid.NewGuid().ToString();
                    row[table.PrimaryKey] = id;
                }

                var dict = table.Data.Columns.Cast<DataColumn>()
                    .ToDictionary(
                        c => c.ColumnName,
                        c => row[c] == DBNull.Value ? null : row[c]
                    );

                list.Add(dict);
            }

            string json = System.Text.Json.JsonSerializer.Serialize(list);

            // =====================================================
            // 4️⃣ 构建 MERGE SQL
            // =====================================================
            var columns = table.Data.Columns.Cast<DataColumn>()
                .Select(c => c.ColumnName)
                .ToList();

            var nonPkColumns = columns.Where(c => c != table.PrimaryKey).ToList();

            string updateSet = string.Join(",",
                nonPkColumns.Select(c => $"TARGET.[{c}] = SOURCE.[{c}]"));

            string insertCols = string.Join(",", columns.Select(c => $"[{c}]"));

            string insertVals = string.Join(",",
                columns.Select(c =>
                    c == table.PrimaryKey
                        ? $"ISNULL(SOURCE.[{c}], NEWID())"
                        : $"SOURCE.[{c}]"
                ));

            string withColumns = string.Join(",",
                columns.Select(c =>
                    c == table.PrimaryKey
                        ? $"[{c}] UNIQUEIDENTIFIER '$.{c}'"
                        : $"[{c}] NVARCHAR(MAX) '$.{c}'"
                ));

            string sql = $@"
MERGE INTO [{table.TableName}] AS TARGET
USING (
    SELECT *
    FROM OPENJSON(@json)
    WITH (
        {withColumns}
    )
) AS SOURCE
ON TARGET.[{table.PrimaryKey}] = SOURCE.[{table.PrimaryKey}]
WHEN MATCHED THEN
    UPDATE SET {updateSet}
WHEN NOT MATCHED THEN
    INSERT ({insertCols})
    VALUES ({insertVals});";

            // =====================================================
            // 5️⃣ 执行
            // =====================================================
            _db.Ado.ExecuteCommand(sql,
                new SugarParameter("@json", json));
        }

        /**************************************************** 批量保存数据 第二 版本  支持多表 begin*******************************/

    }

    public class BatchTableDto
    {
        public string TableName { get; set; }
        public string PrimaryKey { get; set; }
        public DataTable Data { get; set; }
        public DataTable DeleteRows { get; set; }
    }
}
