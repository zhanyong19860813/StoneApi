/* =========================================================
  紧急回滚方案（建议优先用你数据库备份恢复）

  背景：
    第六段脚本曾错误定位 STUFF 起点，可能导致 dbo.att_pro_DayResult 被大段删除，
    表现为“测试数据全部变旷工”。

  最稳做法：
    1) 用你数据库里“考勤日结存储过程”的备份恢复 dbo.att_pro_DayResult
    2) 然后按顺序重新执行第 1~5 段重构脚本（这些你已验证通过）
    3) 最后再执行已修正定位的第 6 段脚本 refactor_split_rejudge_single_card.sql

  本文件只给出操作顺序清单，不直接改库（避免在已损坏状态下做二次破坏）
========================================================= */

/*
步骤：

【A.恢复主过程到“第5段通过”的版本】
- 如果你之前在数据库里备份过 dbo.att_pro_DayResult：
  直接从备份还原 dbo.att_pro_DayResult（你最熟悉的方式）。

- 如果没有备份，只能退回到 doc 中原始过程再重做：
  1) 用 doc\考勤sql整理\att_pro_DayResult.sql 重新发布 dbo.att_pro_DayResult（CREATE/ALTER）
  2) 依次执行你已通过的脚本：
     - refactor_split_employee_scope.sql
     - refactor_split_expand_jobscheduling.sql
     - refactor_split_update_shift_intervals.sql
     - refactor_split_update_card_records.sql
     - refactor_split_update_overtime_records.sql

【B.确认第5段状态 OK 后，再做第6段】
  执行（已修正版本）：
    - refactor_split_rejudge_single_card.sql

【C.回归测试】
  重新跑你那份 testdata_2cards_4cards_202603.sql 的 A8425 2026-03 测试集，
  并对比重构前后日结结果一致。
*/

