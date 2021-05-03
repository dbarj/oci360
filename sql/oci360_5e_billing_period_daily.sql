-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_USAGECOSTS_TAGGED_DAILY'
@@&&fc_table_loader. 'OCI360_USAGECOSTS'
@@&&fc_table_loader. 'OCI360_SERV_RESOURCES'
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
alldays as ( -- Will generate all days between Min and Max Start Time
  SELECT trunc(trange.min,'DD') + (rownum - 1) vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1) <= trange.max - 1  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min) + 1
),
result as (
  select seq              snap_id,
         TO_CHAR(vdate,  'YYYY-MM-DD HH24:MI') begin_time,
         TO_CHAR(vdate+1,'YYYY-MM-DD HH24:MI') end_time,
         TO_CHAR(NVL(CEIL(SUM(COMPUTEDAMOUNT)*100)/100,0),'99999990D00') line1
  from   t1, alldays
  where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+) < vdate+1
  group by seq, vdate
),
statistics as (
  select REGR_SLOPE(line1,snap_id) slope,
         REGR_INTERCEPT(line1,snap_id) intercept
  from   result
)
select snap_id,
       begin_time,
       end_time,
       line1,
       TO_CHAR(CEIL((slope*snap_id+intercept)*100)/100,'99999990D00') line2,
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
from   result, statistics
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
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Day''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
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
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_comp_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Compartment: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Day''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
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
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_srvgrp_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service Group: ' || TAG || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS_TAGGED_DAILY''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS_TAGGED_DAILY]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[TAG = ''' || TAG || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Day''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
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
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_srv_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service Name: ' || SERVICENAME || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[SERVICENAME = ''' || SERVICENAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Day''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
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
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_5e_rsr_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Resource: ' || NVL(DISPLAYNAME,RESOURCENAME) || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_billing_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_USAGECOSTS''' || CHR(10) ||
       'DEF vaxis = ''Cost (&&oci360_billing_currency.)''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@main_table@'', q''[OCI360_USAGECOSTS]'');' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[RESOURCENAME = ''' || RESOURCENAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Cost per Day''' || CHR(10) ||
       'DEF tit_02 = ''Linear Regression Trend''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
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
@@&&oci360_list_subsec_stop.

-----------------------------------------

DEF title = 'Total per day'
DEF title_suffix = '&&oci360_billing_between.'
DEF main_table = 'OCI360_USAGECOSTS'
DEF vaxis = 'Cost (&&oci360_billing_currency.)'
EXEC :sql_text := REPLACE(:sql_text_backup, '@main_table@', q'[OCI360_USAGECOSTS]');
EXEC :sql_text := REPLACE(:sql_text, '@filter_predicate@', q'[1 = 1]');
DEF tit_01 = 'Total Cost per Day'
DEF tit_02 = 'Linear Regression Trend'
DEF chartype = 'AreaChart'
DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF gc_lin_1  = ''
DEF gc_lin_2  = ''
DEF gc_lin_3  = ''
DEF gc_lin_4  = ''
DEF gc_lin_5  = ''
DEF gc_lin_6  = ''
DEF gc_lin_7  = ''
DEF gc_lin_8  = ''
DEF gc_lin_9  = ''
DEF gc_lin_10 = ''
DEF gc_lin_11 = ''
DEF gc_lin_12 = ''
DEF gc_lin_13 = ''
DEF gc_lin_14 = ''
DEF gc_lin_15 = ''

COL gc_lin_1  NEW_V gc_lin_1  NOPRI
COL gc_lin_2  NEW_V gc_lin_2  NOPRI
COL gc_lin_3  NEW_V gc_lin_3  NOPRI
COL gc_lin_4  NEW_V gc_lin_4  NOPRI
COL gc_lin_5  NEW_V gc_lin_5  NOPRI
COL gc_lin_6  NEW_V gc_lin_6  NOPRI
COL gc_lin_7  NEW_V gc_lin_7  NOPRI
COL gc_lin_8  NEW_V gc_lin_8  NOPRI
COL gc_lin_9  NEW_V gc_lin_9  NOPRI
COL gc_lin_10 NEW_V gc_lin_10 NOPRI
COL gc_lin_11 NEW_V gc_lin_11 NOPRI
COL gc_lin_12 NEW_V gc_lin_12 NOPRI
COL gc_lin_13 NEW_V gc_lin_13 NOPRI
COL gc_lin_14 NEW_V gc_lin_14 NOPRI
COL gc_lin_15 NEW_V gc_lin_15 NOPRI

DEF gc_flt_1  = ''
DEF gc_flt_2  = ''
DEF gc_flt_3  = ''
DEF gc_flt_4  = ''
DEF gc_flt_5  = ''
DEF gc_flt_6  = ''
DEF gc_flt_7  = ''
DEF gc_flt_8  = ''
DEF gc_flt_9  = ''
DEF gc_flt_10 = ''
DEF gc_flt_11 = ''
DEF gc_flt_12 = ''
DEF gc_flt_13 = ''
DEF gc_flt_14 = ''
DEF gc_flt_15 = ''

COL gc_flt_1  NEW_V gc_flt_1  NOPRI
COL gc_flt_2  NEW_V gc_flt_2  NOPRI
COL gc_flt_3  NEW_V gc_flt_3  NOPRI
COL gc_flt_4  NEW_V gc_flt_4  NOPRI
COL gc_flt_5  NEW_V gc_flt_5  NOPRI
COL gc_flt_6  NEW_V gc_flt_6  NOPRI
COL gc_flt_7  NEW_V gc_flt_7  NOPRI
COL gc_flt_8  NEW_V gc_flt_8  NOPRI
COL gc_flt_9  NEW_V gc_flt_9  NOPRI
COL gc_flt_10 NEW_V gc_flt_10 NOPRI
COL gc_flt_11 NEW_V gc_flt_11 NOPRI
COL gc_flt_12 NEW_V gc_flt_12 NOPRI
COL gc_flt_13 NEW_V gc_flt_13 NOPRI
COL gc_flt_14 NEW_V gc_flt_14 NOPRI
COL gc_flt_15 NEW_V gc_flt_15 NOPRI

WITH t1 AS (
  SELECT SUM(COSTS$COMPUTEDAMOUNT) COMPUTEDAMOUNT,
         RESOURCENAME
  FROM   OCI360_USAGECOSTS
  GROUP BY RESOURCENAME
), t2 as (
  SELECT /*+ materialize */
         t1.RESOURCENAME,
         nvl(o2.DISPLAYNAME,t1.RESOURCENAME) DISPLAYNAME,
         rank() over (order by t1.COMPUTEDAMOUNT desc, t1.RESOURCENAME) ord
  FROM  t1, (select distinct NAME, DISPLAYNAME from OCI360_SERV_RESOURCES) o2
  where t1.RESOURCENAME = o2.NAME (+)
)
SELECT
 -- Define filters
 (select RESOURCENAME FROM t2 where ord = 1)  gc_flt_1,
 (select RESOURCENAME FROM t2 where ord = 2)  gc_flt_2,
 (select RESOURCENAME FROM t2 where ord = 3)  gc_flt_3,
 (select RESOURCENAME FROM t2 where ord = 4)  gc_flt_4,
 (select RESOURCENAME FROM t2 where ord = 5)  gc_flt_5,
 (select RESOURCENAME FROM t2 where ord = 6)  gc_flt_6,
 (select RESOURCENAME FROM t2 where ord = 7)  gc_flt_7,
 (select RESOURCENAME FROM t2 where ord = 8)  gc_flt_8,
 (select RESOURCENAME FROM t2 where ord = 9)  gc_flt_9,
 (select RESOURCENAME FROM t2 where ord = 10) gc_flt_10,
 (select RESOURCENAME FROM t2 where ord = 11) gc_flt_11,
 (select RESOURCENAME FROM t2 where ord = 12) gc_flt_12,
 (select RESOURCENAME FROM t2 where ord = 13) gc_flt_13,
 (select RESOURCENAME FROM t2 where ord = 14) gc_flt_14,
 (select RESOURCENAME FROM t2 where ord = 15) gc_flt_15,
 -- Define names
 (select DISPLAYNAME  FROM t2 where ord = 1)  gc_lin_1,
 (select DISPLAYNAME  FROM t2 where ord = 2)  gc_lin_2,
 (select DISPLAYNAME  FROM t2 where ord = 3)  gc_lin_3,
 (select DISPLAYNAME  FROM t2 where ord = 4)  gc_lin_4,
 (select DISPLAYNAME  FROM t2 where ord = 5)  gc_lin_5,
 (select DISPLAYNAME  FROM t2 where ord = 6)  gc_lin_6,
 (select DISPLAYNAME  FROM t2 where ord = 7)  gc_lin_7,
 (select DISPLAYNAME  FROM t2 where ord = 8)  gc_lin_8,
 (select DISPLAYNAME  FROM t2 where ord = 9)  gc_lin_9,
 (select DISPLAYNAME  FROM t2 where ord = 10) gc_lin_10,
 (select DISPLAYNAME  FROM t2 where ord = 11) gc_lin_11,
 (select DISPLAYNAME  FROM t2 where ord = 12) gc_lin_12,
 (select DISPLAYNAME  FROM t2 where ord = 13) gc_lin_13,
 (select DISPLAYNAME  FROM t2 where ord = 14) gc_lin_14,
 (select DISPLAYNAME  FROM t2 where ord = 15) gc_lin_15
FROM DUAL;

COL gc_lin_1  CLEAR
COL gc_lin_2  CLEAR
COL gc_lin_3  CLEAR
COL gc_lin_4  CLEAR
COL gc_lin_5  CLEAR
COL gc_lin_6  CLEAR
COL gc_lin_7  CLEAR
COL gc_lin_8  CLEAR
COL gc_lin_9  CLEAR
COL gc_lin_10 CLEAR
COL gc_lin_11 CLEAR
COL gc_lin_12 CLEAR
COL gc_lin_13 CLEAR
COL gc_lin_14 CLEAR
COL gc_lin_15 CLEAR

COL gc_flt_1  CLEAR
COL gc_flt_2  CLEAR
COL gc_flt_3  CLEAR
COL gc_flt_4  CLEAR
COL gc_flt_5  CLEAR
COL gc_flt_6  CLEAR
COL gc_flt_7  CLEAR
COL gc_flt_8  CLEAR
COL gc_flt_9  CLEAR
COL gc_flt_10 CLEAR
COL gc_flt_11 CLEAR
COL gc_flt_12 CLEAR
COL gc_flt_13 CLEAR
COL gc_flt_14 CLEAR
COL gc_flt_15 CLEAR

BEGIN
  :sql_text := q'{
WITH t1 AS (
  SELECT SUM(COSTS$COMPUTEDAMOUNT) COMPUTEDAMOUNT,
         TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') ENDTIMEUTC,
         RESOURCENAME
  FROM   OCI360_USAGECOSTS
  GROUP BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.'), RESOURCENAME
),
trange as (
  select trunc(min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') max
  FROM   OCI360_USAGECOSTS
),
alldays as ( -- Will generate all days between Min and Max Start Time
  SELECT trunc(trange.min,'DD') + (rownum - 1) vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1) <= trange.max - 1  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min) + 1
)
select seq              snap_id,
       TO_CHAR(vdate,  'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1,'YYYY-MM-DD HH24:MI') end_time,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_1.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line1,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_2.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line2,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_3.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line3,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_4.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line4,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_5.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line5,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_6.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line6,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_7.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line7,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_8.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line8,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_9.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line9,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_10.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line10,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_11.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line11,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_12.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line12,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_13.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line13,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_14.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line14,
       TO_CHAR(NVL(CEIL(SUM(DECODE(RESOURCENAME,'&&gc_flt_15.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line15
from   t1, alldays
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+) < vdate+1
group by seq, vdate
order by seq
}';
END;
/

DEF tit_01 = '&&gc_lin_1.'
DEF tit_02 = '&&gc_lin_2.'
DEF tit_03 = '&&gc_lin_3.'
DEF tit_04 = '&&gc_lin_4.'
DEF tit_05 = '&&gc_lin_5.'
DEF tit_06 = '&&gc_lin_6.'
DEF tit_07 = '&&gc_lin_7.'
DEF tit_08 = '&&gc_lin_8.'
DEF tit_09 = '&&gc_lin_9.'
DEF tit_10 = '&&gc_lin_10.'
DEF tit_11 = '&&gc_lin_11.'
DEF tit_12 = '&&gc_lin_12.'
DEF tit_13 = '&&gc_lin_13.'
DEF tit_14 = '&&gc_lin_14.'
DEF tit_15 = '&&gc_lin_15.'

DEF title = 'Top 15 Resources - Total per day'
DEF title_suffix = '&&oci360_billing_between.'
DEF main_table = 'OCI360_USAGECOSTS'
DEF vaxis = 'Cost (&&oci360_billing_currency.)'
DEF chartype = 'AreaChart'
DEF stacked = 'isStacked: true,';
DEF skip_lch = ''
@@&&9a_pre_one.

UNDEF gc_lin_1 gc_lin_2 gc_lin_3 gc_lin_4 gc_lin_5 gc_lin_6 gc_lin_7 gc_lin_8 gc_lin_9 gc_lin_10 gc_lin_11 gc_lin_12 gc_lin_13 gc_lin_14 gc_lin_15
UNDEF gc_flt_1 gc_flt_2 gc_flt_3 gc_flt_4 gc_flt_5 gc_flt_6 gc_flt_7 gc_flt_8 gc_flt_9 gc_flt_10 gc_flt_11 gc_flt_12 gc_flt_13 gc_flt_14 gc_flt_15

-----------------------------------------
UNDEF oci360_billing_currency oci360_billing_date_from oci360_billing_date_to oci360_billing_period

UNDEF oci360_billing_between