@@&&fc_json_loader. 'OCI360_USAGECOSTS_TAGGED_DAILY'
@@&&fc_json_loader. 'OCI360_SERV_RESOURCES'
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
WITH t1 AS (
  SELECT SUM(COSTS$COMPUTEDAMOUNT) COMPUTEDAMOUNT,
         TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') ENDTIMEUTC
  FROM   @main_table@
  WHERE  @filter_predicate@
  GROUP BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')
),
trange as (
  select trunc(min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') max
  FROM   @main_table@
),
tcycle_account AS (
  SELECT /*+ materialize */
         TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$STARTDATE,'&&oci360_tzcolformat.') STARTDATE,
         TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$ENDDATE,'&&oci360_tzcolformat.') ENDDATE
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
  CONNECT BY LEVEL <= NUMMON),
tcycle AS (
  SELECT STARTDATE, ENDDATE  FROM TCYCLE_ACCOUNT
  UNION ALL
  SELECT STARTDATE, ENDDATE
  FROM TCYCLE_GAPS
),
alldays as ( -- Will generate all days between Min and Max Start Time
  SELECT trunc(trange.min,'DD') + (rownum - 1) vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1) <= trange.max - 1  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min) + 1
)
select seq              snap_id,
       TO_CHAR(vdate,   'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1, 'YYYY-MM-DD HH24:MI') end_time,
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
from   t1, tcycle, alldays
WHERE  vdate between tcycle.STARTDATE AND tcycle.ENDDATE -- For each hour frame I get the billing period range
AND    t1.ENDTIMEUTC(+) >= tcycle.STARTDATE AND t1.ENDTIMEUTC(+) < vdate+1 -- The Billing end time must be inside the range until the computed hour
group by seq, vdate
order by seq
}';
END;
/

-----------------------------------------

@@&&oci360_billing_sec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_tag_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Tag: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost until this Day''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
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
@@&&oci360_billing_sec_stop.

-----------------------------------------

@@&&oci360_billing_sec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_comp_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Compartment: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost until this Day''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
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
@@&&oci360_billing_sec_stop.

-----------------------------------------

@@&&oci360_billing_sec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_srvgrp_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service Group: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost until this Day''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
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
@@&&oci360_billing_sec_stop.

-----------------------------------------

@@&&oci360_billing_sec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_srv_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service Name: ' || SERVICENAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[SERVICENAME = ''' || SERVICENAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost until this Day''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
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
@@&&oci360_billing_sec_stop.

-----------------------------------------

@@&&oci360_billing_sec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_rsr_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Resource: ' || NVL(DISPLAYNAME,RESOURCENAME) || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[RESOURCENAME = ''' || RESOURCENAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost until this Day''' || CHR(10) ||
       'DEF chartype = ''AreaChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
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
@@&&oci360_billing_sec_stop.

-----------------------------------------

DEF title = 'Total per cycle'
DEF title_suffix = '&&oci360_billing_between.'
DEF main_table = 'OCI360_USAGECOSTS'
DEF vaxis = 'Cost (&&oci360_billing_currency.)'
EXEC :sql_text := REPLACE(:sql_text_backup, '@main_table@', q'[OCI360_USAGECOSTS]');
EXEC :sql_text := REPLACE(:sql_text, '@filter_predicate@', q'[1 = 1]');
DEF tit_01 = 'Total Cost until this Day'
DEF chartype = 'AreaChart'
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------
UNDEF oci360_billing_currency oci360_billing_date_from oci360_billing_date_to oci360_billing_period

UNDEF oci360_billing_between