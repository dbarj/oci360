-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_REPORTS_USAGE'
-----------------------------------------

DEF oci360_usage_tzcolformat = 'YYYY-MM-DD"T"HH24:MI"Z"'

--- Get some Usage info before starting
@@&&fc_def_empty_var. oci360_usage_date_from
@@&&fc_def_empty_var. oci360_usage_date_to
@@&&fc_def_empty_var. oci360_usage_period

COL oci360_usage_date_from NEW_V oci360_usage_date_from NOPRI
COL oci360_usage_date_to   NEW_V oci360_usage_date_to   NOPRI
COL oci360_usage_period    NEW_V oci360_usage_period    NOPRI

SELECT TO_CHAR(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'YYYY-MM-DD') oci360_usage_date_from,
       TO_CHAR(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'YYYY-MM-DD') oci360_usage_date_to,
       EXTRACT(DAY FROM (max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')) - min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')))) oci360_usage_period
from   OCI360_REPORTS_USAGE;

COL oci360_usage_date_from CLEAR
COL oci360_usage_date_to   CLEAR
COL oci360_usage_period    CLEAR

DEF oci360_usage_between = '&&oci360_usage_date_from. and &&oci360_usage_date_to.'

-----------------------------------------

DEF oci360_list_subsec_start = '&&moat369_sw_folder./oci360_fc_list_subsection_start.sql'
DEF oci360_list_subsec_stop  = '&&moat369_sw_folder./oci360_fc_list_subsection_stop.sql'

-----------------------------------------

DEF title = 'Used Services'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT distinct "product/service" "Service"
FROM   OCI360_REPORTS_USAGE t1
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Used Resources'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT distinct "product/service" "Service", "product/resource" "Resource"
FROM   OCI360_REPORTS_USAGE t1
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Resources Utilization'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT "product/service" "Service",
        "product/resource" "Resource",
        MIN("lineItem/intervalUsageStart") "Date Min",
        MAX("lineItem/intervalUsageStart") "Date Max",
        "usage/consumedQuantityUnits" "Units",
        "usage/consumedQuantityMeasure" "Measure",
        TO_CHAR(SUM("usage/consumedQuantity")) "Total Consumed",
        TO_CHAR(SUM("usage/billedQuantity")) "Total Billed",
        TO_CHAR(SUM("usage/consumedQuantity"-"usage/billedQuantity")) "Total Non-Billed"
FROM   OCI360_REPORTS_USAGE t1
GROUP BY "product/service",
         "product/resource",
         "usage/consumedQuantityUnits",
         "usage/consumedQuantityMeasure"
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Usage Corrections'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REPORTS_USAGE t1
WHERE  "lineItem/isCorrection" != 'false'
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.


-----------------------------------------

DEF title = 'Usage Gaps'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
WITH t1 AS (
  SELECT /*+ materialize */ distinct TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   OCI360_REPORTS_USAGE
),
trange as (
  select trunc(min(ENDTIMEUTC),'HH24') min,
         trunc(max(ENDTIMEUTC),'HH24') max
  FROM   t1
),
allhours as ( /*  Will generate all hours between Min and Max Start Time */
  SELECT trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  /*  Skip last entry as may be incomplete. */
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
)
select seq              snap_id,
       TO_CHAR(vdate,     'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1/24,'YYYY-MM-DD HH24:MI') end_time
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
and    ENDTIMEUTC is null
group by seq, vdate
order by seq
}';
END;
/
DEF foot = 'If this statement return lines, you may have gaps in your utilization results.<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Billed > Consumed'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT "lineItem/intervalUsageStart"
      ,"lineItem/intervalUsageEnd"
      ,"product/service"
      ,"product/resource"
      ,"product/compartmentId"
      ,"product/compartmentName"
      ,"product/region"
      ,"product/availabilityDomain"
      ,"product/resourceId"
      ,TO_CHAR(TO_NUMBER("usage/consumedQuantity"))
      ,TO_CHAR(TO_NUMBER("usage/billedQuantity"))
      ,TO_CHAR(TO_NUMBER("usage/consumedQuantity") - TO_NUMBER("usage/billedQuantity")) "Difference"
      ,"usage/consumedQuantityUnits"
      ,"usage/consumedQuantityMeasure"
FROM   OCI360_REPORTS_USAGE
WHERE  TO_NUMBER("usage/billedQuantity") > TO_NUMBER("usage/consumedQuantity")
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Distinct Objects per Resource'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT resource_product,
       substr(resource_id,1,instr(resource_id,'.',1,4)-1) resource_id_pref,
       count(*) total_distinct_resources
