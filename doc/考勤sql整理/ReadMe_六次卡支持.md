# 六次卡（三段六次打卡）支持说明

## 一、改动文件一览

| 文件 | 说明 |
|------|------|
| `alter_att_lst_DayResult_add_segment3.sql` | 表结构：增加 BCST3/BCET3/ST3/ET3/attStatus3 等第三段字段 |
| `alter_att_lst_DayResult_add_segment_status.sql` | 表结构：增加 attStatus1/attStatus2（若尚未执行） |
| `procs_20260318/3_att_pro_DayResult_UpdateShiftIntervals.sql` | 班次时间段：支持 sec_num=3 |
| `procs_20260318/4_att_pro_DayResult_UpdateCardRecords.sql` | 刷卡匹配：第三段 [0,0] + sec2/sec3 跨天 [-1,0]、[0,1] |
| `procs_20260318/8_att_pro_DayResult.sql` | 日结主过程：第三段字段、迟到/早退/旷工、最终写入 |
| `v_att_lst_DayResult.sql` | 视图：增加 BCST3/BCET3/ST3/ET3、attStatus3、attStatus3Name |
| `Data_6cards_manual_test.sql` | 六次卡测试数据与执行脚本 |

## 二、执行顺序

1. **表结构**  
   依次执行：  
   - `alter_att_lst_DayResult_add_segment_status.sql`（如尚未执行）  
   - `alter_att_lst_DayResult_add_segment3.sql`

2. **存储过程**  
   依次执行：  
   - `3_att_pro_DayResult_UpdateShiftIntervals.sql`  
   - `4_att_pro_DayResult_UpdateCardRecords.sql`  
   - `8_att_pro_DayResult.sql`

3. **视图**  
   执行 `v_att_lst_DayResult.sql` 中的 ALTER VIEW

4. **测试**  
   执行 `Data_6cards_manual_test.sql`

## 三、跨天 tag 说明

- **[-1, 0]**：上班前一天、下班当天  
- **[0, 0]**：当天上下班  
- **[0, 1]**：当天上班、下班次日  

sec_num=1/2/3 均支持以上三种配置。

## 四、attStatus 取值

- **0**：正常  
- **1**：迟到  
- **2**：早退  
- **3**：漏打卡  
- **NULL**：不适用
