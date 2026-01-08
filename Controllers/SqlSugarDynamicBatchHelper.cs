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
    }
}
