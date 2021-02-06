-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_MONIT_METRIC_DATA_1HMAX'
@@&&fc_table_loader. 'OCI360_VNICS'
@@&&fc_table_loader. 'OCI360_INSTANCES'
-----------------------------------------

DEF oci360_list_subsec_start = '&&moat369_sw_folder./oci360_fc_list_subsection_start.sql'
DEF oci360_list_subsec_stop  = '&&moat369_sw_folder./oci360_fc_list_subsection_stop.sql'

--- Get some monit info before starting
@@&&fc_def_empty_var. oci360_monit_date_from
@@&&fc_def_empty_var. oci360_monit_date_to
@@&&fc_def_empty_var. oci360_monit_period

COL oci360_monit_date_from NEW_V oci360_monit_date_from NOPRI
COL oci360_monit_date_to   NEW_V oci360_monit_date_to   NOPRI
COL oci360_monit_period    NEW_V oci360_monit_period    NOPRI
SELECT TO_CHAR(min(TO_TIMESTAMP_TZ(AGGREGATED_DATAPOINTS$TIMESTAMP,'&&oci360_tzcolformat.')),'YYYY-MM-DD') oci360_monit_date_from,
       TO_CHAR(max(TO_TIMESTAMP_TZ(AGGREGATED_DATAPOINTS$TIMESTAMP,'&&oci360_tzcolformat.')),'YYYY-MM-DD') oci360_monit_date_to,
       EXTRACT(DAY FROM (max(TO_TIMESTAMP_TZ(AGGREGATED_DATAPOINTS$TIMESTAMP,'&&oci360_tzcolformat.')) - min(TO_TIMESTAMP_TZ(AGGREGATED_DATAPOINTS$TIMESTAMP,'&&oci360_tzcolformat.')))) oci360_monit_period
from   OCI360_MONIT_METRIC_DATA_1HMAX;
COL oci360_monit_date_from CLEAR
COL oci360_monit_date_to   CLEAR
COL oci360_monit_period    CLEAR

DEF oci360_monit_between = '&&oci360_monit_date_from. and &&oci360_monit_date_to.'

-----------------------------------------
-- Prepare SQL for multiple scenarios.
-----------------------------------------

@@&&fc_def_output_file. oci360_reset_print 'oci360_reset_print.sql'
@@&&fc_spool_start.
SPO &&oci360_reset_print.
PRO DEF oci360_print_01 = '--'
PRO DEF oci360_print_02 = '--'
PRO DEF oci360_print_03 = '--'
PRO DEF oci360_print_04 = '--'
PRO DEF oci360_print_05 = '--'
PRO DEF oci360_print_06 = '--'
PRO DEF oci360_print_07 = '--'
PRO DEF oci360_print_08 = '--'
PRO DEF oci360_print_09 = '--'
PRO DEF oci360_print_10 = '--'
PRO DEF oci360_print_11 = '--'
PRO DEF oci360_print_12 = '--'
PRO DEF oci360_print_13 = '--'
PRO DEF oci360_print_14 = '--'
PRO DEF oci360_print_15 = '--'
PRO 
PRO DEF oci360_skip_01 = ''
PRO DEF oci360_skip_02 = ''
PRO DEF oci360_skip_03 = ''
PRO DEF oci360_skip_04 = ''
PRO DEF oci360_skip_05 = ''
PRO DEF oci360_skip_06 = ''
PRO DEF oci360_skip_07 = ''
PRO DEF oci360_skip_08 = ''
PRO DEF oci360_skip_09 = ''
PRO DEF oci360_skip_10 = ''
PRO DEF oci360_skip_11 = ''
PRO DEF oci360_skip_12 = ''
PRO DEF oci360_skip_13 = ''
PRO DEF oci360_skip_14 = ''
PRO DEF oci360_skip_15 = ''
SPO OFF
@@&&fc_spool_end.