FROM   ( select distinct "product/resource" resource_product, "product/resourceId" resource_id
           from OCI360_REPORTS_USAGE )
GROUP BY resource_product, substr(resource_id,1,instr(resource_id,'.',1,4)-1)
ORDER BY resource_id_pref,resource_product,total_distinct_resources DESC
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Service Resources - Sample lines'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REPORTS_USAGE SAMPLE(0.1) t1
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Non-OCID Resources'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
select distinct "product/resource" resource_product, "product/resourceId" resource_id
from   OCI360_REPORTS_USAGE
where  substr("product/resourceId",1,instr("product/resourceId",'.',1,1)-1) != 'ocid1'
and    "product/resourceId" is not null
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
WITH tot as
(SELECT SUM("usage/consumedQuantity") total_global
   FROM OCI360_REPORTS_USAGE
  where @filter_predicate@
)
SELECT "product/resource" || ' - ' || SUM("usage/consumedQuantity") resource_name,
       SUM("usage/consumedQuantity") total,
       trim(to_char(round(SUM("usage/consumedQuantity")/decode(total_global,0,1,total_global),4)*100,'990D99')) percent
FROM   OCI360_REPORTS_USAGE, tot
where @filter_predicate@
GROUP BY "product/resource",total_global
}';
END;
/

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Service: ' || NAME || ' - ' || UNITS || '''' || CHR(10) ||
       'DEF title_suffix = '' between &&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_USAGE''' || CHR(10) ||
       'DEF vaxis = ''' || UNITS || '''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@filter_predicate@'', q''["product/service" = ''' || NAME || ''' AND TRIM("usage/consumedQuantityUnits" || '' '' || "usage/consumedQuantityMeasure") = ''' || UNITS || ''']'');' || CHR(10) ||
       'DEF skip_pch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( 
SELECT "product/service" NAME,
       TRIM("usage/consumedQuantityUnits" || ' ' || "usage/consumedQuantityMeasure") UNITS
FROM   OCI360_REPORTS_USAGE t1
GROUP BY "product/service",
         "usage/consumedQuantityUnits",
         "usage/consumedQuantityMeasure"
HAVING COUNT(distinct "product/resource") > 1
);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Services - Hourly - Total Usage'
@@&&oci360_list_subsec_stop.

-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
WITH t1 AS (
  SELECT SUM("usage/consumedQuantity") CONSUMED_AMOUNT,
         SUM("usage/billedQuantity") BILLED_AMOUNT,
         TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   OCI360_REPORTS_USAGE
  WHERE  @filter_predicate@
  GROUP BY TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')
),
trange as (
  select trunc(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') max
  FROM   OCI360_REPORTS_USAGE
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
       TO_CHAR(NVL(SUM(CONSUMED_AMOUNT),0)) line1,
       TO_CHAR(NVL(SUM(BILLED_AMOUNT),0))   line2,
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

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Resource: ' || NAME || '''' || CHR(10) ||
       'DEF title_suffix = '' between &&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_USAGE''' || CHR(10) ||
       'DEF vaxis = ''' || UNITS || '''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@filter_predicate@'', q''["product/resource" = ''' || NAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Consumed per Hour''' || CHR(10) ||
       'DEF tit_02 = ''Total Billed per Hour''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT   DISTINCT "product/resource" NAME,
                           "usage/consumedQuantityUnits" || ' ' || "usage/consumedQuantityMeasure" UNITS
         FROM     OCI360_REPORTS_USAGE
         WHERE    "product/resource" IN (SELECT "product/resource" FROM OCI360_REPORTS_USAGE GROUP BY "product/resource" HAVING SUM("usage/consumedQuantity") > 0)
         ORDER BY "product/resource");
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Resources - Hourly - Total Usage'
@@&&oci360_list_subsec_stop.

-----------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE OCI360_REPORTS_USAGE_TEMP PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- This table will contain only entries that have a not constant graph
CREATE TABLE OCI360_REPORTS_USAGE_TEMP
AS
WITH t1 AS (
  SELECT /*+ materialize */ "product/resource",
         "product/resourceId",
         SUM("usage/consumedQuantity") CONSUMED_AMOUNT,
         SUM("usage/billedQuantity")   BILLED_AMOUNT,
         TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   OCI360_REPORTS_USAGE
  WHERE  substr("product/resourceId",1,instr("product/resourceId",'.',1,2)-1) = 'ocid1.instance'
  GROUP BY TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.'),
         "product/resource",
         "product/resourceId"
),
trange as ( 
  select /*+ materialize */ trunc(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') max
  FROM   OCI360_REPORTS_USAGE
),
allhours as ( -- Will generate all hours between Min and Max Start Time
  SELECT /*+ materialize */ trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
),
allentries as (
select "product/resource",
       "product/resourceId",
       TO_CHAR(NVL(SUM(CONSUMED_AMOUNT),0)) line1,
       TO_CHAR(NVL(SUM(BILLED_AMOUNT),0))   line2
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
group by seq, vdate, "product/resource", "product/resourceId"
)
select "product/resource", "product/resourceId"
from   allentries
group by "product/resource", "product/resourceId"
having count(distinct line1 || ' ' || line2) > 1;

-----------------------------------------

DEF title = 'Computes - Hourly - Constant Usage'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT DISTINCT
       "product/service"
      ,"product/resource"
      ,"product/compartmentId"
      ,"product/compartmentName"
      ,"product/region"
      ,"product/availabilityDomain"
      ,"product/resourceId"
      ,TO_CHAR(TO_NUMBER("usage/consumedQuantity"))
      ,TO_CHAR(TO_NUMBER("usage/billedQuantity"))
      ,TO_CHAR(TO_NUMBER("usage/consumedQuantity") - TO_NUMBER("usage/billedQuantity")) "Difference"
      ,"usage/consumedQuantityUnits"
      ,"usage/consumedQuantityMeasure"
FROM     OCI360_REPORTS_USAGE
WHERE    substr("product/resourceId",1,instr("product/resourceId",'.',1,2)-1) = 'ocid1.instance'
         AND ("product/resource", "product/resourceId") NOT IN
         ( SELECT "product/resource", "product/resourceId" FROM OCI360_REPORTS_USAGE_TEMP )
ORDER BY "product/service"
        ,"product/resource"
        ,"product/resourceId"
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Compute: ' || NAME || ' Res: ' || RES || '''' || CHR(10) ||
       'DEF title_suffix = '' between &&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_USAGE''' || CHR(10) ||
       'DEF vaxis = ''' || TRIM(UNITS) || '''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@filter_predicate@'', q''["product/resource" = ''' || RES || ''' AND "product/resourceId" = ''' || NAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Consumed per Hour''' || CHR(10) ||
       'DEF tit_02 = ''Total Billed per Hour''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( 
SELECT   DISTINCT "product/resource"   RES,
                  "product/resourceId" NAME,
                  "usage/consumedQuantityUnits" || ' ' || "usage/consumedQuantityMeasure" UNITS
FROM     OCI360_REPORTS_USAGE
WHERE    substr("product/resourceId",1,instr("product/resourceId",'.',1,2)-1) = 'ocid1.instance'
         AND ("product/resource", "product/resourceId") IN
         ( SELECT "product/resource", "product/resourceId" FROM OCI360_REPORTS_USAGE_TEMP )
ORDER BY NAME, RES
);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Computes - Hourly - Total Usage'
@@&&oci360_list_subsec_stop.

-----------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE OCI360_REPORTS_USAGE_TEMP PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- This table will contain only entries that have a not constant graph
CREATE TABLE OCI360_REPORTS_USAGE_TEMP
AS
WITH t1 AS (
  SELECT /*+ materialize */ "product/resource",
         "product/resourceId",
         SUM("usage/consumedQuantity") CONSUMED_AMOUNT,
         SUM("usage/billedQuantity")   BILLED_AMOUNT,
         TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   OCI360_REPORTS_USAGE
  WHERE  substr("product/resourceId",1,instr("product/resourceId",'.',1,2)-1)
                 NOT IN ('ocid1.instance',
                         'ocid1.volumebackup',
                         'ocid1.bootvolumebackup',
                         'ocid1.volume',
                         'ocid1.bootvolume',
                         'ocid1.vnic')
          OR     nvl(substr("product/resourceId",1,instr("product/resourceId",'.',1,1)-1),'x') != 'ocid1'
  GROUP BY TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.'),
         "product/resource",
         "product/resourceId"
),
trange as ( 
  select /*+ materialize */ trunc(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') max
  FROM   OCI360_REPORTS_USAGE
),
allhours as ( -- Will generate all hours between Min and Max Start Time
  SELECT /*+ materialize */ trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
),
allentries as (
select "product/resource",
       "product/resourceId",
       TO_CHAR(NVL(SUM(CONSUMED_AMOUNT),0)) line1,
       TO_CHAR(NVL(SUM(BILLED_AMOUNT),0))   line2
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
group by seq, vdate, "product/resource", "product/resourceId"
)
select "product/resource", "product/resourceId"
from   allentries
group by "product/resource", "product/resourceId"
having count(distinct line1 || ' ' || line2) > 1;

-----------------------------------------

DEF title = 'Other Objects - Hourly - Constant Usage'
DEF main_table = 'OCI360_REPORTS_USAGE'

BEGIN
  :sql_text := q'{
SELECT DISTINCT
       t1."product/service"
      ,t1."product/resource"
      ,t1."product/compartmentId"
      ,t1."product/compartmentName"
      ,t1."product/region"
      ,t1."product/availabilityDomain"
      ,t1."product/resourceId"
      ,TO_CHAR(TO_NUMBER(t1."usage/consumedQuantity"))
      ,TO_CHAR(TO_NUMBER(t1."usage/billedQuantity"))
      ,TO_CHAR(TO_NUMBER(t1."usage/consumedQuantity") - TO_NUMBER(t1."usage/billedQuantity")) "Difference"
      ,t1."usage/consumedQuantityUnits"
      ,t1."usage/consumedQuantityMeasure"
FROM  OCI360_REPORTS_USAGE t1, OCI360_REPORTS_USAGE_TEMP t2
WHERE  (
       substr(t1."product/resourceId",1,instr(t1."product/resourceId",'.',1,2)-1)
       NOT IN ('ocid1.instance',
               'ocid1.volumebackup',
               'ocid1.bootvolumebackup',
               'ocid1.volume',
               'ocid1.bootvolume',
               'ocid1.vnic')
OR     nvl(substr(t1."product/resourceId",1,instr(t1."product/resourceId",'.',1,1)-1),'x') != 'ocid1'
      )
AND   t1."product/resourceId" = t2."product/resourceId" (+)
AND   t1."product/resource" = t2."product/resource" (+)
AND   t2."product/resource" is null AND t2."product/resourceId" is null
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'

@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT 'DEF title = ''Object: ' || NAME || DECODE(RES,NULL,NULL,' Res: ' || RES) || '''' || CHR(10) ||
       'DEF title_suffix = '' between &&oci360_usage_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_REPORTS_USAGE''' || CHR(10) ||
       'DEF vaxis = ''' || TRIM(UNITS) || '''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text_backup, ''@filter_predicate@'', q''[' || DECODE(RES,NULL,NULL,'"product/resource" = ''' || RES || ''' AND ') || '"product/resourceId" = ''' || NAME || ''']'');' || CHR(10) ||
       'DEF tit_01 = ''Total Consumed per Hour''' || CHR(10) ||
       'DEF tit_02 = ''Total Billed per Hour''' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( 
SELECT DISTINCT t1."product/resource"   RES,
       t1."product/resourceId" NAME,
       t1."usage/consumedQuantityUnits" || ' ' || t1."usage/consumedQuantityMeasure" UNITS
FROM  OCI360_REPORTS_USAGE t1, OCI360_REPORTS_USAGE_TEMP t2
WHERE  (
       substr(t1."product/resourceId",1,instr(t1."product/resourceId",'.',1,2)-1)
       NOT IN ('ocid1.instance',
               'ocid1.volumebackup',
               'ocid1.bootvolumebackup',
               'ocid1.volume',
               'ocid1.bootvolume',
               'ocid1.vnic')
OR     nvl(substr(t1."product/resourceId",1,instr(t1."product/resourceId",'.',1,1)-1),'x') != 'ocid1'
      )
AND   t1."product/resourceId" = t2."product/resourceId"
AND   nvl(t1."product/resource",'x') = nvl(t2."product/resource",'x')
ORDER BY t1."product/resource"
        ,t1."product/resourceId"
);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Other Objects - Hourly - Total Usage'
@@&&oci360_list_subsec_stop.

-----------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE OCI360_REPORTS_USAGE_TEMP PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

UNDEF oci360_usage_tzcolformat
UNDEF oci360_usage_date_from
UNDEF oci360_usage_date_to
UNDEF oci360_usage_period
UNDEF oci360_usage_between

-----------------------------------------