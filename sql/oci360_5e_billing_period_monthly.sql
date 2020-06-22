-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_USAGECOSTS_TAGGED_DAILY'
@@&&fc_json_loader. 'OCI360_USAGECOSTS'
@@&&fc_json_loader. 'OCI360_SERV_RESOURCES'
@@&&fc_json_loader. 'OCI360_ACCOUNTDETAILS'
-----------------------------------------

--- Get some Billing info before starting
@@&&fc_def_empty_var. oci360_billing_currency
@@&&fc_def_empty_var. oci360_billing_date_from
@@&&fc_def_empty_var. oci360_billing_date_to
@@&&fc_def_empty_var. oci360_billing_period

COL oci360_billing_currency NEW_V oci360_billing_currency NOPRI
SELECT distinct CURRENCY oci360_billing_currency
from   OCI360_USAGECOSTS_TAGGED_DAILY;
COL oci360_billing_currency CLEAR

COL oci360_billing_date_from NEW_V oci360_billing_date_from NOPRI
COL oci360_billing_date_to   NEW_V oci360_billing_date_to   NOPRI
COL oci360_billing_period    NEW_V oci360_billing_period    NOPRI
SELECT TO_CHAR(min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'YYYY-MM-DD') oci360_billing_date_from,
       TO_CHAR(max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'YYYY-MM-DD') oci360_billing_date_to,
       EXTRACT(DAY FROM (max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')) - min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')))) oci360_billing_period
from   OCI360_USAGECOSTS_TAGGED_DAILY;
COL oci360_billing_date_from CLEAR
COL oci360_billing_date_to   CLEAR
COL oci360_billing_period    CLEAR

DEF oci360_billing_between = ', between &&oci360_billing_date_from. and &&oci360_billing_date_to.'

-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
WITH t1 AS ( -- Cost of the resource group by ENDTIME
  SELECT SUM(COSTS$COMPUTEDAMOUNT) COMPUTEDAMOUNT,
         TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') ENDTIMEUTC
  FROM   @main_table@
  WHERE  @filter_predicate@
  GROUP BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')
),
trange as ( -- Min and Max range of the costs
  select trunc(min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') max
  FROM   @main_table@
),
tcycle_account AS (
  SELECT /*+ materialize */
         TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$STARTDATE,'&&oci360_tzcolformat.') STARTDATE,
         TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$ENDDATE,'&&oci360_tzcolformat.') ENDDATE,
         rank() over (order by TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$STARTDATE,'&&oci360_tzcolformat.')) seq
  FROM   OCI360_ACCOUNTDETAILS, trange
  WHERE  PURCHASE$ID is not null
    AND  PURCHASE$PURCHASEDRESOURCES$NAME = 'CLOUD_CREDIT_AMOUNT'
  ORDER BY STARTDATE
),
tcycle_gaps AS (
  SELECT CAST(ADD_MONTHS(LAST_START,ROWNUM) AS TIMESTAMP) STARTDATE,
         CAST(ADD_MONTHS(LAST_END,ROWNUM) AS TIMESTAMP) ENDDATE
  FROM   (SELECT MAX(STARTDATE) LAST_START, MAX(ENDDATE) LAST_END, CEIL(MONTHS_BETWEEN(TRANGE.MAX,MAX(ENDDATE))) NUMMON FROM TCYCLE_ACCOUNT, TRANGE GROUP BY TRANGE.MAX)
  WHERE  NUMMON > 0
  CONNECT BY LEVEL <= NUMMON + 3),
