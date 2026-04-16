using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using SqlSugar;
using StoneApi.Services;

namespace StoneApi.Controllers;

/// <summary>
/// 人力资源 — 员工入职（新前端原生表单，对齐老系统 Create 主表 + 常用子表）
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HrEmployeeOnboardingController : ControllerBase
{
    private readonly SqlSugarClient _db;
    private readonly IWebHostEnvironment _env;
    private readonly DingTalkOapiDepartmentService _dingDept;
    private readonly DingTalkOapiUserService _dingUser;

    public HrEmployeeOnboardingController(
        SqlSugarClient db,
        IWebHostEnvironment env,
        DingTalkOapiDepartmentService dingDept,
        DingTalkOapiUserService dingUser)
    {
        _db = db;
        _env = env;
        _dingDept = dingDept;
        _dingUser = dingUser;
    }

    /// <summary>multipart 上传工牌/门禁照片（保存入职后按工号写入 wwwroot/images/employeePhotos）。</summary>
    public sealed class EmployeePhotoUploadForm
    {
        public string EmployeeCode { get; set; } = "";
        public IFormFile? BadgePhoto { get; set; }
        public IFormFile? DoorPhoto { get; set; }
    }

    private static bool IsAllowedImage(IFormFile f)
    {
        var ct = f.ContentType ?? "";
        return ct.StartsWith("image/jpeg", StringComparison.OrdinalIgnoreCase)
               || ct.StartsWith("image/png", StringComparison.OrdinalIgnoreCase)
               || ct.StartsWith("image/webp", StringComparison.OrdinalIgnoreCase);
    }

    private static string ImageExtension(IFormFile f)
    {
        var ct = f.ContentType ?? "";
        if (ct.Contains("png", StringComparison.OrdinalIgnoreCase)) return ".png";
        if (ct.Contains("webp", StringComparison.OrdinalIgnoreCase)) return ".webp";
        return ".jpg";
    }

    public class CreateOnboardingRequest
    {
        public string Name { get; set; } = "";
        /// <summary>男 / 女</summary>
        public string Gender { get; set; } = "男";
        public string? BrithDate { get; set; }
        public string? Nation { get; set; }
        public string? NativePlace { get; set; }
        public string? Addr { get; set; }
        public string IDCardType { get; set; } = "身份证";
        public string IdCardNo { get; set; } = "";
        public string? IDCardLicence { get; set; }
        public string? IDCardStartDate { get; set; }
        public string? IDCardEndDate { get; set; }
        public string? NowAddr { get; set; }
        public int IsPartyMember { get; set; }
        public int IsVeteran { get; set; }
        public int Ishandicapped { get; set; }
        public int IsMartyr { get; set; }
        public int IsSingleParent { get; set; }
        public int IsMilitary { get; set; }
        public int IsLowIncomeAid { get; set; }
        public string MobileNo { get; set; } = "";
        public string? PhoneNo { get; set; }
        public Guid CompId { get; set; }
        public Guid DeptId { get; set; }
        public Guid DutyId { get; set; }
        public Guid? RankId { get; set; }
        public string Type { get; set; } = "合同工";
        public string GradeLevel { get; set; } = "L";
        public string FristJoinDate { get; set; } = "";
        public string? EmpNormalDate { get; set; }
        public string? ModifyName { get; set; }

        /// <summary>特种设备操作证类型</summary>
        public string? Specialequipment { get; set; }
        public string? SpecialequipmentDate { get; set; }
        public string? SpecialequipmentPlace { get; set; }
        /// <summary>入职资料</summary>
        public string? EntryInformation { get; set; }

        public string? RecruitingChannel { get; set; }
        public string? School { get; set; }
        public string? Specialty { get; set; }
        public string? EmpEducation { get; set; }
        public string? PoliticalStatus { get; set; }
        public string? MaritalStatus { get; set; }
        public string? EmpTimeCard { get; set; }
        public string? Contact { get; set; }
        public string? ContactTel { get; set; }
        public string? ContactAddr { get; set; }
        /// <summary>介绍人工号等，varchar(10)</summary>
        public string? Reference { get; set; }
        public string? Remake { get; set; }

        public string? ContractType { get; set; }
        public string? ContractStartDate { get; set; }
        public string? ContractEndDate { get; set; }
        public int? ContractPeriod { get; set; }
        public string? ProbationStartDate { get; set; }
        public string? ProbationEndDate { get; set; }
        public int? ProbationPeriod { get; set; }

        // —— 子表 / 扩展 ——
        public string? HealthCertType { get; set; }
        public string? HealthLimitedPeriod { get; set; }
        public string? HealthStartTime { get; set; }
        public string? HealthEndTime { get; set; }

        /// <summary>内招渠道等，写入 t_employee_NetworkRecruiting</summary>
        public string? NetworkRecruiting { get; set; }

        public string? BcId { get; set; }
        public string? DepositBank { get; set; }
        public string? BankBranch { get; set; }
        public string? BankAttribution { get; set; }
        public string? RegionCode { get; set; }

        public string? TrainType { get; set; }
        public string? TrainServicePeriod { get; set; }
        public string? TrainServiceStart { get; set; }
        public string? TrainServiceEnd { get; set; }

        public string? DispatchCompany { get; set; }
        public string? DispatchSettlementMethod { get; set; }
        public string? DispatchCompany2 { get; set; }
        public string? DispatchSettlementMethod2 { get; set; }
    }

    public sealed class UpdateOnboardingRequest : CreateOnboardingRequest
    {
        public Guid Id { get; set; }
    }

    private static string? NullIfEmpty(string? s) =>
        string.IsNullOrWhiteSpace(s) ? null : s.Trim();

    private static string? Trunc(string? s, int max)
    {
        if (string.IsNullOrWhiteSpace(s)) return null;
        s = s.Trim();
        return s.Length <= max ? s : s.Substring(0, max);
    }

    private static DateTime? ParseDate(string? s)
    {
        if (string.IsNullOrWhiteSpace(s)) return null;
        return DateTime.TryParse(s.Trim(), out var d) ? d.Date : null;
    }

    /// <summary>
    /// 性别统一转换：库里是 int（1=男，0=女），前端用 男/女 文本。
    /// </summary>
    private static string GenderToDb(string? gender)
    {
        var s = (gender ?? "").Trim();
        if (string.IsNullOrEmpty(s)) return "1";
        if (s == "男" || s.Equals("m", StringComparison.OrdinalIgnoreCase) || s == "1" || s.Equals("true", StringComparison.OrdinalIgnoreCase))
            return "1";
        if (s == "女" || s.Equals("f", StringComparison.OrdinalIgnoreCase) || s == "0" || s.Equals("false", StringComparison.OrdinalIgnoreCase))
            return "0";
        return "1";
    }

    private static string GenderFromDb(object? v)
    {
        if (v == null || v == DBNull.Value) return "男";
        var s = v.ToString()?.Trim() ?? "";
        if (s == "女" || s == "0" || s.Equals("f", StringComparison.OrdinalIgnoreCase) || s.Equals("female", StringComparison.OrdinalIgnoreCase))
            return "女";
        return "男";
    }

    private static void SaveOnboardingChildren(SqlSugarClient db, string empId, CreateOnboardingRequest req, string op)
    {
        var now = DateTime.Now;

        if (!string.IsNullOrWhiteSpace(req.HealthCertType))
        {
            db.Insertable(new Dictionary<string, object?>
                {
                    ["EMP_ID"] = empId,
                    ["Cert_type"] = req.HealthCertType.Trim(),
                    ["Limited_Period"] = Trunc(req.HealthLimitedPeriod, 20),
                    ["StartTime"] = ParseDate(req.HealthStartTime),
                    ["EndTime"] = ParseDate(req.HealthEndTime),
                    ["ModifyOPName"] = op,
                    ["ModifyDate"] = now,
                })
                .AS("t_employee_HealthCertificate")
                .ExecuteCommand();
        }

        if (!string.IsNullOrWhiteSpace(req.NetworkRecruiting))
        {
            db.Insertable(new Dictionary<string, object?>
                {
                    ["EMP_ID"] = empId,
                    ["NetworkRecruiting"] = Trunc(req.NetworkRecruiting, 300),
                    ["ModifyOPName"] = op,
                    ["ModifyDate"] = now,
                })
                .AS("t_employee_NetworkRecruiting")
                .ExecuteCommand();
        }

        if (!string.IsNullOrWhiteSpace(req.BcId) || !string.IsNullOrWhiteSpace(req.DepositBank) ||
            !string.IsNullOrWhiteSpace(req.BankBranch))
        {
            db.Insertable(new Dictionary<string, object?>
                {
                    ["EMP_ID"] = empId,
                    ["BC_ID"] = Trunc(req.BcId, 30),
                    ["DepositBank"] = Trunc(req.DepositBank, 500),
                    ["Branch"] = Trunc(req.BankBranch, 50),
                    ["Attribution"] = Trunc(req.BankAttribution, 100),
                    ["RegionCode"] = Trunc(req.RegionCode, 10),
                    ["BC_CreateDate"] = now,
                    ["BC_CreateOPName"] = Trunc(op, 20),
                })
                .AS("GZ_Inf_BankCard")
                .ExecuteCommand();
        }

        if (!string.IsNullOrWhiteSpace(req.TrainType) || ParseDate(req.TrainServiceStart) != null ||
            ParseDate(req.TrainServiceEnd) != null)
        {
            db.Insertable(new Dictionary<string, object?>
                {
                    ["EMP_ID"] = empId,
                    ["Train_type"] = Trunc(req.TrainType, 50),
                    ["Service_Period"] = Trunc(req.TrainServicePeriod, 20),
                    ["ServiceStartTime"] = ParseDate(req.TrainServiceStart),
                    ["ServiceEndTime"] = ParseDate(req.TrainServiceEnd),
                    ["ModifyOPName"] = op,
                    ["ModifyDate"] = now,
                })
                .AS("t_employee_TrainService")
                .ExecuteCommand();
        }

        // t_employee_dispatch 主键仅为 EMP_ID：代招有数据时写入 Employ=1，否则写入派遣 Employ=0（与老系统两次保存最终态以代招为准一致）
        db.Ado.ExecuteCommand("DELETE FROM dbo.t_employee_dispatch WHERE EMP_ID = @e",
            new SugarParameter("@e", empId));
        var useHelpEmploy = !string.IsNullOrWhiteSpace(req.DispatchCompany2) ||
                            !string.IsNullOrWhiteSpace(req.DispatchSettlementMethod2);
        if (useHelpEmploy)
        {
            db.Insertable(new Dictionary<string, object?>
                {
                    ["EMP_ID"] = empId,
                    ["DispatchCompany"] = NullIfEmpty(req.DispatchCompany2),
                    ["DispatchSettlementMethod"] = NullIfEmpty(req.DispatchSettlementMethod2),
                    ["Employ"] = true,
                    ["ModifyOPName"] = op,
                    ["ModifyDate"] = now,
                })
                .AS("t_employee_dispatch")
                .ExecuteCommand();
        }
        else if (!string.IsNullOrWhiteSpace(req.DispatchCompany) ||
                 !string.IsNullOrWhiteSpace(req.DispatchSettlementMethod))
        {
            db.Insertable(new Dictionary<string, object?>
                {
                    ["EMP_ID"] = empId,
                    ["DispatchCompany"] = NullIfEmpty(req.DispatchCompany),
                    ["DispatchSettlementMethod"] = NullIfEmpty(req.DispatchSettlementMethod),
                    ["Employ"] = false,
                    ["ModifyOPName"] = op,
                    ["ModifyDate"] = now,
                })
                .AS("t_employee_dispatch")
                .ExecuteCommand();
        }
    }

    private static void DeleteOnboardingChildRows(SqlSugarClient db, string empCode)
    {
        var c = empCode.Trim();
        db.Ado.ExecuteCommand("DELETE FROM dbo.t_employee_HealthCertificate WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", c));
        db.Ado.ExecuteCommand("DELETE FROM dbo.t_employee_NetworkRecruiting WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", c));
        db.Ado.ExecuteCommand(
            "DELETE FROM dbo.GZ_Inf_BankCard WHERE RTRIM(CAST(EMP_ID AS NVARCHAR(20))) = @e",
            new SugarParameter("@e", c));
        db.Ado.ExecuteCommand("DELETE FROM dbo.t_employee_TrainService WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", c));
        db.Ado.ExecuteCommand("DELETE FROM dbo.t_employee_dispatch WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", c));
    }

    private static string? FmtYmd(object? v)
    {
        if (v == null || v == DBNull.Value) return null;
        if (v is DateTime dt) return dt.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        if (DateTime.TryParse(v.ToString(), out var d)) return d.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        return null;
    }

    private static int? ParseNullableInt(object? v)
    {
        if (v == null || v == DBNull.Value) return null;
        if (v is int i) return i;
        return int.TryParse(v.ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var n) ? n : null;
    }

    private static object? RowVal(DataRow row, params string[] names)
    {
        foreach (var n in names)
        {
            if (row.Table.Columns.Contains(n)) return row[n] == DBNull.Value ? null : row[n];
        }

        foreach (DataColumn col in row.Table.Columns)
        {
            foreach (var n in names)
            {
                if (string.Equals(col.ColumnName, n, StringComparison.OrdinalIgnoreCase))
                    return row[col] == DBNull.Value ? null : row[col];
            }
        }

        return null;
    }

    /// <summary>读取在职员工主表 + 子表，供新前端编辑弹窗回填（字段与 create 请求体对齐）。</summary>
    [HttpGet("detail")]
    public IActionResult Detail([FromQuery] Guid id)
    {
        if (id == Guid.Empty)
            return BadRequest(new { code = -1, message = "id 无效" });

        var dt = _db.Ado.GetDataTable(
            "SELECT * FROM dbo.t_base_employee WITH (NOLOCK) WHERE id = @id AND status = 0",
            new SugarParameter("@id", id));
        if (dt.Rows.Count == 0)
            return BadRequest(new { code = -1, message = "未找到在职员工" });

        var r = dt.Rows[0];
        var code = (RowVal(r, "code")?.ToString() ?? "").Trim();
        if (code.Length == 0)
            return BadRequest(new { code = -1, message = "员工工号为空" });

        string? str(params string[] names) => RowVal(r, names)?.ToString()?.Trim();
        int Int32Col(params string[] names)
        {
            var v = RowVal(r, names);
            if (v == null) return 0;
            return int.TryParse(v.ToString(), out var n) ? n : 0;
        }

        Guid? gid(params string[] names)
        {
            var v = RowVal(r, names);
            if (v == null) return null;
            if (v is Guid g) return g == Guid.Empty ? null : g;
            return Guid.TryParse(v.ToString(), out var gg) && gg != Guid.Empty ? gg : null;
        }

        var gradeLevelRaw = (str("GradeLevel") ?? "").Trim();
        var gradeLevelJson =
            gradeLevelRaw.Length >= 1 ? gradeLevelRaw.Substring(0, 1) : "L";

        var data = new Dictionary<string, object?>
        {
            ["id"] = id.ToString(),
            ["code"] = code,
            ["name"] = str("name") ?? "",
            ["gender"] = GenderFromDb(RowVal(r, "gender")),
            ["brithDate"] = FmtYmd(RowVal(r, "brith_date")),
            ["nation"] = str("nation"),
            ["nativePlace"] = str("NativePlace"),
            ["addr"] = str("Addr"),
            ["idCardType"] = string.IsNullOrWhiteSpace(str("IDCardType")) ? "身份证" : str("IDCardType"),
            ["idCardNo"] = str("idcard_no") ?? "",
            ["idCardLicence"] = str("IDCardLicence"),
            ["idCardStartDate"] = FmtYmd(RowVal(r, "IDCardStartDate")),
            ["idCardEndDate"] = FmtYmd(RowVal(r, "IDCardEndDate")),
            ["nowAddr"] = str("nowAddr"),
            ["isPartyMember"] = Int32Col("isPartyMember"),
            ["isVeteran"] = Int32Col("isVeteran"),
            ["ishandicapped"] = Int32Col("ishandicapped"),
            ["isMartyr"] = Int32Col("isMartyr"),
            ["isSingleParent"] = Int32Col("isSingleParent"),
            ["isMilitary"] = Int32Col("isMilitary"),
            ["isLowIncomeAid"] = Int32Col("isLowIncomeAid"),
            ["mobileNo"] = str("mobile_no") ?? "",
            ["phoneNo"] = str("phone_no"),
            ["compId"] = gid("comp_id")?.ToString(),
            ["deptId"] = gid("dept_id")?.ToString(),
            ["dutyId"] = gid("duty_id")?.ToString(),
            ["rankId"] = gid("rank_id")?.ToString(),
            ["type"] = string.IsNullOrWhiteSpace(str("type")) ? "合同工" : str("type"),
            ["gradeLevel"] = gradeLevelJson,
            ["fristJoinDate"] = FmtYmd(RowVal(r, "frist_join_date")),
            ["empNormalDate"] = FmtYmd(RowVal(r, "EMP_NormalDate")),
            ["specialequipment"] = str("specialequipment"),
            ["specialequipmentDate"] = FmtYmd(RowVal(r, "specialequipmentDate")),
            ["specialequipmentPlace"] = str("specialequipmentPlace"),
            ["entryInformation"] = str("entryInformation"),
            ["recruitingChannel"] = str("RecruitingChannel"),
            ["school"] = str("School"),
            ["specialty"] = str("Specialty"),
            ["empEducation"] = str("EMP_Education"),
            ["politicalStatus"] = str("PoliticalStatus"),
            ["maritalStatus"] = str("MaritalStatus"),
            ["empTimeCard"] = str("EMP_TimeCard"),
            ["contact"] = str("Contact"),
            ["contactTel"] = str("ContactTel"),
            ["contactAddr"] = str("ContactAddr"),
            ["reference"] = str("Reference"),
            ["remake"] = str("Remake"),
            ["contractType"] = str("ContractType"),
            ["contractStartDate"] = FmtYmd(RowVal(r, "ContractStartDate")),
            ["contractEndDate"] = FmtYmd(RowVal(r, "ContractEndDate")),
            ["contractPeriod"] = ParseNullableInt(RowVal(r, "ContractPeriod")),
            ["probationStartDate"] = FmtYmd(RowVal(r, "ProbationStartDate")),
            ["probationEndDate"] = FmtYmd(RowVal(r, "ProbationEndDate")),
            ["probationPeriod"] = ParseNullableInt(RowVal(r, "ProbationPeriod")),
        };

        var h = _db.Ado.GetDataTable(
            "SELECT TOP 1 Cert_type, Limited_Period, StartTime, EndTime FROM dbo.t_employee_HealthCertificate WITH (NOLOCK) WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", code));
        if (h.Rows.Count > 0)
        {
            var hr = h.Rows[0];
            data["healthCertType"] = RowVal(hr, "Cert_type")?.ToString()?.Trim();
            data["healthLimitedPeriod"] = RowVal(hr, "Limited_Period")?.ToString()?.Trim();
            data["healthStartTime"] = FmtYmd(RowVal(hr, "StartTime"));
            data["healthEndTime"] = FmtYmd(RowVal(hr, "EndTime"));
        }

        var net = _db.Ado.GetDataTable(
            "SELECT TOP 1 NetworkRecruiting FROM dbo.t_employee_NetworkRecruiting WITH (NOLOCK) WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", code));
        if (net.Rows.Count > 0)
            data["networkRecruiting"] = RowVal(net.Rows[0], "NetworkRecruiting")?.ToString()?.Trim();

        var bank = _db.Ado.GetDataTable(
            "SELECT TOP 1 BC_ID, DepositBank, Branch, Attribution, RegionCode FROM dbo.GZ_Inf_BankCard WITH (NOLOCK) WHERE RTRIM(CAST(EMP_ID AS NVARCHAR(20))) = @e",
            new SugarParameter("@e", code));
        if (bank.Rows.Count > 0)
        {
            var b = bank.Rows[0];
            data["bcId"] = RowVal(b, "BC_ID")?.ToString()?.Trim();
            data["depositBank"] = RowVal(b, "DepositBank")?.ToString()?.Trim();
            data["bankBranch"] = RowVal(b, "Branch")?.ToString()?.Trim();
            data["bankAttribution"] = RowVal(b, "Attribution")?.ToString()?.Trim();
            data["regionCode"] = RowVal(b, "RegionCode")?.ToString()?.Trim();
        }

        var tr = _db.Ado.GetDataTable(
            "SELECT TOP 1 Train_type, Service_Period, ServiceStartTime, ServiceEndTime FROM dbo.t_employee_TrainService WITH (NOLOCK) WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", code));
        if (tr.Rows.Count > 0)
        {
            var t = tr.Rows[0];
            data["trainType"] = RowVal(t, "Train_type")?.ToString()?.Trim();
            data["trainServicePeriod"] = RowVal(t, "Service_Period")?.ToString()?.Trim();
            data["trainServiceStart"] = FmtYmd(RowVal(t, "ServiceStartTime"));
            data["trainServiceEnd"] = FmtYmd(RowVal(t, "ServiceEndTime"));
        }

        var dp = _db.Ado.GetDataTable(
            "SELECT TOP 1 DispatchCompany, DispatchSettlementMethod, Employ FROM dbo.t_employee_dispatch WITH (NOLOCK) WHERE RTRIM(EMP_ID) = @e",
            new SugarParameter("@e", code));
        if (dp.Rows.Count > 0)
        {
            var p = dp.Rows[0];
            var employObj = RowVal(p, "Employ");
            var isHelp = employObj != null && employObj != DBNull.Value &&
                         Convert.ToBoolean(employObj, CultureInfo.InvariantCulture);
            var dc = RowVal(p, "DispatchCompany")?.ToString()?.Trim();
            var dm = RowVal(p, "DispatchSettlementMethod")?.ToString()?.Trim();
            if (isHelp)
            {
                data["dispatchCompany2"] = dc;
                data["dispatchSettlementMethod2"] = dm;
            }
            else
            {
                data["dispatchCompany"] = dc;
                data["dispatchSettlementMethod"] = dm;
            }
        }

        return Ok(new { code = 0, data });
    }

    /// <summary>更新在职员工（主表 + 子表与 create 一致；工号不变）。</summary>
    [HttpPost("update")]
    public IActionResult Update([FromBody] UpdateOnboardingRequest? req)
    {
        if (req == null)
            return BadRequest(new { code = -1, message = "请求体为空" });

        if (req.Id == Guid.Empty)
            return BadRequest(new { code = -1, message = "id 无效" });

        var empDt = _db.Ado.GetDataTable(
            "SELECT TOP 1 id, code FROM dbo.t_base_employee WITH (NOLOCK) WHERE id = @id AND status = 0",
            new SugarParameter("@id", req.Id));
        if (empDt.Rows.Count == 0)
            return BadRequest(new { code = -1, message = "未找到在职员工" });

        var existingCode = (empDt.Rows[0]["code"]?.ToString() ?? "").Trim();
        if (existingCode.Length == 0)
            return BadRequest(new { code = -1, message = "员工工号为空" });

        var name = (req.Name ?? "").Trim();
        if (name.Length == 0)
            return BadRequest(new { code = -1, message = "姓名不能为空" });

        var mobile = (req.MobileNo ?? "").Trim();
        if (!Regex.IsMatch(mobile, @"^1\d{10}$"))
            return BadRequest(new { code = -1, message = "手机号码格式错误" });

        var idCard = (req.IdCardNo ?? "").Trim();
        if (idCard.Length == 0)
            return BadRequest(new { code = -1, message = "证件号码不能为空" });

        if (string.Equals(req.IDCardType?.Trim(), "身份证", StringComparison.Ordinal))
        {
            if (!Regex.IsMatch(idCard, @"^\d{17}[\dXx]$"))
                return BadRequest(new { code = -1, message = "身份证号码格式错误" });
        }

        if (string.IsNullOrWhiteSpace(req.FristJoinDate))
            return BadRequest(new { code = -1, message = "入职日期不能为空" });

        if (req.CompId == Guid.Empty || req.DeptId == Guid.Empty || req.DutyId == Guid.Empty)
            return BadRequest(new { code = -1, message = "公司、部门、岗位不能为空" });

        var dupMobile = _db.Ado.GetInt(
            "SELECT COUNT(1) FROM dbo.t_base_employee WITH (NOLOCK) WHERE mobile_no = @m AND status = 0 AND id <> @id",
            new SugarParameter("@m", mobile), new SugarParameter("@id", req.Id));
        if (dupMobile > 0)
            return BadRequest(new { code = -1, message = "当前手机号码在职人员中已存在" });

        var dupIdc = _db.Ado.GetInt(
            "SELECT COUNT(1) FROM dbo.t_base_employee WITH (NOLOCK) WHERE idcard_no = @idc AND status = 0 AND id <> @id",
            new SugarParameter("@idc", idCard), new SugarParameter("@id", req.Id));
        if (dupIdc > 0)
            return BadRequest(new { code = -1, message = "该证件号码已被其他在职人员使用" });

        var op = string.IsNullOrWhiteSpace(req.ModifyName)
            ? (User?.Identity?.Name ?? "system")
            : req.ModifyName!.Trim();

        var joinDate = ParseDate(req.FristJoinDate);
        if (joinDate == null)
            return BadRequest(new { code = -1, message = "入职日期格式无效" });

        var normalDate = ParseDate(req.EmpNormalDate);
        var gradeRaw = string.IsNullOrWhiteSpace(req.GradeLevel) ? "L" : req.GradeLevel.Trim();
        var gradeChar = gradeRaw.Length >= 1 ? gradeRaw.Substring(0, 1) : "L";
        var firstName = name.Length > 20 ? name.Substring(0, 20) : name;

        var updateRow = new Dictionary<string, object?>
        {
            ["name"] = name,
            ["first_name"] = firstName,
            ["gender"] = GenderToDb(req.Gender),
            ["brith_date"] = ParseDate(req.BrithDate),
            ["nation"] = string.IsNullOrWhiteSpace(req.Nation) ? null : req.Nation.Trim(),
            ["NativePlace"] = NullIfEmpty(req.NativePlace),
            ["Addr"] = NullIfEmpty(req.Addr),
            ["IDCardType"] = string.IsNullOrWhiteSpace(req.IDCardType) ? "身份证" : req.IDCardType.Trim(),
            ["idcard_no"] = idCard,
            ["IDCardLicence"] = NullIfEmpty(req.IDCardLicence),
            ["IDCardStartDate"] = ParseDate(req.IDCardStartDate),
            ["IDCardEndDate"] = ParseDate(req.IDCardEndDate),
            ["nowAddr"] = NullIfEmpty(req.NowAddr),
            ["isPartyMember"] = req.IsPartyMember,
            ["isVeteran"] = req.IsVeteran,
            ["ishandicapped"] = req.Ishandicapped,
            ["isMartyr"] = req.IsMartyr,
            ["isSingleParent"] = req.IsSingleParent,
            ["isMilitary"] = req.IsMilitary,
            ["isLowIncomeAid"] = req.IsLowIncomeAid,
            ["mobile_no"] = mobile,
            ["phone_no"] = NullIfEmpty(req.PhoneNo),
            ["comp_id"] = req.CompId,
            ["dept_id"] = req.DeptId,
            ["duty_id"] = req.DutyId,
            ["rank_id"] = req.RankId.HasValue && req.RankId.Value != Guid.Empty ? req.RankId : null,
            ["type"] = string.IsNullOrWhiteSpace(req.Type) ? "合同工" : req.Type.Trim(),
            ["GradeLevel"] = gradeChar,
            ["frist_join_date"] = joinDate,
            ["hiredt"] = joinDate,
            ["EMP_NormalDate"] = normalDate,
            ["regularworker_time"] = normalDate,
            ["ModifyTime"] = DateTime.Now,
            ["ModifyName"] = op,
            ["RecruitingChannel"] = Trunc(req.RecruitingChannel, 50),
            ["School"] = Trunc(req.School, 300),
            ["Specialty"] = Trunc(req.Specialty, 80),
            ["EMP_Education"] = Trunc(req.EmpEducation, 50),
            ["PoliticalStatus"] = Trunc(req.PoliticalStatus, 50),
            ["MaritalStatus"] = Trunc(req.MaritalStatus, 20),
            ["EMP_TimeCard"] = Trunc(req.EmpTimeCard, 100),
            ["Contact"] = Trunc(req.Contact, 50),
            ["ContactTel"] = Trunc(req.ContactTel, 50),
            ["ContactAddr"] = Trunc(req.ContactAddr, 300),
            ["Reference"] = Trunc(req.Reference, 10),
            ["Remake"] = Trunc(req.Remake, 300),
            ["ContractType"] = Trunc(req.ContractType, 50),
            ["ContractStartDate"] = ParseDate(req.ContractStartDate),
            ["ContractEndDate"] = ParseDate(req.ContractEndDate),
            ["ContractPeriod"] = req.ContractPeriod,
            ["ProbationStartDate"] = ParseDate(req.ProbationStartDate),
            ["ProbationEndDate"] = ParseDate(req.ProbationEndDate),
            ["ProbationPeriod"] = req.ProbationPeriod,
            ["specialequipment"] = Trunc(req.Specialequipment, 100),
            ["specialequipmentDate"] = ParseDate(req.SpecialequipmentDate),
            ["specialequipmentPlace"] = Trunc(req.SpecialequipmentPlace, 100),
            ["entryInformation"] = Trunc(req.EntryInformation, 800),
        };

        try
        {
            _db.Ado.BeginTran();
            try
            {
                _db.Updateable(updateRow).AS("t_base_employee").Where("id = @id", new { id = req.Id })
                    .ExecuteCommand();
                DeleteOnboardingChildRows(_db, existingCode);
                SaveOnboardingChildren(_db, existingCode, req, op);
                _db.Ado.CommitTran();
            }
            catch
            {
                _db.Ado.RollbackTran();
                throw;
            }
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = "保存失败：" + ex.Message });
        }

        try
        {
            _db.Ado.ExecuteCommand("EXEC dbo.RS_Pro_UpdateEmployeeName @0", existingCode);
        }
        catch
        {
            /* 同 create */
        }

        return Ok(new
        {
            code = 0,
            data = new { id = req.Id, code = existingCode, message = "保存成功" },
        });
    }

    [HttpPost("create")]
    public IActionResult Create([FromBody] CreateOnboardingRequest? req)
    {
        if (req == null)
            return BadRequest(new { code = -1, message = "请求体为空" });

        var name = (req.Name ?? "").Trim();
        if (name.Length == 0)
            return BadRequest(new { code = -1, message = "姓名不能为空" });

        var mobile = (req.MobileNo ?? "").Trim();
        if (!Regex.IsMatch(mobile, @"^1\d{10}$"))
            return BadRequest(new { code = -1, message = "手机号码格式错误" });

        var idCard = (req.IdCardNo ?? "").Trim();
        if (idCard.Length == 0)
            return BadRequest(new { code = -1, message = "证件号码不能为空" });

        if (string.Equals(req.IDCardType?.Trim(), "身份证", StringComparison.Ordinal))
        {
            if (!Regex.IsMatch(idCard, @"^\d{17}[\dXx]$"))
                return BadRequest(new { code = -1, message = "身份证号码格式错误" });
        }

        if (string.IsNullOrWhiteSpace(req.FristJoinDate))
            return BadRequest(new { code = -1, message = "入职日期不能为空" });

        if (req.CompId == Guid.Empty || req.DeptId == Guid.Empty || req.DutyId == Guid.Empty)
            return BadRequest(new { code = -1, message = "公司、部门、岗位不能为空" });

        var dupMobile = _db.Ado.GetInt(
            "SELECT COUNT(1) FROM dbo.t_base_employee WITH (NOLOCK) WHERE mobile_no = @m AND status = 0",
            new SugarParameter("@m", mobile));
        if (dupMobile > 0)
            return BadRequest(new { code = -1, message = "当前手机号码在职人员中已存在" });

        var dupId = _db.Ado.GetInt(
            "SELECT COUNT(1) FROM dbo.t_base_employee WITH (NOLOCK) WHERE idcard_no = @id AND status = 0",
            new SugarParameter("@id", idCard));
        if (dupId > 0)
            return BadRequest(new { code = -1, message = "该证件号码在职记录中已存在，请勿重复录入" });

        string code;
        try
        {
            code = _db.Ado.GetString("SELECT CAST(dbo.ufn_get_employee_code() AS NVARCHAR(20))")?.Trim() ?? "";
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = "生成工号失败：" + ex.Message });
        }

        if (string.IsNullOrEmpty(code))
            return BadRequest(new { code = -1, message = "生成工号为空，请检查 dbo.ufn_get_employee_code" });

        var id = Guid.NewGuid();
        var op = string.IsNullOrWhiteSpace(req.ModifyName)
            ? (User?.Identity?.Name ?? "system")
            : req.ModifyName!.Trim();

        var photoRel = "../../images/employeePhotos/" + code + ".jpg";

        var joinDate = ParseDate(req.FristJoinDate);
        if (joinDate == null)
            return BadRequest(new { code = -1, message = "入职日期格式无效" });

        var normalDate = ParseDate(req.EmpNormalDate);

        var gradeRaw = string.IsNullOrWhiteSpace(req.GradeLevel) ? "L" : req.GradeLevel.Trim();
        var gradeChar = gradeRaw.Length >= 1 ? gradeRaw.Substring(0, 1) : "L";

        var firstName = name.Length > 20 ? name.Substring(0, 20) : name;

        var row = new Dictionary<string, object?>
        {
            ["id"] = id,
            ["name"] = name,
            ["first_name"] = firstName,
            ["code"] = code,
            ["gender"] = GenderToDb(req.Gender),
            ["brith_date"] = ParseDate(req.BrithDate),
            ["nation"] = string.IsNullOrWhiteSpace(req.Nation) ? null : req.Nation.Trim(),
            ["NativePlace"] = NullIfEmpty(req.NativePlace),
            ["Addr"] = NullIfEmpty(req.Addr),
            ["IDCardType"] = string.IsNullOrWhiteSpace(req.IDCardType) ? "身份证" : req.IDCardType.Trim(),
            ["idcard_no"] = idCard,
            ["IDCardLicence"] = NullIfEmpty(req.IDCardLicence),
            ["IDCardStartDate"] = ParseDate(req.IDCardStartDate),
            ["IDCardEndDate"] = ParseDate(req.IDCardEndDate),
            ["nowAddr"] = NullIfEmpty(req.NowAddr),
            ["isPartyMember"] = req.IsPartyMember,
            ["isVeteran"] = req.IsVeteran,
            ["ishandicapped"] = req.Ishandicapped,
            ["isMartyr"] = req.IsMartyr,
            ["isSingleParent"] = req.IsSingleParent,
            ["isMilitary"] = req.IsMilitary,
            ["isLowIncomeAid"] = req.IsLowIncomeAid,
            ["mobile_no"] = mobile,
            ["phone_no"] = NullIfEmpty(req.PhoneNo),
            ["comp_id"] = req.CompId,
            ["dept_id"] = req.DeptId,
            ["duty_id"] = req.DutyId,
            ["rank_id"] = req.RankId.HasValue && req.RankId.Value != Guid.Empty ? req.RankId : null,
            ["type"] = string.IsNullOrWhiteSpace(req.Type) ? "合同工" : req.Type.Trim(),
            ["GradeLevel"] = gradeChar,
            ["frist_join_date"] = joinDate,
            ["hiredt"] = joinDate,
            ["EMP_NormalDate"] = normalDate,
            ["regularworker_time"] = normalDate,
            ["status"] = 0,
            ["add_time"] = DateTime.Now,
            ["add_user"] = op,
            ["ModifyTime"] = DateTime.Now,
            ["ModifyName"] = op,
            ["employee_photo"] = photoRel,
            ["doorban_photo"] = photoRel,
            ["RecruitingChannel"] = Trunc(req.RecruitingChannel, 50),
            ["School"] = Trunc(req.School, 300),
            ["Specialty"] = Trunc(req.Specialty, 80),
            ["EMP_Education"] = Trunc(req.EmpEducation, 50),
            ["PoliticalStatus"] = Trunc(req.PoliticalStatus, 50),
            ["MaritalStatus"] = Trunc(req.MaritalStatus, 20),
            ["EMP_TimeCard"] = Trunc(req.EmpTimeCard, 100),
            ["Contact"] = Trunc(req.Contact, 50),
            ["ContactTel"] = Trunc(req.ContactTel, 50),
            ["ContactAddr"] = Trunc(req.ContactAddr, 300),
            ["Reference"] = Trunc(req.Reference, 10),
            ["Remake"] = Trunc(req.Remake, 300),
            ["ContractType"] = Trunc(req.ContractType, 50),
            ["ContractStartDate"] = ParseDate(req.ContractStartDate),
            ["ContractEndDate"] = ParseDate(req.ContractEndDate),
            ["ContractPeriod"] = req.ContractPeriod,
            ["ProbationStartDate"] = ParseDate(req.ProbationStartDate),
            ["ProbationEndDate"] = ParseDate(req.ProbationEndDate),
            ["ProbationPeriod"] = req.ProbationPeriod,
            ["specialequipment"] = Trunc(req.Specialequipment, 100),
            ["specialequipmentDate"] = ParseDate(req.SpecialequipmentDate),
            ["specialequipmentPlace"] = Trunc(req.SpecialequipmentPlace, 100),
            ["entryInformation"] = Trunc(req.EntryInformation, 800),
        };

        try
        {
            _db.Ado.BeginTran();
            try
            {
                _db.Insertable(new List<Dictionary<string, object?>> { row })
                    .AS("t_base_employee")
                    .ExecuteCommand();
                SaveOnboardingChildren(_db, code, req, op);
                _db.Ado.CommitTran();
            }
            catch
            {
                _db.Ado.RollbackTran();
                throw;
            }
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = "保存失败：" + ex.Message });
        }

        try
        {
            _db.Ado.ExecuteCommand("EXEC dbo.RS_Pro_UpdateEmployeeName @0", code);
        }
        catch
        {
            /* 参数名因库而异；失败不阻断入职 */
        }

        try
        {
            _db.Ado.ExecuteCommand("EXEC dbo.RS_Pro_CreateEmployeeNoviceTask @0", code);
        }
        catch
        {
            /* 同上 */
        }

        return Ok(new
        {
            code = 0,
            data = new { id, code, message = "保存成功" },
        });
    }

    /// <summary>
    /// 上传工牌照、门禁照（需在 create 成功拿到工号后调用）。写入 ContentRoot/wwwroot/images/employeePhotos/，并更新 t_base_employee.employee_photo / doorban_photo。
    /// </summary>
    [HttpPost("upload-photos")]
    [RequestSizeLimit(12_000_000)]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadPhotos([FromForm] EmployeePhotoUploadForm? form,
        CancellationToken cancellationToken)
    {
        if (form == null)
            return BadRequest(new { code = -1, message = "请求体为空" });

        var code = (form.EmployeeCode ?? "").Trim();
        if (code.Length == 0 || code.Length > 12)
            return BadRequest(new { code = -1, message = "工号无效" });

        if (!Regex.IsMatch(code, @"^[A-Za-z0-9]+$"))
            return BadRequest(new { code = -1, message = "工号仅允许字母数字" });

        var exists = _db.Ado.GetInt(
            "SELECT COUNT(1) FROM dbo.t_base_employee WITH (NOLOCK) WHERE code = @c AND status = 0",
            new SugarParameter("@c", code));
        if (exists == 0)
            return BadRequest(new { code = -1, message = "未找到在职员工或工号不存在" });

        var hasBadge = form.BadgePhoto is { Length: > 0 };
        var hasDoor = form.DoorPhoto is { Length: > 0 };
        if (!hasBadge && !hasDoor)
            return BadRequest(new { code = -1, message = "请至少选择一张照片" });

        if (hasBadge && !IsAllowedImage(form.BadgePhoto!))
            return BadRequest(new { code = -1, message = "工牌照片仅支持 JPEG / PNG / WebP" });

        if (hasDoor && !IsAllowedImage(form.DoorPhoto!))
            return BadRequest(new { code = -1, message = "门禁照片仅支持 JPEG / PNG / WebP" });

        var op = User?.Identity?.Name ?? "system";
        var root = Path.Combine(_env.ContentRootPath, "wwwroot", "images", "employeePhotos");
        Directory.CreateDirectory(root);

        try
        {
            if (hasBadge)
            {
                var ext = ImageExtension(form.BadgePhoto!);
                var fileName = code + ext;
                var physical = Path.Combine(root, fileName);
                await using (var fs = System.IO.File.Create(physical))
                    await form.BadgePhoto!.CopyToAsync(fs, cancellationToken);

                var rel = "../../images/employeePhotos/" + fileName;
                _db.Ado.ExecuteCommand(
                    "UPDATE dbo.t_base_employee SET employee_photo = @p, ModifyTime = GETDATE(), ModifyName = @op WHERE code = @c AND status = 0",
                    new SugarParameter("@p", rel),
                    new SugarParameter("@op", op),
                    new SugarParameter("@c", code));
            }

            if (hasDoor)
            {
                var ext = ImageExtension(form.DoorPhoto!);
                var fileName = code + "_door" + ext;
                var physical = Path.Combine(root, fileName);
                await using (var fs = System.IO.File.Create(physical))
                    await form.DoorPhoto!.CopyToAsync(fs, cancellationToken);

                var rel = "../../images/employeePhotos/" + fileName;
                _db.Ado.ExecuteCommand(
                    "UPDATE dbo.t_base_employee SET doorban_photo = @p, ModifyTime = GETDATE(), ModifyName = @op WHERE code = @c AND status = 0",
                    new SugarParameter("@p", rel),
                    new SugarParameter("@op", op),
                    new SugarParameter("@c", code));
            }
        }
        catch (Exception ex)
        {
            return BadRequest(new { code = -1, message = "保存照片失败：" + ex.Message });
        }

        return Ok(new { code = 0, data = new { message = "照片已上传" } });
    }

    public sealed class SyncEmployeeToDingTalkRequest
    {
        public string? EmployeeId { get; set; }
    }

    private const string DingTalkDictCode = "DingTalk_DeptSync";

    private sealed class DingTalkCfgState
    {
        public Guid? DictionaryId { get; set; }
        public bool Enabled { get; set; }
        public string? CorpId { get; set; }
        public string? CorpSecret { get; set; }
        public List<string> MissingKeys { get; } = new();
    }

    private sealed class DictDetailRow
    {
        public string? Name { get; set; }
        public string? Value { get; set; }
    }

    private DingTalkCfgState LoadDingTalkConfig()
    {
        var st = new DingTalkCfgState();
        var idObj = _db.Ado.GetScalar(
            "SELECT id FROM dbo.vben_t_base_dictionary WITH (NOLOCK) WHERE code = @c",
            new SugarParameter("@c", DingTalkDictCode));
        if (idObj == null || idObj == DBNull.Value)
            return st;

        st.DictionaryId = Guid.Parse(idObj.ToString()!, CultureInfo.InvariantCulture);

        var rows = _db.Ado.SqlQuery<DictDetailRow>(
            """
            SELECT LTRIM(RTRIM(name)) AS Name, LTRIM(RTRIM(value)) AS Value
            FROM dbo.vben_t_base_dictionary_detail WITH (NOLOCK)
            WHERE dictionary_id = @did AND (is_stop IS NULL OR is_stop <> '1')
            """,
            new SugarParameter("@did", st.DictionaryId.Value));

        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var r in rows)
        {
            if (!string.IsNullOrEmpty(r.Name))
                map[r.Name!] = r.Value ?? "";
        }

        if (!map.TryGetValue("enabled", out var en))
            st.MissingKeys.Add("enabled");
        else
            st.Enabled = en.Trim() == "1";

        if (!map.TryGetValue("corp_id", out var cid) || string.IsNullOrWhiteSpace(cid))
            st.MissingKeys.Add("corp_id");
        else
            st.CorpId = cid.Trim();

        if (!map.TryGetValue("corp_secret", out var csec) || string.IsNullOrWhiteSpace(csec))
            st.MissingKeys.Add("corp_secret");
        else
            st.CorpSecret = csec.Trim();

        return st;
    }

    private sealed class SyncEmpRow
    {
        public string? EmployeeId { get; set; }
        public string? Code { get; set; }
        public string? Name { get; set; }
        public string? Mobile { get; set; }
        public string? DeptDingTalkId { get; set; }
    }

    /// <summary>
    /// 同步员工到钉钉：按工号(code)作为 userid，存在则更新，不存在则创建。
    /// </summary>
    [HttpPost("sync-to-dingtalk")]
    public async Task<IActionResult> SyncEmployeeToDingTalk([FromBody] SyncEmployeeToDingTalkRequest req, CancellationToken ct)
    {
        var employeeId = (req.EmployeeId ?? "").Trim();
        if (string.IsNullOrWhiteSpace(employeeId))
            return BadRequest(new { code = -1, message = "employeeId 不能为空" });
        if (!Guid.TryParse(employeeId, out _))
            return BadRequest(new { code = -1, message = "employeeId 不是有效 GUID" });

        var st = LoadDingTalkConfig();
        if (st.DictionaryId == null)
            return BadRequest(new { code = -1, message = "未配置数据字典 DingTalk_DeptSync。" });
        if (st.MissingKeys.Count > 0)
            return BadRequest(new { code = -1, message = $"数据字典缺少项：{string.Join("、", st.MissingKeys)}。" });
        if (!st.Enabled)
            return BadRequest(new { code = -1, message = "钉钉同步未启用（enabled != 1）。" });

        var rows = _db.Ado.SqlQuery<SyncEmpRow>(
            """
            SELECT TOP 1
              CAST(e.id AS varchar(50)) AS EmployeeId,
              LTRIM(RTRIM(e.code)) AS Code,
              LTRIM(RTRIM(e.name)) AS Name,
              LTRIM(RTRIM(e.mobile_no)) AS Mobile,
              LTRIM(RTRIM(d.dingtalk_id)) AS DeptDingTalkId
            FROM dbo.t_base_employee e WITH (NOLOCK)
            LEFT JOIN dbo.t_base_department d WITH (NOLOCK) ON e.dept_id = d.id
            WHERE e.id = @id AND e.status = 0
            """,
            new SugarParameter("@id", employeeId));
        var emp = rows.FirstOrDefault();
        if (emp == null)
            return BadRequest(new { code = -1, message = "未找到在职员工记录。" });

        var userId = (emp.Code ?? "").Trim();
        var name = (emp.Name ?? "").Trim();
        var mobile = (emp.Mobile ?? "").Trim();
        var deptDd = (emp.DeptDingTalkId ?? "").Trim();

        if (string.IsNullOrWhiteSpace(userId))
            return BadRequest(new { code = -1, message = "员工工号为空，无法同步钉钉。" });
        if (string.IsNullOrWhiteSpace(name))
            return BadRequest(new { code = -1, message = "员工姓名为空，无法同步钉钉。" });
        if (!Regex.IsMatch(mobile, @"^1\d{10}$"))
            return BadRequest(new { code = -1, message = "员工手机号格式无效，无法同步钉钉。" });
        if (string.IsNullOrWhiteSpace(deptDd) || !long.TryParse(deptDd, out var deptDdId))
            return BadRequest(new { code = -1, message = "员工所属部门未维护有效 dingtalk_id，请先同步部门到钉钉。" });

        JObject tokenJo = await _dingDept.GetTokenAsync(st.CorpId!, st.CorpSecret!, ct).ConfigureAwait(false);
        if (!DingTalkOapiDepartmentService.IsOk(tokenJo))
            return BadRequest(new { code = -1, message = "获取钉钉 access_token 失败：" + DingTalkOapiDepartmentService.ErrString(tokenJo) });
        var token = tokenJo["access_token"]?.ToString();
        if (string.IsNullOrWhiteSpace(token))
            return BadRequest(new { code = -1, message = "钉钉未返回 access_token。" });

        JObject getRes = await _dingUser.GetUserAsync(token, userId, ct).ConfigureAwait(false);
        var ec = getRes["errcode"]?.ToString() ?? "";
        if (ec == "0")
        {
            var upd = await _dingUser.UpdateUserAsync(token, userId, name, mobile, deptDdId, ct).ConfigureAwait(false);
            if (!DingTalkOapiUserService.IsOk(upd))
                return BadRequest(new { code = -1, message = "钉钉更新员工失败：" + DingTalkOapiUserService.ErrString(upd) });
            return Ok(new { code = 0, data = new { message = "已同步到钉钉（更新）", userId } });
        }

        if (ec == "60121")
        {
            var crt = await _dingUser.CreateUserAsync(token, userId, name, mobile, deptDdId, ct).ConfigureAwait(false);
            if (!DingTalkOapiUserService.IsOk(crt))
                return BadRequest(new { code = -1, message = "钉钉创建员工失败：" + DingTalkOapiUserService.ErrString(crt) });
            return Ok(new { code = 0, data = new { message = "已同步到钉钉（新建）", userId } });
        }

        return BadRequest(new { code = -1, message = "查询钉钉员工失败：" + DingTalkOapiUserService.ErrString(getRes) });
    }
}