@@&&fc_def_output_file. oci360_reset_cols 'oci360_reset_cols.sql'
@@&&fc_spool_start.
SPO &&oci360_reset_cols.
SET DEF ^
PRO BEGIN
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line01_print--','&&oci360_print_01.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line02_print--','&&oci360_print_02.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line03_print--','&&oci360_print_03.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line04_print--','&&oci360_print_04.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line05_print--','&&oci360_print_05.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line06_print--','&&oci360_print_06.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line07_print--','&&oci360_print_07.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line08_print--','&&oci360_print_08.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line09_print--','&&oci360_print_09.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line10_print--','&&oci360_print_10.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line11_print--','&&oci360_print_11.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line12_print--','&&oci360_print_12.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line13_print--','&&oci360_print_13.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line14_print--','&&oci360_print_14.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line15_print--','&&oci360_print_15.');;
PRO
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line01_skip--' ,'&&oci360_skip_01.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line02_skip--' ,'&&oci360_skip_02.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line03_skip--' ,'&&oci360_skip_03.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line04_skip--' ,'&&oci360_skip_04.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line05_skip--' ,'&&oci360_skip_05.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line06_skip--' ,'&&oci360_skip_06.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line07_skip--' ,'&&oci360_skip_07.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line08_skip--' ,'&&oci360_skip_08.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line09_skip--' ,'&&oci360_skip_09.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line10_skip--' ,'&&oci360_skip_10.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line11_skip--' ,'&&oci360_skip_11.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line12_skip--' ,'&&oci360_skip_12.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line13_skip--' ,'&&oci360_skip_13.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line14_skip--' ,'&&oci360_skip_14.');;
PRO   :sql_text_base := REPLACE(:sql_text_base, '--line15_skip--' ,'&&oci360_skip_15.');;
PRO END;;
PRO /
SPO OFF
SET DEF &
@@&&fc_spool_end.

VAR sql_text_backup CLOB
VAR sql_text_base CLOB

BEGIN
  :sql_text_backup := q'{