tcycle AS (
  SELECT STARTDATE, ENDDATE,SEQ  FROM TCYCLE_ACCOUNT
  UNION ALL
  SELECT STARTDATE, ENDDATE,RANK() OVER (ORDER BY ENDDATE ASC)+ LAST SEQ 
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
         '&&oci360_billing_currency. ' || bar_value bar_desc,
         'opacity: 0.6' colour
  from   result
  where  completed = 'Y'
  union all
  select snap_id,
         bar_name,
         bar_value,
         '&&oci360_billing_currency. ' || bar_value bar_desc,
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

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_tag_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Tag: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   DISTINCT t1.TAG
         FROM     OCI360_USAGECOSTS_TAGGED_DAILY t1
         WHERE EXISTS (SELECT 1 FROM OCI360_USAGECOSTS_TAGGED_DAILY t3 WHERE t3.TAG = t1.TAG HAVING SUM(COSTS$COMPUTEDAMOUNT) > 0)
         AND   t1.TAG not like 'ORCL:%'
         ORDER BY t1.TAG);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Custom Tags - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_comp_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Compartment: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   DISTINCT t1.TAG
         FROM     OCI360_USAGECOSTS_TAGGED_DAILY t1
         WHERE EXISTS (SELECT 1 FROM OCI360_USAGECOSTS_TAGGED_DAILY t3 WHERE t3.TAG = t1.TAG HAVING SUM(COSTS$COMPUTEDAMOUNT) > 0)
         AND   t1.TAG like 'ORCL:OCICompartmentPath=%'
         ORDER BY t1.TAG);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Compartments - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_srvgrp_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service Group: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   DISTINCT t1.TAG
         FROM     OCI360_USAGECOSTS_TAGGED_DAILY t1
         WHERE EXISTS (SELECT 1 FROM OCI360_USAGECOSTS_TAGGED_DAILY t3 WHERE t3.TAG = t1.TAG HAVING SUM(COSTS$COMPUTEDAMOUNT) > 0)
         AND   t1.TAG like 'ORCL:OCIService=%'
         ORDER BY t1.TAG);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Service Groups - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_srv_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service Name: ' || SERVICENAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[SERVICENAME = ''' || SERVICENAME || ''']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   DISTINCT t1.SERVICENAME
         FROM     OCI360_USAGECOSTS t1
         WHERE EXISTS (SELECT 1 FROM OCI360_USAGECOSTS t3 WHERE t3.SERVICENAME = t1.SERVICENAME HAVING SUM(COSTS$COMPUTEDAMOUNT) > 0)
         ORDER BY t1.SERVICENAME);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Services - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_rsr_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Resource: ' || NVL(DISPLAYNAME,RESOURCENAME) || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS''' || CHR(10) ||
       'DEF vAxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[RESOURCENAME = ''' || RESOURCENAME || ''']'');' || CHR(10) ||
       'DEF bar_minperc = 0' || CHR(10) ||
       'DEF foot = ''Bars in purple are estimations using linear regression from previous values.''' || CHR(10) ||
       'DEF hAxis = ''Billing Cycle - End Date''' || CHR(10) ||
       'DEF skip_bch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   DISTINCT t1.RESOURCENAME, t2.DISPLAYNAME
         FROM     OCI360_USAGECOSTS t1, OCI360_SERV_RESOURCES t2
         WHERE    t1.RESOURCENAME = t2.NAME
         AND EXISTS (SELECT 1 FROM OCI360_USAGECOSTS t3 WHERE t3.RESOURCENAME = t1.RESOURCENAME HAVING SUM(COSTS$COMPUTEDAMOUNT) > 0)
         ORDER BY t1.RESOURCENAME);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Resources - Total Costs'
@@&&oci360_list_subsec_stop.

-----------------------------------------

DEF title = 'Total per month'
DEF title_suffix = '&&oci360_billing_between.'
DEF main_table = 'OCI360_USAGECOSTS'
DEF vaxis = 'Cost (&&oci360_billing_currency.)'
EXEC :sql_text := REPLACE(:sql_text_backup, '@main_table@', 'OCI360_USAGECOSTS');
EXEC :sql_text := REPLACE(:sql_text, '@filter_predicate@', '1 = 1');
DEF bar_minperc = 0
DEF foot = 'Bars in purple are estimations using linear regression from previous values.'
DEF hAxis = 'Billing Cycle - End Date'
DEF skip_bch = ''
@@&&9a_pre_one.

-----------------------------------------
UNDEF oci360_billing_currency oci360_billing_date_from oci360_billing_date_to oci360_billing_period

UNDEF oci360_billing_between