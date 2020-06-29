-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
WITH t1 AS ( -- Cost of the resource group by ENDTIME
  SELECT SUM("cost/myCost") COMPUTEDAMOUNT,
         TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   @main_table@
  WHERE  @filter_predicate@
  GROUP BY TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')
),
trange as ( -- Min and Max range of the costs
  select trunc(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') max
  FROM   @main_table@
),
tcycle_account AS (
  SELECT /*+ materialize */
         TO_TIMESTAMP(add_months(trunc(trange.min,'mm'),ROWNUM-1)) STARTDATE,
         TO_TIMESTAMP(add_months(trunc(trange.min,'mm'),ROWNUM)) - numToDSInterval( 1, 'second' ) ENDDATE,
         ROWNUM seq
  FROM   trange
  CONNECT BY LEVEL <= ceil(months_between(trange.max,trange.min)) + 1
  ORDER BY STARTDATE
),
tcycle_gaps AS (
  SELECT CAST(ADD_MONTHS(LAST_START,ROWNUM) AS TIMESTAMP) STARTDATE,
         CAST(ADD_MONTHS(LAST_END,ROWNUM) AS TIMESTAMP)   ENDDATE
  FROM   (SELECT MAX(STARTDATE) LAST_START,
                 MAX(ENDDATE)   LAST_END,
                 CEIL(MONTHS_BETWEEN(TRANGE.MAX,MAX(ENDDATE))) NUMMON
          FROM TCYCLE_ACCOUNT, TRANGE
          GROUP BY TRANGE.MAX)
  WHERE  NUMMON >= 0
  CONNECT BY LEVEL <= NUMMON + 3
),
tcycle AS (
  SELECT STARTDATE, ENDDATE, SEQ FROM TCYCLE_ACCOUNT
  UNION ALL
  SELECT STARTDATE, ENDDATE, RANK() OVER (ORDER BY ENDDATE ASC) + LAST SEQ 
  FROM TCYCLE_GAPS, (SELECT MAX(SEQ) LAST FROM TCYCLE_ACCOUNT)
),
result AS (
  select seq snap_id,
         TO_CHAR(ENDDATE, 'YYYY-MM-DD') bar_name,
         TO_CHAR(STARTDATE, 'YYYY-MM-DD HH24:MI') || ' - ' || TO_CHAR(ENDDATE, 'YYYY-MM-DD HH24:MI') bar_desc,
         TO_CHAR(NVL(CEIL(SUM(COMPUTEDAMOUNT)*100)/100,0),'99999990D00') bar_value,
         CASE WHEN STARTDATE > min AND ENDDATE < max THEN 'Y' ELSE 'N' END completed -- Check for incomplete periods
  from   t1, tcycle, trange
  WHERE  t1.ENDTIMEUTC(+) >= tcycle.STARTDATE AND t1.ENDTIMEUTC(+) < tcycle.ENDDATE -- The Billing end time must be inside the range until the computed hour
    AND  (tcycle.STARTDATE between trange.min and trange.max OR tcycle.ENDDATE between trange.min and trange.max)
  group by seq, tcycle.STARTDATE, tcycle.ENDDATE, min, max
  order by seq
),
statistics as (
  select REGR_SLOPE(bar_value,snap_id) slope,
         REGR_INTERCEPT(bar_value,snap_id) intercept
  from   result
  where  completed = 'Y' -- Don't consider incomplete periods for calc
),
result_next3 as (
  select seq snap_id,
         TO_CHAR(ENDDATE, 'YYYY-MM-DD') bar_name,
         TO_CHAR(STARTDATE, 'YYYY-MM-DD HH24:MI') || ' - ' || TO_CHAR(ENDDATE, 'YYYY-MM-DD HH24:MI') bar_desc,
         TO_CHAR(NVL(CEIL((slope*seq+intercept)*100)/100,0),'99999990D00') bar_value -- Linear Regression calculate.
  from   tcycle, trange, statistics
  WHERE  (tcycle.STARTDATE >= trange.max OR tcycle.ENDDATE >= trange.max)
    and  slope is not null and intercept is not null
  group by seq, tcycle.STARTDATE, tcycle.ENDDATE, slope, intercept
  order by seq
),
result_final as (
  select snap_id,
         bar_name,
         bar_value,
         '&&oci360_usage_currency. ' || bar_value bar_desc,
         'opacity: 0.6' colour
  from   result
  where  completed = 'Y'
  union all
  select snap_id,
         bar_name,
         bar_value,
         '&&oci360_usage_currency. ' || bar_value bar_desc,
         'color: #703593; opacity: 0.6' colour
  from   result_next3
  where  rownum <= 3
)
select bar_name, bar_value, colour, bar_desc
from   result_final
order by snap_id
}';
END;
/

-----------------------------------------

DEF title = 'Total Costs'
DEF title_suffix = '&&oci360_usage_between.'
DEF main_table = 'OCI360_REPORTS_COST'
DEF vaxis = 'Cost (&&oci360_usage_currency.)'
EXEC :sql_text := REPLACE(:sql_text_backup, '@main_table@', 'OCI360_REPORTS_COST');
EXEC :sql_text := REPLACE(:sql_text, '@filter_predicate@', '1 = 1');
DEF bar_minperc = 0
DEF foot = 'Bars in purple are estimations using linear regression from previous values.'
DEF hAxis = 'Billing Cycle - End Date'
DEF skip_bch = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Compartment: ' || COMP_NAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[' || FILTER_CLAUSE || ']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
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

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service: ' || SRV_NAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[' || FILTER_CLAUSE || ']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
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

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Product: ' || SKU_ID || ' - ' || SKU_DESC || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''["cost/productSku" = ''' || SKU_ID || ''']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
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

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_usage_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Resource: ' || RES_ID || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_COST''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_usage_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_REPORTS_COST]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[' || FILTER_CLAUSE || ']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
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