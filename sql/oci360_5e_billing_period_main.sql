-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_USAGECOSTS_TAGGED_DAILY'
-----------------------------------------

DEF title = 'Distinct Tags, Resources, Services'
DEF main_table = 'OCI360_USAGECOSTS_TAGGED_DAILY'
BEGIN
  :sql_text := q'[
SELECT   DISTINCT TAG, RESOURCENAME, SERVICENAME
FROM     OCI360_USAGECOSTS_TAGGED_DAILY t1
WHERE EXISTS (SELECT 1 FROM OCI360_USAGECOSTS_TAGGED_DAILY t3 WHERE t3.TAG = t1.TAG HAVING SUM(COSTS$COMPUTEDAMOUNT) > 0)
ORDER BY 1,2,3
]';
END;
/

@@&&9a_pre_one.

DEF oci360_list_subsec_start = '&&moat369_sw_folder./oci360_fc_list_subsection_start.sql'
DEF oci360_list_subsec_stop  = '&&moat369_sw_folder./oci360_fc_list_subsection_stop.sql'

@@&&fc_call_secion_sub. '&&moat369_sec_id..1' '&&moat369_sw_name._&&moat369_sec_id._billing_period_hourly.sql'  'Per Hour'
@@&&fc_call_secion_sub. '&&moat369_sec_id..2' '&&moat369_sw_name._&&moat369_sec_id._billing_period_daily.sql'   'Per Day'
@@&&fc_call_secion_sub. '&&moat369_sec_id..3' '&&moat369_sw_name._&&moat369_sec_id._billing_period_monthly.sql' 'Per Month'
@@&&fc_call_secion_sub. '&&moat369_sec_id..4' '&&moat369_sw_name._&&moat369_sec_id._billing_period_cycle.sql'   'Per Cycle'

UNDEF oci360_list_subsec_start oci360_list_subsec_stop