WITH t1 AS (
  SELECT NAME,
         AGGREGATED_DATAPOINTS$VALUE COMPUTEDAMOUNT,
         TO_TIMESTAMP_TZ(AGGREGATED_DATAPOINTS$TIMESTAMP,'&&oci360_tzcolformat.') ENDTIMEUTC
  FROM   OCI360_MONIT_METRIC_DATA_1HMAX
  WHERE  @filter_predicate@
),
trange as (
  select TO_DATE('&&oci360_monit_date_from.','YYYY-MM-DD') min,
         TO_DATE('&&oci360_monit_date_to.','YYYY-MM-DD') max
  FROM   DUAL
),
allhours as ( -- Will generate all hours between Min and Max Start Time
  SELECT trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
)
select seq                snap_id,
       TO_CHAR(vdate,     'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1/24,'YYYY-MM-DD HH24:MI') end_time,
--line01_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_01@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line1,
--line02_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_02@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line2,
--line03_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_03@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line3,
--line04_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_04@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line4,
--line05_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_05@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line5,
--line06_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_06@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line6,
--line07_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_07@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line7,
--line08_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_08@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line8,
--line09_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_09@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line9,
--line10_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_10@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line10,
--line11_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_11@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line11,
--line12_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_12@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line12,
--line13_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_13@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line13,
--line14_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_14@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line14,
--line15_print--       TO_CHAR(NVL(CEIL(SUM(DECODE(NAME,'@line_15@',COMPUTEDAMOUNT,0))*100)/100,0),'9999999999990D00') line15
--line01_skip--       0                   dummy_01,
--line02_skip--       0                   dummy_02,
--line03_skip--       0                   dummy_03,
--line04_skip--       0                   dummy_04,
--line05_skip--       0                   dummy_05,
--line06_skip--       0                   dummy_06,
--line07_skip--       0                   dummy_07,
--line08_skip--       0                   dummy_08,
--line09_skip--       0                   dummy_09,
--line10_skip--       0                   dummy_10,
--line11_skip--       0                   dummy_11,
--line12_skip--       0                   dummy_12,
--line13_skip--       0                   dummy_13,
--line14_skip--       0                   dummy_14,
--line15_skip--       0                   dummy_15
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
group by seq, vdate
order by seq
}';
END;
/

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&oci360_reset_print.
DEF oci360_print_01  = ''
DEF oci360_print_02  = ''
DEF oci360_print_03  = ''
DEF oci360_print_04  = ''
DEF oci360_print_05  = ''
DEF oci360_print_06  = ''
DEF oci360_skip_01  = '--'
DEF oci360_skip_02  = '--'
DEF oci360_skip_03  = '--'
DEF oci360_skip_04  = '--'
DEF oci360_skip_05  = '--'
DEF oci360_skip_06  = '--'
EXEC :sql_text_base := TRIM(:sql_text_backup);
@@&&oci360_reset_cols.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'
@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT '----------------------' || CHR(10) ||
       'DEF title = ''' || VNIC_DESC || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_monit_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_MONIT_METRIC_DATA_1HMAX''' || CHR(10) ||
       'DEF foot = ''Vnic: ' || VNIC_ID || '''' || CHR(10) ||
       'DEF vaxis = ''Bytes''' || CHR(10) ||
       '-- Dont remove this TRIM or sql_text_base may be removed.' || CHR(10) ||
       'EXEC :sql_text := TRIM(:sql_text_base);' || CHR(10) ||
       '--' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''["dimensions$resourceId" = ''' || VNIC_ID || ''' AND NAMESPACE = ''oci_vcn'']'');' || CHR(10) ||
       '-- Removing lines with comments.' || CHR(10) ||
       'EXEC :sql_text := REGEXP_REPLACE(:sql_text, ''--.*'' || CHR(10), '''');' || CHR(10) ||
       '--' || CHR(10) ||
       'DEF tit_01 = ''Bytes to Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_01@'', ''VnicToNetworkBytes'');' || CHR(10) ||
       'DEF tit_02 = ''Bytes from Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_02@'', ''VnicFromNetworkBytes'');' || CHR(10) ||
       'DEF tit_03 = ''Packets to Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_03@'', ''VnicToNetworkPackets'');' || CHR(10) ||
       'DEF tit_04 = ''Packets from Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_04@'', ''VnicFromNetworkPackets'');' || CHR(10) ||
       'DEF tit_05 = ''Egress Packets Dropped by Security List''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_05@'', ''VnicEgressDropsSecurityList'');' || CHR(10) ||
       'DEF tit_06 = ''Ingress Packets Dropped by Security List''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_06@'', ''VnicIngressDropsSecurityList'');' || CHR(10) ||
       '--' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT DISTINCT t1."dimensions$resourceId" VNIC_ID,
                DECODE(t2.id,NULL,t1."dimensions$resourceId",
                    DECODE(t2.display_name,NULL,NULL,'Name: ' || t2.display_name || ' ') ||
                    DECODE(t2.private_ip,NULL,NULL,'Private IP: ' || t2.private_ip || ' ') ||
                    DECODE(t2.hostname_label,NULL,NULL,'Host: ' || t2.hostname_label || ' ') ||
                    DECODE(t2.public_ip,NULL,NULL,'Public IP: ' || t2.public_ip)) VNIC_DESC
         FROM   OCI360_MONIT_METRIC_DATA_1HMAX t1, OCI360_VNICS t2
         WHERE  t1.NAMESPACE = 'oci_vcn'
           AND  t1."dimensions$resourceId" = t2.id (+)
         ORDER BY 2);
SPO OFF
@@&&fc_spool_end.
-- @@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Vnics Utilization'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&oci360_reset_print.
DEF oci360_print_01  = ''
DEF oci360_print_02  = ''
DEF oci360_print_03  = ''
DEF oci360_print_04  = ''
DEF oci360_print_05  = ''
DEF oci360_print_06  = ''
DEF oci360_skip_01  = '--'
DEF oci360_skip_02  = '--'
DEF oci360_skip_03  = '--'
DEF oci360_skip_04  = '--'
DEF oci360_skip_05  = '--'
DEF oci360_skip_06  = '--'
EXEC :sql_text_base := TRIM(:sql_text_backup);
@@&&oci360_reset_cols.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'
@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT '----------------------' || CHR(10) ||
       'DEF title = ''' || VNIC_DESC || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_monit_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_MONIT_METRIC_DATA_1HMAX''' || CHR(10) ||
       'DEF foot = ''Vnic: ' || VNIC_ID || '''' || CHR(10) ||
       'DEF vaxis = ''Bytes''' || CHR(10) ||
       '-- Dont remove this TRIM or sql_text_base may be removed.' || CHR(10) ||
       'EXEC :sql_text := TRIM(:sql_text_base);' || CHR(10) ||
       '--' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''["dimensions$resourceId" = ''' || VNIC_ID || ''' AND NAMESPACE = ''oci_vcn'']'');' || CHR(10) ||
       '-- Removing lines with comments.' || CHR(10) ||
       'EXEC :sql_text := REGEXP_REPLACE(:sql_text, ''--.*'' || CHR(10), '''');' || CHR(10) ||
       '--' || CHR(10) ||
       'DEF tit_01 = ''Bytes to Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_01@'', ''VnicToNetworkBytes'');' || CHR(10) ||
       'DEF tit_02 = ''Bytes from Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_02@'', ''VnicFromNetworkBytes'');' || CHR(10) ||
       'DEF tit_03 = ''Packets to Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_03@'', ''VnicToNetworkPackets'');' || CHR(10) ||
       'DEF tit_04 = ''Packets from Network''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_04@'', ''VnicFromNetworkPackets'');' || CHR(10) ||
       'DEF tit_05 = ''Egress Packets Dropped by Security List''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_05@'', ''VnicEgressDropsSecurityList'');' || CHR(10) ||
       'DEF tit_06 = ''Ingress Packets Dropped by Security List''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_06@'', ''VnicIngressDropsSecurityList'');' || CHR(10) ||
       '--' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT DISTINCT t1."dimensions$resourceId" VNIC_ID,
                DECODE(t2.id,NULL,t1."dimensions$resourceId",
                    DECODE(t2.display_name,NULL,NULL,'Name: ' || t2.display_name || ' ') ||
                    DECODE(t2.private_ip,NULL,NULL,'Private IP: ' || t2.private_ip || ' ') ||
                    DECODE(t2.hostname_label,NULL,NULL,'Host: ' || t2.hostname_label || ' ') ||
                    DECODE(t2.public_ip,NULL,NULL,'Public IP: ' || t2.public_ip)) VNIC_DESC
         FROM   OCI360_MONIT_METRIC_DATA_1HMAX t1, OCI360_VNICS t2
         WHERE  t1.NAMESPACE = 'oci_vcn'
           AND  t1."dimensions$resourceId" = t2.id (+)
         ORDER BY 2);
SPO OFF
@@&&fc_spool_end.
-- @@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Vnics Utilization'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&oci360_list_subsec_start.

@@&&oci360_reset_print.
DEF oci360_print_01  = ''
DEF oci360_print_02  = ''
DEF oci360_print_03  = ''
DEF oci360_print_04  = ''
DEF oci360_print_05  = ''
DEF oci360_print_06  = ''
DEF oci360_skip_01  = '--'
DEF oci360_skip_02  = '--'
DEF oci360_skip_03  = '--'
DEF oci360_skip_04  = '--'
DEF oci360_skip_05  = '--'
DEF oci360_skip_06  = '--'
EXEC :sql_text_base := TRIM(:sql_text_backup);
@@&&oci360_reset_cols.

@@&&fc_def_output_file. oci360_loop_section 'oci360_section.sql'
@@&&fc_spool_start.
SPO &&oci360_loop_section.
SELECT '----------------------' || CHR(10) ||
       'DEF title = ''' || ITEM_DESC || '''' || CHR(10) ||
       'DEF title_suffix = ''&&oci360_monit_between.''' || CHR(10) ||
       'DEF main_table = ''OCI360_MONIT_METRIC_DATA_1HMAX''' || CHR(10) ||
       'DEF foot = ''OCID: ' || ITEM_ID || '''' || CHR(10) ||
       'DEF vaxis = ''Count''' || CHR(10) ||
       '-- Dont remove this TRIM or sql_text_base may be removed.' || CHR(10) ||
       'EXEC :sql_text := TRIM(:sql_text_base);' || CHR(10) ||
       '--' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@filter_predicate@'', q''[lower(DIMENSIONS$RESOURCEID) = ''' || ITEM_ID || ''' AND NAMESPACE = ''' || NAMESPACE || ''']'');' || CHR(10) ||
       '-- Removing lines with comments.' || CHR(10) ||
       'EXEC :sql_text := REGEXP_REPLACE(:sql_text, ''--.*'' || CHR(10), '''');' || CHR(10) ||
       '--' || CHR(10) ||
       'DEF tit_01 = ''Current Logons''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_01@'', ''CurrentLogons'');' || CHR(10) ||
       'DEF tit_02 = ''Execute Count''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_02@'', ''ExecuteCount'');' || CHR(10) ||
       'DEF tit_03 = ''Parse Count''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_03@'', ''ParseCount'');' || CHR(10) ||
       'DEF tit_04 = ''Running Statements''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_04@'', ''RunningStatements'');' || CHR(10) ||
       'DEF tit_05 = ''Sessions''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_05@'', ''Sessions'');' || CHR(10) ||
       'DEF tit_06 = ''User Calls''' || CHR(10) ||
       'EXEC :sql_text := REPLACE(:sql_text, ''@line_06@'', ''UserCalls'');' || CHR(10) ||
       '--' || CHR(10) ||
       'DEF chartype = ''LineChart''' || CHR(10) ||
       'DEF skip_lch = ''''' || CHR(10) ||
       '@@&&9a_pre_one.'
FROM   ( SELECT DISTINCT
                lower(t1.DIMENSIONS$RESOURCEID) ITEM_ID,
                t1.NAMESPACE,
                DECODE(t2.id,NULL,t1.DIMENSIONS$RESOURCEID,
                    TRIM(
                      DECODE(t2.display_name,NULL,NULL,'Name: "' || t2.display_name || '" ') ||
                      DECODE(t2.display_name,NULL,NULL,'CPUs: ' || t2.CPU_CORE_COUNT)
                    )
                ) ITEM_DESC
         FROM   OCI360_MONIT_METRIC_DATA_1HMAX t1, OCI360_AUTONOMOUS_DB t2
         WHERE  t1.NAMESPACE = 'oci_autonomous_database'
           AND  lower(t1.DIMENSIONS$RESOURCEID) = lower(t2.id (+))
         ORDER BY 2);
SPO OFF
@@&&fc_spool_end.

@@&&oci360_loop_section.

@@&&fc_zip_driver_files. &&oci360_loop_section.

UNDEF oci360_loop_section

DEF title = 'Autonomous Utilization'
@@&&oci360_list_subsec_stop.

-----------------------------------------

@@&&fc_zip_driver_files. &&oci360_reset_print.
@@&&fc_zip_driver_files. &&oci360_reset_cols.

UNDEF oci360_reset_print oci360_reset_cols

UNDEF oci360_print_01 oci360_print_02 oci360_print_03 oci360_print_04 oci360_print_05
UNDEF oci360_print_06 oci360_print_07 oci360_print_08 oci360_print_09 oci360_print_10
UNDEF oci360_print_11 oci360_print_12 oci360_print_13 oci360_print_14 oci360_print_15
UNDEF oci360_skip_01 oci360_skip_02 oci360_skip_03 oci360_skip_04 oci360_skip_05
UNDEF oci360_skip_06 oci360_skip_07 oci360_skip_08 oci360_skip_09 oci360_skip_10
UNDEF oci360_skip_11 oci360_skip_12 oci360_skip_13 oci360_skip_14 oci360_skip_15

UNDEF oci360_monit_date_from oci360_monit_date_to oci360_monit_period

UNDEF oci360_monit_between