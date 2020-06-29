-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
WITH t1 AS (
  SELECT SUM("cost/myCost") COMPUTEDAMOUNT,
         TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   @main_table@
  WHERE  @filter_predicate@
  GROUP BY TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')
),
trange as (
  select trunc(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') max
  FROM   @main_table@
),
allhours as ( -- Will generate all hours between Min and Max Start Time
  SELECT trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
)
select seq              snap_id,
       TO_CHAR(vdate,     'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1/24,'YYYY-MM-DD HH24:MI') end_time,
       TO_CHAR(NVL(CEIL(SUM(COMPUTEDAMOUNT)*100)/100,0),'99999990D00') line1,
       0                   dummy_02,
       0                   dummy_03,
       0                   dummy_04,
       0                   dummy_05,
       0                   dummy_06,
       0                   dummy_07,
       0                   dummy_08,
       0                   dummy_09,
       0                   dummy_10,
       0                   dummy_11,
       0                   dummy_12,
       0                   dummy_13,
       0                   dummy_14,
       0                   dummy_15
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
group by seq, vdate
order by seq
}';
END;
/

-----------------------------------------

DEF oci360_line_cost_prepare = '&&moat369_sw_folder./oci360_fc_line_cost_hourly_prepare.sql'

-----------------------------------------

DEF title = 'Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
EXEC :sql_text := REPLACE(:sql_text_backup, '@main_table@', q'[OCI360_REPORTS_COST]');
EXEC :sql_text := REPLACE(:sql_text, '@filter_predicate@', q'[1 = 1]');
DEF tit_01 = 'Total Cost per Hour'
DEF chartype = 'AreaChart'
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF oci360_lin_prepare_id = '"product/compartmentId"'
DEF oci360_lin_prepare_ds = 'MAX("product/compartmentName")'

@@&&oci360_line_cost_prepare.

DEF title = 'Top Compartments - Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Compartment: ' || COMP_NAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[' || FILTER_CLAUSE || ']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Hour''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   NVL("product/compartmentName",'NULL') COMP_NAME,
                  '"product/compartmentId"' || NVL2("product/compartmentId", ' = ' || DBMS_ASSERT.ENQUOTE_LITERAL("product/compartmentId"),' IS NULL') FILTER_CLAUSE
         FROM     OCI360_REPORTS_COST t1
         GROUP BY "product/compartmentName", "product/compartmentId"
         HAVING SUM("cost/myCost") > 0
         ORDER BY COMP_NAME);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'All Compartments - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

DEF oci360_lin_prepare_id = '"product/service"'
DEF oci360_lin_prepare_ds = '"product/service"'

@@&&oci360_line_cost_prepare.

DEF title = 'Top Services - Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service: ' || SRV_NAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[' || FILTER_CLAUSE || ']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Hour''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   NVL("product/service",'NULL') SRV_NAME,
                  '"product/service"' || NVL2("product/service", ' = ' || DBMS_ASSERT.ENQUOTE_LITERAL("product/service"),' IS NULL') FILTER_CLAUSE
         FROM     OCI360_REPORTS_COST t1
         GROUP BY "product/service"
         HAVING SUM("cost/myCost") > 0
         ORDER BY SRV_NAME);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'All Services - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

DEF oci360_lin_prepare_id = '"cost/productSku"'
DEF oci360_lin_prepare_ds = 'MAX("product/Description")'

@@&&oci360_line_cost_prepare.

DEF title = 'Top Products - Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Product: ' || SKU_ID || ' - ' || SKU_DESC || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''["cost/productSku" = ''' || SKU_ID || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Hour''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   "cost/productSku" SKU_ID, MAX("product/Description") SKU_DESC
         FROM     OCI360_REPORTS_COST
         GROUP BY "cost/productSku"
         HAVING SUM("cost/myCost") > 0
         ORDER BY SKU_DESC);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'All Products - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

DEF oci360_lin_prepare_id = '"product/resourceId"'
DEF oci360_lin_prepare_ds = '"product/resourceId"'

@@&&oci360_line_cost_prepare.

DEF title = 'Top Resources - Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF oci360_lin_prepare_id = ''"cost/productSku"''' || CHR(10) ||
       'DEF oci360_lin_prepare_ds = ''MAX("product/Description")''' || CHR(10) ||
       'DEF oci360_lin_prepare_wh = ''' || FILTER_CLAUSE || '''' || CHR(10) ||
       '@@&&oci360_line_cost_prepare.' || CHR(10) ||
       'DEF title = ''Resource: ' || RES_ID || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF stacked = ''isStacked: true,'';' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   NVL("product/resourceId",'NULL') RES_ID,
                  DECODE(SUBSTR("product/resourceId",1,INSTR("product/resourceId",'.',1,3)-1),
                         'ocid1.volumebackup.oc1',99,
                         'ocid1.bootvolumebackup.oc1',98,
                         'ocid1.volume.oc1',97,
                         'ocid1.bootvolume.oc1',96,
                         1) RES_PRIORITY,
                  '"product/resourceId"' || NVL2("product/resourceId", ' = ''' || DBMS_ASSERT.ENQUOTE_LITERAL("product/resourceId") || '''',' IS NULL') FILTER_CLAUSE
         FROM   OCI360_REPORTS_COST t1
         GROUP BY t1."product/resourceId"
         HAVING SUM(t1."cost/myCost") > 0
         ORDER BY RES_PRIORITY ASC, SUM(t1."cost/myCost") DESC)
WHERE  ROWNUM <= 100 OR RES_PRIORITY=1;
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'All Resources - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

DEF oci360_lin_prepare_id = '"product/region"'
DEF oci360_lin_prepare_ds = '"product/region"'

@@&&oci360_line_cost_prepare.

DEF title = 'Top Regions - Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF oci360_lin_prepare_id = '"product/availabilityDomain"'
DEF oci360_lin_prepare_ds = '"product/availabilityDomain"'

@@&&oci360_line_cost_prepare.

DEF title = 'Top ADs - Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF oci360_lin_prepare_id = ' || DBMS_ASSERT.ENQUOTE_LITERAL(COL_NAME) || CHR(10) ||
       'DEF oci360_lin_prepare_ds = ' || DBMS_ASSERT.ENQUOTE_LITERAL(COL_NAME) || CHR(10) ||
       '@@&&oci360_line_cost_prepare.' || CHR(10) ||
       'DEF title = ''Tag ' || COL_NAME || ' Top 15''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF stacked = ''isStacked: true,''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT '"' || COLUMN_NAME || '"' COL_NAME -- Don't use DBMS_ASSERT.ENQUOTE_NAME because you can't use capitalize option in SQL
         FROM   user_tab_columns
         WHERE  table_name='OCI360_REPORTS_COST'
         AND    COLUMN_NAME like 'tags/%'
         ORDER BY COLUMN_ID);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Tags - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------