using Dm;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SqlSugar;
using StoneApi.Controllers.QueryModel;
using YourNamespace.Helpers;

namespace StoneApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DataBatchDeleteController : ControllerBase
    {



    

        private readonly SqlSugarClient _db;

        public DataBatchDeleteController(SqlSugarClient db)
        {
            _db = db;
        }


        /// <summary>
        /// 通用批量删除（支持多表、多主键）
        /// </summary>
        /// 
        //[HttpPost("BatchDelete")]
        //public IActionResult DeleteBatch(List<BatchDeleteItem> deleteItems)
        //{
        //    if (deleteItems == null || deleteItems.Count == 0)
        //          return BadRequest("无效的删除请求"); ;

        //    _db.Ado.BeginTran();
        //    try
        //    {
        //        foreach (var item in deleteItems)
        //        {
        //            if (string.IsNullOrWhiteSpace(item.TableName))
        //                throw new ArgumentException("表名不能为空");

        //            if (string.IsNullOrWhiteSpace(item.Key))
        //                throw new ArgumentException("主键不能为空");

        //            //if (!IsValidIdentifier(item.TableName) || !IsValidIdentifier(item.Key))
        //            //    throw new ArgumentException("表名或主键名非法");

        //            if (item.Keys == null || item.Keys.Count == 0)
        //                continue;

        //            // 统一转 string，避免大小写 / Guid 问题
        //            var ids = item.Keys
        //                          .Where(k => !string.IsNullOrWhiteSpace(k))
        //                          .Select(k => k.ToUpper())
        //                          .ToList();

        //            if (ids.Count == 0)
        //                continue;

        //            _db.Deleteable<object>()
        //               .AS(item.TableName)
        //               .In(item.Key, ids)
        //               .ExecuteCommand();
        //        }

        //        _db.Ado.CommitTran();




        //        return Ok(new
        //        {
        //            code = 0, // 对应  
        //            data = new
        //            {
        //               message = "删除成功"
        //            }
        //        });
        //    }
        //    catch
        //    {
        //        _db.Ado.RollbackTran();
        //        throw;
        //    }
        //}



        /// <summary>
        /// 通用批量删除（支持多表、多主键）
        /// </summary>
        /// 
        [HttpPost("BatchDelete")]
        public IActionResult DeleteBatch(List<BatchDeleteItem> deleteItems)
        {
            if (deleteItems == null || deleteItems.Count == 0)
                return BadRequest("无效的删除请求");

            int totalDeleted = 0; // ⭐ 关键：累计删除条数

            _db.Ado.BeginTran();
            try
            {
                foreach (var item in deleteItems)
                {
                    if (string.IsNullOrWhiteSpace(item.TableName))
                        throw new ArgumentException("表名不能为空");

                    if (string.IsNullOrWhiteSpace(item.Key))
                        throw new ArgumentException("主键不能为空");

                    if (item.Keys == null || item.Keys.Count == 0)
                        continue;

                    var ids = item.Keys
                                  .Where(k => !string.IsNullOrWhiteSpace(k))
                                  .Select(k => k.ToUpper())
                                  .ToList();

                    if (ids.Count == 0)
                        continue;

                    // ⭐ 接收 ExecuteCommand 返回值
                    int deleted = _db.Deleteable<object>()
                                     .AS(item.TableName)
                                     .In(item.Key, ids)
                                     .ExecuteCommand();

                    totalDeleted += deleted;
                }

                _db.Ado.CommitTran();

                return Ok(new
                {
                    code = 0,
                    data = new
                    {
                        message = "删除成功",
                        deletedCount = totalDeleted // ⭐ 返回给前端
                    }
                });
            }
            catch
            {
                _db.Ado.RollbackTran();
                throw;
            }
        }


    }
}
