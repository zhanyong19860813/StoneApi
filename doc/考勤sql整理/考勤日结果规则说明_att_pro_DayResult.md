## 考勤日结果规则说明（`dbo.att_pro_DayResult`）

适用对象：考勤管理人员、实施/运维人员  
数据来源：SQL Server 存储过程 `dbo.att_pro_DayResult`（以 `doc/考勤sql整理/att_pro_DayResult.sql` 为准）

---

## 1. 日结的输入参数（如何执行日结）

- **`@emp_list NVARCHAR(4000)`**：人员范围
  - `@DayResultType='0'`：按工号日结，传工号列表（逗号分隔，如 `A8425,A8426`）
  - `@DayResultType='1'`：按部门日结，传部门 ID（含子部门）
- **`@DayResultType NVARCHAR(10)`**：
  - `'0'`：按工号日结
  - `'1'`：按部门日结
- **`@attStartDate DATETIME` / `@attEndDate DATETIME`**：日结起止日期
  - **不允许跨月**：若跨月，过程内部会把 `@attEndDate` 截断到 `@attStartDate` 所在月的月底
- **`@op NVARCHAR(200)`**：操作人（工号或姓名）
  - 用途：确定权限范围、记录操作人名称（`OperatorName`）

---

## 2. 人员范围与权限规则（谁会被日结）

日结会先生成一个“可计算人员清单”写入临时表 `@tempemployee`，规则如下：

- **操作人必须能在员工表找到**：从 `t_base_employee` 以 `code=@op` 或 `name LIKE %op%` 查操作人，且 `status=0`。
- **权限过滤**：通过 `att_Func_GetPower(@op_emp_id)` 得到操作人可管理的员工集合，只能日结权限范围内人员。
- **按工号日结（`@DayResultType='0'`）**：
  - `@emp_list` 工号列表 ∩ 权限范围
- **按部门日结（`@DayResultType='1'`）**：
  - `ufn_get_dept_children(@emp_list)`（部门及子部门）∩ 权限范围
- **排除已审核月结果人员**：
  - 若 `att_lst_MonthResult` 中该月 `Fmonth=@attMonth` 且 `approveStatus=1`，则该员工不参与日结。

---

## 3. 日结总体流程（做了哪些事）

`dbo.att_pro_DayResult` 大致按如下顺序执行：

- **3.1 生成“日结初始清单”**：依据排班表展开到每天
- **3.2 写入班次设定时间**（班次时间段）
- **3.3 匹配刷卡记录**（把刷卡映射成上/下班卡）
- **3.4 更新加班记录**（日常/假日/节日）
- **3.5 刷卡合并/校正**（3分钟内合并、一次卡归属判断）
- **3.6 更新请假记录**（带薪/无薪）
- **3.7 迟到/早退/旷工判定**
- **3.8 出勤天数计算**
- **3.9 删除旧结果并写入正式表**（已审核不覆盖）

---

## 4. 排班规则（没有排班就没有日结果）

排班表：`dbo.att_lst_JobScheduling`

- 按月存储：`JS_Month` + `Day1_ID ... Day31_ID`
- 日结会用 **UNPIVOT** 将 DayX 列展开为每天一条记录，再落到临时表 `#t_att_lst_DayResult`
- 只展开 `@attStartDate~@attEndDate` 范围内的日期

---

## 5. 班次设定规则（班次时间段）

班次明细表：`dbo.att_lst_time_interval`

- `pb_code_fid`：班次主表 FID（也就是日结果里的 `ShiftID`）
- `sec_num`：
  - `1`：第一段
  - `2`：第二段（支持“二段班次”）
- 日结果字段：
  - 第一段：`BCST1`（计划上班）、`BCET1`（计划下班）、`begin_time_tag1/end_time_tag1`
  - 第二段：`BCST2`、`BCET2`、`begin_time_tag2/end_time_tag2`
- `begin_time_slot_card / end_time_slot_card`：
  - 标记该段是否要求“上班/下班必须刷卡”

> 说明：过程会写入第 1 段与第 2 段的班次时间，但后续“迟到早退旷工”主要按第 1 段计算（第 2 段的规则需要扩展或另行补丁）。

---

## 6. 刷卡匹配规则（刷卡如何变成 ST/ET）

刷卡表：`dbo.att_lst_Cardrecord`

关键字段：
- `SlotCardDate`：刷卡日期（用于匹配当天）
- `SlotCardTime`：刷卡时间（用于与班次有效窗口比较）

纳入日结的刷卡记录（简化）：
- `SlotCardDate` 在日结范围内，且
  - **正常刷卡**：`CardReason IS NULL`
  - **补卡/审批类**：`CardReason IS NOT NULL AND ISNULL(AppState,0) <> 0`

匹配规则（简化）：
- 班次明细里有“有效刷卡窗口”`valid_begin_time ~ valid_end_time`
- 在窗口内：
  - 取最早的刷卡为上班卡（`ST1` / `ST2`）
  - 取最晚的刷卡为下班卡（`ET1` / `ET2`）
