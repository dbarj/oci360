-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_REPORTS_COST'
-----------------------------------------

--- Get some Billing info before starting
@@&&fc_def_empty_var. oci360_usage_currency
@@&&fc_def_empty_var. oci360_usage_date_from
@@&&fc_def_empty_var. oci360_usage_date_to
@@&&fc_def_empty_var. oci360_usage_period

COL oci360_usage_currency NEW_V oci360_usage_currency NOPRI
SELECT distinct "cost/currencyCode" oci360_usage_currency
from   OCI360_REPORTS_COST;
COL oci360_usage_currency CLEAR

@@&&fc_def_empty_var. oci360_usage_date_from
@@&&fc_def_empty_var. oci360_usage_date_to
@@&&fc_def_empty_var. oci360_usage_period

COL oci360_usage_date_from NEW_V oci360_usage_date_from NOPRI
COL oci360_usage_date_to   NEW_V oci360_usage_date_to   NOPRI
COL oci360_usage_period    NEW_V oci360_usage_period    NOPRI

DEF oci360_usage_tzcolformat = 'YYYY-MM-DD"T"HH24:MI"Z"'

SELECT TO_CHAR(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'YYYY-MM-DD') oci360_usage_date_from,
       TO_CHAR(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'YYYY-MM-DD') oci360_usage_date_to,
       EXTRACT(DAY FROM (max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')) - min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')))) oci360_usage_period
from   OCI360_REPORTS_COST;

COL oci360_usage_date_from CLEAR
COL oci360_usage_date_to   CLEAR
COL oci360_usage_period    CLEAR

DEF oci360_usage_between = ', between &&oci360_usage_date_from. and &&oci360_usage_date_to.'

DEF oci360_list_subsec_start = '&&moat369_sw_folder./oci360_fc_list_subsection_start.sql'
DEF oci360_list_subsec_stop  = '&&moat369_sw_folder./oci360_fc_list_subsection_stop.sql'

-----------------------------------------

@@&&fc_call_secion_sub. '&&moat369_sec_id..1' '&&moat369_sw_name._&&moat369_sec_id._cost_period_hourly.sql'  'Per Hour'
@@&&fc_call_secion_sub. '&&moat369_sec_id..2' '&&moat369_sw_name._&&moat369_sec_id._cost_period_daily.sql'   'Per Day'
@@&&fc_call_secion_sub. '&&moat369_sec_id..3' '&&moat369_sw_name._&&moat369_sec_id._cost_period_monthly.sql' 'Per Month'

-----------------------------------------

UNDEF oci360_list_subsec_start oci360_list_subsec_stop oci360_line_cost_prepare

UNDEF oci360_usage_currency oci360_usage_date_from oci360_usage_date_to oci360_usage_period
UNDEF oci360_usage_tzcolformat oci360_usage_between