- 对跨天班次，过程内有多段逻辑处理“上班在前一天/下班在次日”的情况（由 `valid_begin_time_tag/valid_end_time_tag` 参与）

特殊处理（节选）：
- 入职当天可能用班次时间补默认上班卡（避免首日被判旷工）
- 休息班但有刷卡，会尝试把刷卡写入显示
- 3分钟内刷卡记录会合并为一次，并校正属于“上班卡/下班卡”

---

## 7. 加班规则（会影响状态与加班字段）

加班表：`dbo.att_lst_OverTime`

- **日常加班**（`fType LIKE '日常加班%'`）
  - `attovertime15=1`，`attStatus=5`，`attDay=1`
- **假日加班**（`fType LIKE '假日加班%'`）
  - `attovertime20=1`，`attStatus=6`，`attDay=1`
- **节日加班**（`fType LIKE '节日加班%'` 且当天为法定假日）
  - `attovertime30=1`，`attStatus=7`，`attDay=1`

说明：
- 加班段也会取当天最早/最晚刷卡写入 `ST1/ET1`（用于显示/校验）
- 存在特殊班次允许节日加班（过程内有固定 ShiftID 白名单）

---

## 8. 请假规则（会覆盖出勤天数/出勤时间）

请假表：`dbo.att_lst_Holiday`  
请假类别：`dbo.att_lst_HolidayCategory`（字段 `HC_Paidleave` 标记带薪/无薪）

- **带薪假（`HC_Paidleave=1`）**：
  - `attDay=1`，`attTime=8`，`attHoliday=1`，记录 `attHolidayID/attHolidayCategory`
  - 特例：出差（示例：`HC_ID='H10'`）在周日不计出勤（过程内写死规则）
- **无薪假（`HC_Paidleave=0`）**：
  - `attDay=0`，`attTime=0`，`attHoliday=1`

---

## 9. 迟到/早退/旷工（异常判定）

阈值：
- `@AbsenteeismTime = 60`（分钟）：迟到或早退超过 60 分钟，会作为旷工判定条件之一

### 9.1 迟到（按第一段）
- 条件（简化）：
  - 班次第一段要求刷上班卡（`sec_num=1 AND begin_time_slot_card=1`）
  - `ST1` 晚于计划上班时间 `BCST1`
- 结果：
  - `attLate = 迟到分钟数`
  - `attStatus = 1`

### 9.2 早退（按第一段）
- 条件（简化）：
  - 班次第一段要求刷下班卡（`sec_num=1 AND end_time_slot_card=1`）
  - `ET1` 早于计划下班时间 `BCET1`
- 结果：
  - `attEarly = 早退分钟数`
  - `attStatus = 2`

### 9.3 旷工/漏卡（按第一段）
满足任一条件会判定旷工（简化）：
- 该刷上班卡但 `ST1` 为空
- 该刷下班卡但 `ET1` 为空
- `attLate > 60` 或 `attEarly > 60`

结果：
- `attAbsenteeism=1`
- `attLate=0`、`attEarly=0`
- `attStatus=3`
- `errorMessage`：
  - 漏打卡 / 没有刷卡记录 / 迟到或早退超过60分钟（根据 `ST1/ET1` 组合）

> 重要说明：此处主要按第一段计算；第二段（`ST2/ET2`）不参与迟到早退旷工判定，需扩展。

---

## 10. 出勤天数（`attDay`）

- 默认：只要 **有排班** 且 **不旷工**，记为 `attDay=1`
- 班次不存在（排班班次在主表找不到）：`attStatus=8` 且 `attDay=0`
- 无薪假：`attDay=0`
- 休息班（ShiftID 全 0）：`attStatus=99`
- 法定假日：`attStatus=4`

---

## 11. 写入正式表与覆盖规则

正式表：`dbo.att_lst_DayResult`

- 写入前会先删除旧结果：
  - 仅删除本次范围内、且在 `@tempemployee` 内的人员
  - **已审核（approval=1）不删除**
  - 若关联钉钉流程处于 `NEW/RUNNING`，不删除（避免覆盖进行中的流程数据）
- 写入后会清理“入职前/离职后”的无效日结果

---

## 12. 常见问题（排查思路）

- **日结没有生成任何数据**：
  - 操作人 `@op` 是否能在 `t_base_employee` 找到且在职
  - 操作人权限是否包含目标员工（`att_Func_GetPower`）
  - 月结果是否已审核导致被排除
  - 排班是否存在（`att_lst_JobScheduling` 的当月 DayX_ID）

- **明明有刷卡但日结果显示“没有刷卡记录”**：
  - 检查刷卡时间存储格式是否符合系统约定
  - 系统通常按 `SlotCardDate` 绑定日期，`SlotCardTime` 仅用于“时间段窗口比较”（常见为 1900-01-01 + time）
  - 检查班次明细的有效刷卡窗口 `valid_begin_time ~ valid_end_time` 是否覆盖刷卡时间

- **二段班次下午迟到没有算**：
  - 过程会写入 `ST2/ET2`，但迟到/早退/旷工主要按第一段计算，需扩展规则或使用补丁版本。

