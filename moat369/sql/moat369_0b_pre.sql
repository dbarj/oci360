WHENEVER SQLERROR EXIT SQL.SQLCODE

SET TERM OFF
SET VER OFF
SET FEED OFF
SET ECHO OFF
SET TIM OFF
SET TIMI OFF
DEF moat369_fw_vYYNN = 'v2002'
DEF moat369_fw_vrsn  = '&&moat369_fw_vYYNN. (2020-02-27)'

-- Define all functions and files:
@@moat369_fc_define_files.sql

-- Exit if not connected to a database
@@&&fc_exit_not_connected.

SET APPINFO ON

COL moat369_fw_vYYYY NEW_V moat369_fw_vYYYY NOPRI
SELECT TO_CHAR(SYSDATE,'YYYY') moat369_fw_vYYYY FROM DUAL;
COL moat369_fw_vYYYY CLEAR

-- Check command line parameter - This must come as soon as possible to avoid subsqls from overriding parameters. Do not call any parametered function or fc_set_term_off before.
COL C1 NEW_V 1
COL C2 NEW_V 2
COL C3 NEW_V 3
COL C4 NEW_V 4
COL C5 NEW_V 5
SELECT '' "C1", '' "C2", '' "C3", '' "C4", '' "C5" from dual WHERE ROWNUM = 0;
COL C1 clear
COL C2 clear
COL C3 clear
COL C4 clear
COL C5 clear
DEF in_main_param1 = '&1'
DEF in_main_param2 = '&2'
DEF in_main_param3 = '&3'
DEF in_main_param4 = '&4'
DEF in_main_param5 = '&5'
UNDEF 1 2 3 4 5

-- Start Time - Do not move it to the beggining, b4 we must ensure we are connected.
VAR moat369_main_time0 NUMBER;
EXEC :moat369_main_time0 := DBMS_UTILITY.GET_TIME;

-- Define SW folder and load configurations:
@@&&fc_def_empty_var. moat369_pre_sw_base
@@&&fc_def_empty_var. moat369_sw_base
@@&&fc_set_value_var_nvl. 'moat369_sw_base' '&&moat369_pre_sw_base.' './'

@@&&fc_def_empty_var. moat369_pre_sw_folder
@@&&fc_def_empty_var. moat369_sw_folder
@@&&fc_set_value_var_nvl. 'moat369_sw_folder' '&&moat369_pre_sw_folder.' '&&moat369_sw_base./sql'
@@&&moat369_sw_folder./00_config.sql

-- Validate config file -> Must run after variables 1 and 2 are saved.
@@&&fc_check_config.

-- Define full output folder path.
DEF step_full_path_name = 'step_full_path_outfdr.sql'
@@&&fc_def_output_file. step_full_path_outfdr  '&&step_full_path_name.'
HOS cd &&moat369_sw_output_fdr.; echo "DEF moat369_sw_output_fdr_fpath='$(pwd)'" > &&step_full_path_name.
-- I don't use &&step_full_path_outfdr. as target because of the "cd".
@&&step_full_path_outfdr.
HOS rm -f &&step_full_path_outfdr.
UNDEF step_full_path_name step_full_path_outfdr

-- Parse parameters
@@&&fc_parse_parameters.
undef in_main_param1 in_main_param2 in_main_param3 in_main_param4 in_main_param5

-- Override moat369_sections with sections_param if provided
@@&&fc_set_value_var_nvl. 'sections_param' '&&sections_param.' '&&moat369_sections.'
DEF moat369_sections = '&&sections_param.'
undef sections_param

-- Start
@@&&fc_def_output_file. step_pre_file_driver 'step_pre_file_driver.sql'
SPO &&step_pre_file_driver.
PRO SET TERM ON
PRO PRO If your Database is licensed to use the Oracle Tuning pack please enter T.
PRO PRO If you have a license for Diagnostics pack but not for Tuning pack, enter D.
PRO PRO Be aware value N reduces the output content substantially. Avoid N if possible.
PRO PRO
PRO @@&&fc_set_term_off.
SPO OFF

COL skip_spo_license NEW_V skip_spo_license
COL skip_ask_license NEW_V skip_ask_license

SELECT CASE WHEN '&moat369_conf_ask_license.' = 'Y' THEN '' ELSE '&&fc_skip_script.' END "skip_spo_license",
       CASE WHEN '&moat369_conf_ask_license.' = 'Y' AND '&license_pack_param.' IS NULL THEN '' ELSE '&&fc_skip_script.' END "skip_ask_license"
FROM   DUAL;
COL skip_spo_license clear
COL skip_ask_license clear

@&&skip_spo_license.&&step_pre_file_driver.
UNDEF skip_spo_license
HOS rm -f &&step_pre_file_driver.

SPO &&step_pre_file_driver.
PRO SET TERM ON
PRO ACCEPT license_pack_param char format a1 default '?' PROMPT "Oracle Pack License? (Tuning, Diagnostics or None) [ T | D | N ] (required): "
PRO PRO
PRO @@&&fc_set_term_off.
SPO OFF

@&&skip_ask_license.&&step_pre_file_driver.
UNDEF skip_ask_license
HOS rm -f &&step_pre_file_driver.

UNDEF step_pre_file_driver

@@&&fc_set_term_off.
COL license_pack NEW_V license_pack FOR A1
SELECT NVL(UPPER(TRIM('&license_pack_param.')), 'N') "license_pack" FROM DUAL;
COL license_pack clear
UNDEF license_pack_param

@@&&fc_validate_variable. license_pack T_D_N

COL diagnostics_pack NEW_V diagnostics_pack FOR A1
SELECT CASE WHEN '&&license_pack.' IN ('T', 'D') THEN 'Y' ELSE 'N' END diagnostics_pack FROM DUAL;
COL diagnostics_pack clear
COL skip_diagnostics NEW_V skip_diagnostics
SELECT CASE WHEN '&&license_pack.' IN ('T', 'D') THEN NULL ELSE '&&fc_skip_script.' END skip_diagnostics FROM DUAL;
COL skip_diagnostics clear
-- -- -- -- -- --
COL tuning_pack NEW_V tuning_pack FOR A1
SELECT CASE WHEN '&&license_pack.' = 'T' THEN 'Y' ELSE 'N' END tuning_pack FROM DUAL;
COL tuning_pack clear
COL skip_tuning NEW_V skip_tuning
SELECT CASE WHEN '&&license_pack.' = 'T' THEN NULL ELSE '&&fc_skip_script.' END skip_tuning FROM DUAL;
COL skip_tuning clear

SET TERM ON;
SELECT 'Be aware value "N" reduces output content substantially. Avoid "N" if possible.' warning FROM dual WHERE '&&license_pack.' = 'N' AND '&moat369_conf_ask_license.' = 'Y';
BEGIN
  IF '&&license_pack.' = 'N' AND '&moat369_conf_ask_license.' = 'Y' THEN
    DBMS_LOCK.SLEEP(5); -- sleep few seconds
  END IF;
END;
/
@@&&fc_set_term_off.

-- Move it away from here
-- COL fc_get_dbvault_user NEW_V fc_get_dbvault_user
-- select case WHEN COUNT(*) = 1 then '' ELSE '&&fc_skip_script.' END || '&&fc_get_dbvault_user.' fc_get_dbvault_user from v$option where parameter='Oracle Database Vault' and value='TRUE';
-- COL fc_get_dbvault_user clear
-- @@&&fc_get_dbvault_user.

-- Final file will be only encrypted if defined by parameter
COL fc_encrypt_output NEW_V fc_encrypt_output
select case WHEN '&&moat369_conf_encrypt_output.' = 'ON' then '' ELSE '&&fc_skip_script.' END || '&&fc_encrypt_file.'        fc_encrypt_output from dual;
COL fc_encrypt_output clear
-- Mid non-html files and files converted to html are encrypted based on html encryption
COL fc_encrypt_file NEW_V fc_encrypt_file
select case WHEN '&&moat369_conf_encrypt_html.'   = 'ON' then '' ELSE '&&fc_skip_script.' END || '&&fc_encrypt_file.'        fc_encrypt_file   from dual;
COL fc_encrypt_file clear
--
COL fc_convert_txt_to_html NEW_V fc_convert_txt_to_html
select case WHEN '&&moat369_conf_encrypt_html.'   = 'ON' OR '&&moat369_conf_compress_html.'   = 'ON' then '' ELSE '&&fc_skip_script.' END || '&&fc_convert_txt_to_html.' fc_convert_txt_to_html from dual;
COL fc_convert_txt_to_html clear
--
@@&&fc_set_value_var_decode. 'fc_add_tablefilter' '&&moat369_conf_tablefilter.' 'Y' '&&fc_add_tablefilter.' '&&fc_skip_script.&&fc_add_tablefilter.'
@@&&fc_set_value_var_decode. 'fc_add_sorttable'   '&&moat369_conf_tablefilter.' 'N' '&&fc_add_sorttable.'   '&&fc_skip_script.&&fc_add_sorttable.'

@@&&fc_def_empty_var. moat369_pre_enc_pub_file
@@&&fc_set_value_var_nvl. 'moat369_enc_pub_file' '&&moat369_pre_enc_pub_file.' '&&moat369_sw_base./&&moat369_sw_misc_fdr./&&moat369_sw_cert_file.'

@@&&fc_def_empty_var. moat369_pre_sw_key_file
@@&&fc_def_output_file. enc_key_file 'key.bin'
@@&&fc_set_value_var_nvl. 'enc_key_file' '&&moat369_pre_sw_key_file.' '&&enc_key_file.'
 

HOS if [ ! -f &&enc_key_file. -a '&&moat369_conf_encrypt_html.' == 'ON' ]; then openssl rand -base64 32 -out &&enc_key_file.; fi
HOS if [ -f &&enc_key_file. ]; then openssl rsautl -encrypt -inkey &&moat369_enc_pub_file. -certin -in &&enc_key_file. -out &&enc_key_file..enc; fi

-- End Check Encryption

-- Define OS binaries
COL cmd_awk  NEW_V cmd_awk
COL cmd_grep NEW_V cmd_grep

SELECT bin_prefix1 || 'awk'  cmd_awk,
       bin_prefix2 || 'grep' cmd_grep
from (
SELECT
decode(platform_id,
1,'/usr/xpg4/bin/', -- Solaris[tm] OE (32-bit)
2,'/usr/xpg4/bin/', -- Solaris[tm] OE (64-bit)
'') bin_prefix1,
decode(platform_id,
1,'/usr/gnu/bin/', -- Solaris[tm] OE (32-bit)
2,'/usr/gnu/bin/', -- Solaris[tm] OE (64-bit)
'') bin_prefix2 from v$database);
COL cmd_awk  NEW_V clear
COL cmd_grep NEW_V clear

-- ENABLE ALL ROLES FOR USER
SET ROLE ALL;

--PRO
--PRO Use default value of 31 unless you have been instructed otherwise.
--PRO
COL history_days NEW_V history_days;
-- range: takes at least 31 days and at most as many as actual history, with a default of 31. parameter restricts within that range.
-- Original query commented. If the tool is AWR based, move and adapt it to pre sql specific of the tool
--SELECT TO_CHAR(LEAST(CEIL(SYSDATE - CAST(MIN(begin_interval_time) AS DATE)), GREATEST(31, TO_NUMBER(NVL(TRIM('&&moat369_conf_days.'), '31'))))) history_days FROM dba_hist_snapshot WHERE '&&diagnostics_pack.' = 'Y' AND dbid = (SELECT dbid FROM v$database);
SELECT TO_CHAR(GREATEST(31, TO_NUMBER(NVL(TRIM('&&moat369_conf_days.'), '31')))) history_days FROM DUAL;
SELECT TO_CHAR(TO_DATE('&&moat369_conf_date_to.', 'YYYY-MM-DD') - TO_DATE('&&moat369_conf_date_from.', 'YYYY-MM-DD') + 1) history_days FROM DUAL WHERE '&&moat369_conf_date_from.' != 'YYYY-MM-DD' AND '&&moat369_conf_date_to.' != 'YYYY-MM-DD';
--SELECT '0' history_days FROM DUAL WHERE NVL(TRIM('&&diagnostics_pack.'), 'N') = 'N';
COL history_days clear
@@&&fc_set_term_off.
COL hist_work_days NEW_V hist_work_days;
SELECT TRIM(TO_CHAR(ROUND(TO_NUMBER('&&history_days.')*5/7))) hist_work_days FROM DUAL;
COL hist_work_days clear
-- Dates format
DEF moat369_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

COL moat369_date_from NEW_V moat369_date_from;
COL moat369_date_to NEW_V moat369_date_to;
SELECT CASE '&&moat369_conf_date_from.' WHEN 'YYYY-MM-DD' THEN TO_CHAR(SYSDATE - &&history_days., 'YYYY-MM-DD') ELSE '&&moat369_conf_date_from.' END moat369_date_from FROM DUAL;
SELECT CASE '&&moat369_conf_date_to.' WHEN 'YYYY-MM-DD' THEN TO_CHAR(SYSDATE + 1, 'YYYY-MM-DD') ELSE '&&moat369_conf_date_to.' END moat369_date_to FROM DUAL;

-- hidden parameter _o_release: report column, or section, or range of columns or range of sections i.e. 3, 3-4, 3a, 3a-4c, 3-4c, 3c-4
VAR moat369_sec_from VARCHAR2(2);
VAR moat369_sec_to   VARCHAR2(2);
BEGIN
  IF LENGTH('&&moat369_sections.') > 5 THEN -- no hidden parameter passed
    :moat369_sec_from := '1a';
    :moat369_sec_to := '9z';
  ELSIF LENGTH('&&moat369_sections.') = 5 AND SUBSTR('&&moat369_sections.', 3, 1) = '-' AND LOWER(SUBSTR('&&moat369_sections.', 1, 2)) BETWEEN '1a' AND '9z' AND LOWER(SUBSTR('&&moat369_sections.', 4, 2)) BETWEEN '1a' AND '9z' THEN -- i.e. 1a-7b
    :moat369_sec_from := LOWER(SUBSTR('&&moat369_sections.', 1, 2));
    :moat369_sec_to := LOWER(SUBSTR('&&moat369_sections.', 4, 2));
  ELSIF LENGTH('&&moat369_sections.') = 4 AND SUBSTR('&&moat369_sections.', 3, 1) = '-' AND LOWER(SUBSTR('&&moat369_sections.', 1, 2)) BETWEEN '1a' AND '9z' AND LOWER(SUBSTR('&&moat369_sections.', 4, 1)) BETWEEN '1' AND '9' THEN -- i.e. 3b-7
    :moat369_sec_from := LOWER(SUBSTR('&&moat369_sections.', 1, 2));
    :moat369_sec_to := LOWER(SUBSTR('&&moat369_sections.', 4, 1))||'z';
  ELSIF LENGTH('&&moat369_sections.') = 4 AND SUBSTR('&&moat369_sections.', 2, 1) = '-' AND LOWER(SUBSTR('&&moat369_sections.', 1, 1)) BETWEEN '1' AND '9' AND LOWER(SUBSTR('&&moat369_sections.', 3, 2)) BETWEEN '1a' AND '9z' THEN -- i.e. 3-5b
    :moat369_sec_from := LOWER(SUBSTR('&&moat369_sections.', 1, 1))||'a';
    :moat369_sec_to := LOWER(SUBSTR('&&moat369_sections.', 3, 2));
  ELSIF LENGTH('&&moat369_sections.') = 3 AND SUBSTR('&&moat369_sections.', 2, 1) = '-' AND LOWER(SUBSTR('&&moat369_sections.', 1, 1)) BETWEEN '1' AND '9' AND LOWER(SUBSTR('&&moat369_sections.', 3, 1)) BETWEEN '1' AND '9' THEN -- i.e. 3-5
    :moat369_sec_from := LOWER(SUBSTR('&&moat369_sections.', 1, 1))||'a';
    :moat369_sec_to := LOWER(SUBSTR('&&moat369_sections.', 3, 1))||'z';
  ELSIF LENGTH('&&moat369_sections.') = 2 AND LOWER(SUBSTR('&&moat369_sections.', 1, 2)) BETWEEN '1a' AND '9z' THEN -- i.e. 7b
    :moat369_sec_from := LOWER(SUBSTR('&&moat369_sections.', 1, 2));
    :moat369_sec_to := :moat369_sec_from;
  ELSIF LENGTH('&&moat369_sections.') = 1 AND LOWER(SUBSTR('&&moat369_sections.', 1, 1)) BETWEEN '1' AND '9' THEN -- i.e. 7
    :moat369_sec_from := LOWER(SUBSTR('&&moat369_sections.', 1, 1))||'a';
    :moat369_sec_to := LOWER(SUBSTR('&&moat369_sections.', 1, 1))||'z';
  ELSE -- wrong use of hidden parameter
    :moat369_sec_from := '1a';
    :moat369_sec_to := '9z';
  END IF;
END;
/

PRINT moat369_sec_from;
PRINT moat369_sec_to;

COL skip_tkprof NEW_V skip_tkprof
SELECT CASE '&&moat369_conf_incl_tkprof.' WHEN 'Y' THEN '' ELSE '&&fc_skip_script.' END skip_tkprof FROM DUAL;
COL skip_tkprof clear

-- filename prefix
COL moat369_prefix NEW_V moat369_prefix;
SELECT '&&moat369_sw_name.' || CASE WHEN NOT (:moat369_sec_from = '1a' AND :moat369_sec_to = '9z') THEN '_' || :moat369_sec_from || '_' || :moat369_sec_to END moat369_prefix FROM DUAL;
COL moat369_prefix clear

-- get dbid
COL moat369_dbid NEW_V moat369_dbid;
SELECT TRIM(TO_CHAR(dbid)) moat369_dbid FROM v$database;
COL moat369_dbid clear
-- get instance number
COL connect_instance_number NEW_V connect_instance_number;
SELECT TO_CHAR(instance_number) connect_instance_number FROM v$instance;
COL connect_instance_number clear
-- get database name (up to 10, stop before first '.', no special characters)
COL database_name_short NEW_V database_name_short FOR A10;
SELECT LOWER(SUBSTR(SYS_CONTEXT('USERENV', 'DB_NAME'), 1, 10)) database_name_short FROM DUAL;
SELECT SUBSTR('&&database_name_short.', 1, INSTR('&&database_name_short..', '.') - 1) database_name_short FROM DUAL;
SELECT TRANSLATE('&&database_name_short.',
'abcdefghijklmnopqrstuvwxyz0123456789-_ ''`~!@#$%&*()=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyz0123456789-_') database_name_short FROM DUAL;
COL database_name_short clear
-- get host name (up to 30, stop before first '.', no special characters)
COL host_name_short NEW_V host_name_short FOR A30;
SELECT LOWER(SUBSTR(SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, 30)) host_name_short FROM DUAL;
SELECT SUBSTR('&&host_name_short.', 1, INSTR('&&host_name_short..', '.') - 1) host_name_short FROM DUAL;
SELECT TRANSLATE('&&host_name_short.',
'abcdefghijklmnopqrstuvwxyz0123456789-_ ''`~!@#$%&*()=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyz0123456789-_') host_name_short FROM DUAL;
COL host_name_short clear
-- setup
DEF sql_trace_level = '1';
DEF title = '';
DEF title_no_spaces = '';
DEF title_suffix = '';
-- timestamp on filename
COL moat369_file_time NEW_V moat369_file_time FOR A20;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MI') moat369_file_time FROM DUAL;
COL moat369_file_time clear

COL common_moat369_prefix_dbname NEW_V common_moat369_prefix_dbname NOPRI
SELECT q'[_&&database_name_short.]' common_moat369_prefix_dbname
FROM   DUAL
WHERE  '&&moat369_sw_dbtool.'='Y';
COL common_moat369_prefix_dbname CLEAR

DEF section_id = ''
DEF common_moat369_prefix = '&&moat369_prefix.&&common_moat369_prefix_dbname.';

UNDEF common_moat369_prefix_dbname

@@&&fc_def_output_file. moat369_readme      '00000_readme_first.txt'
@@&&fc_def_output_file. moat369_main_report 'index.html'
@@&&fc_def_output_file. moat369_log         'log.txt'
@@&&fc_def_output_file. moat369_log2        'time_log.txt'
@@&&fc_def_output_file. moat369_log3        'zip_log.txt'
@@&&fc_def_output_file. moat369_tkprof      'tkprof'
@@&&fc_def_output_file. moat369_alert       'alert'
@@&&fc_def_output_file. moat369_opatch      'opatch.zip'
@@&&fc_def_output_file. moat369_driver      'drivers.zip'
@@&&fc_def_output_file. moat369_cpuinfo     'cpuinfo_model_name.txt'

COL moat369_main_filename NEW_V moat369_main_filename NOPRI
SELECT q'[&&common_moat369_prefix.]' || DECODE(q'[&&moat369_sw_dbtool.]','Y',q'[_&&host_name_short.]','') moat369_main_filename FROM DUAL;
COL moat369_main_filename CLEAR

@@&&fc_def_output_file. moat369_zip_filename '&&moat369_main_filename._&&moat369_file_time.'
DEF moat369_tracefile_identifier = '&&common_moat369_prefix.';
@@&&fc_def_output_file. moat369_query '&&common_moat369_prefix._query.sql'

@@&&fc_def_empty_var. moat369_pre_sw_output_file
@@&&fc_set_value_var_nvl. 'moat369_zip_filename' '&&moat369_pre_sw_output_file.' '&&moat369_zip_filename.'

@@&&fc_def_bind_ifnotdef. "exec_seq"
EXEC IF :exec_seq IS NULL THEN :exec_seq := 1; ELSE :exec_seq := :exec_seq + 1; END IF;

@@&&fc_def_bind_ifnotdef. "file_seq"
EXEC IF :file_seq IS NULL THEN :file_seq := 0; END IF;

@@&&fc_seq_output_file. moat369_main_report
@@&&fc_seq_output_file. moat369_log
@@&&fc_seq_output_file. moat369_log2
@@&&fc_seq_output_file. moat369_log3
@@&&fc_seq_output_file. moat369_tkprof
@@&&fc_seq_output_file. moat369_alert
@@&&fc_seq_output_file. moat369_opatch
@@&&fc_seq_output_file. moat369_driver

@@&&fc_clean_file_name. "moat369_main_report"  "moat369_main_report_nopath"  "PATH"
@@&&fc_clean_file_name. "moat369_zip_filename" "moat369_zip_filename_nopath" "PATH"

COL moat369_style_css NEW_V moat369_style_css NOPRI
SELECT 'style_' || :exec_seq || '.css' moat369_style_css FROM DUAL;

-- get rdbms version
COL db_version NEW_V db_version;
SELECT version db_version FROM v$instance;
--

@@&&fc_oracle_version.

-- Exadata
ALTER SESSION SET "_serial_direct_read" = ALWAYS;
ALTER SESSION SET "_small_table_threshold" = 1001;
-- nls
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD/HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD/HH24:MI:SS.FF';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT = 'YYYY-MM-DD/HH24:MI:SS.FF TZH:TZM';
-- adding to prevent slow access to ASH with non default NLS settings
ALTER SESSION SET NLS_SORT = 'BINARY';
ALTER SESSION SET NLS_COMP = 'BINARY';
-- to work around bug 12672969
ALTER SESSION SET "_optimizer_order_by_elimination_enabled"=false;
-- workaround Siebel
ALTER SESSION SET optimizer_index_cost_adj = 100;
ALTER SESSION SET optimizer_dynamic_sampling = 2;
ALTER SESSION SET "_always_semi_join" = CHOOSE;
ALTER SESSION SET "_and_pruning_enabled" = TRUE;
ALTER SESSION SET "_subquery_pruning_enabled" = TRUE;
-- workaround 19567916
DECLARE
  V_CMD VARCHAR2(100) := q'[ALTER SESSION SET "_optimizer_aggr_groupby_elim" = FALSE]';
BEGIN
  IF '&&is_ver_ge_12.' = 'Y' THEN
    EXECUTE IMMEDIATE V_CMD;
  END IF;
END;
/

-- tracing script in case it takes long to execute so we can diagnose it
@@&&fc_def_output_file. step_trace 'step_trace.sql'

@@&&fc_spool_start.
SPO &&step_trace.
PRO ALTER SESSION SET MAX_DUMP_FILE_SIZE = '1G';;
PRO ALTER SESSION SET TRACEFILE_IDENTIFIER = "&&moat369_tracefile_identifier.";;
PRO ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL &&sql_trace_level.';;
SPO OFF
@@&&fc_spool_end.

@@&&skip_tkprof.&&step_trace.
HOS rm -f &&step_trace.
UNDEF step_trace

-- CPU cmd
COL cmd_getcpu NEW_V cmd_getcpu
SELECT decode(platform_id,
13,'cat /proc/cpuinfo | grep -i name | sort | uniq', -- Linux x86 64-bit
6,'lsconf | grep Processor', -- AIX-Based Systems (64-bit)
2,'psrinfo -v', -- Solaris[tm] OE (64-bit)
4,'machinfo', -- HP-UX IA (64-bit)
'cat /proc/cpuinfo | grep -i name | sort | uniq' -- Others
) cmd_getcpu from v$database;
COL cmd_getcpu clear
HOS &&cmd_getcpu. > &&moat369_cpuinfo.

@@&&fc_set_term_off.

-- zip esp files but preserve original files on file system until moat369 completes (one database or multiple)
-- ( MOVED TO RES AND ESP FILES )

-- initialization
COL row_num NEW_V row_num HEA '#' PRI

-- get average number of CPUs
COL avg_cpu_count NEW_V avg_cpu_count FOR A6;
SELECT TO_CHAR(ROUND(AVG(TO_NUMBER(value)),1)) avg_cpu_count FROM gv$system_parameter2 WHERE name = 'cpu_count';
COL avg_cpu_count clear
-- get total number of CPUs
COL sum_cpu_count NEW_V sum_cpu_count FOR A3;
SELECT TO_CHAR(SUM(TO_NUMBER(value))) sum_cpu_count FROM gv$system_parameter2 WHERE name = 'cpu_count';
COL sum_cpu_count clear
-- get average number of Cores
COL avg_core_count NEW_V avg_core_count FOR A5;
SELECT TO_CHAR(ROUND(AVG(TO_NUMBER(value)),1)) avg_core_count FROM gv$osstat WHERE stat_name = 'NUM_CPU_CORES';
COL avg_core_count clear
-- get average number of Threads
COL avg_thread_count NEW_V avg_thread_count FOR A6;
SELECT TO_CHAR(ROUND(AVG(TO_NUMBER(value)),1)) avg_thread_count FROM gv$osstat WHERE stat_name = 'NUM_CPUS';
COL avg_thread_count clear
-- get number of Hosts
COL hosts_count NEW_V hosts_count FOR A2;
SELECT TO_CHAR(COUNT(DISTINCT inst_id)) hosts_count FROM gv$osstat WHERE stat_name = 'NUM_CPU_CORES';
COL hosts_count clear
-- get cores_threads_hosts
COL cores_threads_hosts NEW_V cores_threads_hosts;
SELECT CASE TO_NUMBER('&&hosts_count.') WHEN 1 THEN 'cores:&&avg_core_count. threads:&&avg_thread_count.' ELSE 'cores:&&avg_core_count.(avg) threads:&&avg_thread_count.(avg) hosts:&&hosts_count.' END cores_threads_hosts FROM DUAL;
COL cores_threads_hosts clear
-- get block_size
COL database_block_size NEW_V database_block_size;
SELECT TRIM(TO_NUMBER(value)) database_block_size FROM v$system_parameter2 WHERE name = 'db_block_size';
COL database_block_size clear
-- determine if rac or single instance (null means rac)
COL is_single_instance NEW_V is_single_instance FOR A1;
SELECT CASE COUNT(*) WHEN 1 THEN 'Y' END is_single_instance FROM gv$instance;
COL is_single_instance clear
-- snapshot ranges
SELECT '0' history_days FROM DUAL WHERE TRIM('&&history_days.') IS NULL;
COL tool_sysdate NEW_V tool_sysdate;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') tool_sysdate FROM DUAL;
COL between_times NEW_V between_times;
COL between_dates NEW_V between_dates;
SELECT ', between &&moat369_date_from. and &&moat369_date_to.' between_dates FROM DUAL;

-- inclusion config determine skip flags
COL moat369_skip_html    NEW_V moat369_skip_html;
COL moat369_skip_text    NEW_V moat369_skip_text;
COL moat369_skip_csv     NEW_V moat369_skip_csv;
COL moat369_skip_line    NEW_V moat369_skip_line;
COL moat369_skip_pie     NEW_V moat369_skip_pie;
COL moat369_skip_bar     NEW_V moat369_skip_bar;
COL moat369_skip_graph   NEW_V moat369_skip_graph;
COL moat369_skip_map     NEW_V moat369_skip_map;
COL moat369_skip_treemap NEW_V moat369_skip_treemap;
COL moat369_skip_file    NEW_V moat369_skip_file;
SELECT CASE '&&moat369_conf_incl_html.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_html    ,
       CASE '&&moat369_conf_incl_text.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_text    ,
       CASE '&&moat369_conf_incl_csv.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_csv     ,
       CASE '&&moat369_conf_incl_line.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_line    ,
       CASE '&&moat369_conf_incl_pie.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_pie     ,
       CASE '&&moat369_conf_incl_bar.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_bar     ,
       CASE '&&moat369_conf_incl_graph.'   WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_graph   ,
       CASE '&&moat369_conf_incl_map.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_map     ,
       CASE '&&moat369_conf_incl_treemap.' WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_treemap ,
       CASE '&&moat369_conf_incl_file.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_skip_file
FROM   DUAL;
COL moat369_skip_html    CLEAR
COL moat369_skip_text    CLEAR
COL moat369_skip_csv     CLEAR
COL moat369_skip_line    CLEAR
COL moat369_skip_pie     CLEAR
COL moat369_skip_bar     CLEAR
COL moat369_skip_graph   CLEAR
COL moat369_skip_map     CLEAR
COL moat369_skip_treemap CLEAR
COL moat369_skip_file    CLEAR

-- inclusion config determine skip flags
COL moat369_def_skip_html    NEW_V moat369_def_skip_html;
COL moat369_def_skip_text    NEW_V moat369_def_skip_text;
COL moat369_def_skip_csv     NEW_V moat369_def_skip_csv;
COL moat369_def_skip_line    NEW_V moat369_def_skip_line;
COL moat369_def_skip_pie     NEW_V moat369_def_skip_pie;
COL moat369_def_skip_bar     NEW_V moat369_def_skip_bar;
COL moat369_def_skip_graph   NEW_V moat369_def_skip_graph;
COL moat369_def_skip_map     NEW_V moat369_def_skip_map;
COL moat369_def_skip_treemap NEW_V moat369_def_skip_treemap;
COL moat369_def_skip_file    NEW_V moat369_def_skip_file;
SELECT CASE '&&moat369_conf_def_html.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_html    ,
       CASE '&&moat369_conf_def_text.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_text    ,
       CASE '&&moat369_conf_def_csv.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_csv     ,
       CASE '&&moat369_conf_def_line.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_line    ,
       CASE '&&moat369_conf_def_pie.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_pie     ,
       CASE '&&moat369_conf_def_bar.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_bar     ,
       CASE '&&moat369_conf_def_graph.'   WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_graph   ,
       CASE '&&moat369_conf_def_map.'     WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_map     ,
       CASE '&&moat369_conf_def_treemap.' WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_treemap ,
       CASE '&&moat369_conf_def_file.'    WHEN 'N' THEN '&&fc_skip_script.' END moat369_def_skip_file
FROM   DUAL;
COL moat369_def_skip_html    CLEAR
COL moat369_def_skip_text    CLEAR
COL moat369_def_skip_csv     CLEAR
COL moat369_def_skip_line    CLEAR
COL moat369_def_skip_pie     CLEAR
COL moat369_def_skip_bar     CLEAR
COL moat369_def_skip_graph   CLEAR
COL moat369_def_skip_map     CLEAR
COL moat369_def_skip_treemap CLEAR
COL moat369_def_skip_file    CLEAR

DEF top_level_hints = 'NO_MERGE'
DEF sq_fact_hints   = 'MATERIALIZE NO_MERGE'
DEF ds_hint         = 'DYNAMIC_SAMPLING(4)'
--
DEF skip_all = ''

COL sql_text FOR A100
DEF chartype  = ''
DEF stacked   = ''
DEF haxis     = '&&db_version. &&cores_threads_hosts.'
DEF vaxis     = ''
DEF vbaseline = ''

COL tit_01 NEW_V tit_01
COL tit_02 NEW_V tit_02
COL tit_03 NEW_V tit_03
COL tit_04 NEW_V tit_04
COL tit_05 NEW_V tit_05
COL tit_06 NEW_V tit_06
COL tit_07 NEW_V tit_07
COL tit_08 NEW_V tit_08
COL tit_09 NEW_V tit_09
COL tit_10 NEW_V tit_10
COL tit_11 NEW_V tit_11
COL tit_12 NEW_V tit_12
COL tit_13 NEW_V tit_13
COL tit_14 NEW_V tit_14
COL tit_15 NEW_V tit_15
DEF tit_01 = ''
DEF tit_02 = ''
DEF tit_03 = ''
DEF tit_04 = ''
DEF tit_05 = ''
DEF tit_06 = ''
DEF tit_07 = ''
DEF tit_08 = ''
DEF tit_09 = ''
DEF tit_10 = ''
DEF tit_11 = ''
DEF tit_12 = ''
DEF tit_13 = ''
DEF tit_14 = ''
DEF tit_15 = ''

DEF exadata = '';
DEF column_number = '1';
COL recovery NEW_V recovery;
SELECT CHR(38)||' recovery' recovery FROM DUAL;
-- this above is to handle event "RMAN backup & recovery I/O"
COL dummy_01 NOPRI;
COL dummy_02 NOPRI;
COL dummy_03 NOPRI;
COL dummy_04 NOPRI;
COL dummy_05 NOPRI;
COL dummy_06 NOPRI;
COL dummy_07 NOPRI;
COL dummy_08 NOPRI;
COL dummy_09 NOPRI;
COL dummy_10 NOPRI;
COL dummy_11 NOPRI;
COL dummy_12 NOPRI;
COL dummy_13 NOPRI;
COL dummy_14 NOPRI;
COL dummy_15 NOPRI;
COL moat369_time_stamp NEW_V moat369_time_stamp FOR A20;
DEF total_hours = ''
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') moat369_time_stamp FROM DUAL;
COL hh_mm_ss NEW_V hh_mm_ss FOR A8;
COL title_no_spaces NEW_V title_no_spaces;
COL spool_filename NEW_V spool_filename;
COL one_spool_filename NEW_V one_spool_filename;
COL report_sequence NEW_V report_sequence;
VAR sql_text CLOB;
VAR sql_text_cdb CLOB;
VAR sql_text_display CLOB;
VAR sql_with_clause CLOB;
VAR driver_seq NUMBER;
VAR repo_seq NUMBER;
VAR temp_seq NUMBER;
EXEC :driver_seq := 0;
EXEC :repo_seq := 1;
EXEC :temp_seq := 0;
SELECT TO_CHAR(:repo_seq) report_sequence FROM DUAL;
VAR get_time_t0 NUMBER;
VAR get_time_t1 NUMBER;
COL moat369_prev_sql_id NEW_V moat369_prev_sql_id NOPRI;
COL moat369_prev_child_number NEW_V moat369_prev_child_number NOPRI;
DEF current_time = '';

-- get udump directory path
COL moat369_udump_path NEW_V moat369_udump_path FOR A500;
-- CHR(92) = \
SELECT value||DECODE(INSTR(value, '/'), 0, CHR(92), '/') moat369_udump_path FROM v$parameter2 WHERE name = 'user_dump_dest';
SELECT value||DECODE(INSTR(value, '/'), 0, CHR(92), '/') moat369_udump_path FROM v$diag_info WHERE name = 'Diag Trace';
COL moat369_udump_path clear

-- get pid
COL moat369_spid NEW_V moat369_spid FOR A5;
SELECT TO_CHAR(spid) moat369_spid FROM v$session s, v$process p WHERE s.sid = SYS_CONTEXT('USERENV', 'SID') AND p.addr = s.paddr;
COL moat369_spid clear

-- Define Section Variables
@@&&fc_section_variables.

@@&&fc_set_term_off.

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Print Database and License info only if it is a DB tool.
COL db_lic_info NEW_V db_lic_info NOPRI
COL db_ver_info NEW_V db_ver_info NOPRI
SELECT 'Database:&&database_name_short. License:&&license_pack..' db_lic_info,
       ' for DB &&db_version' db_ver_info
FROM    DUAL
WHERE   '&&moat369_sw_dbtool.'='Y';
COL db_lic_info CLEAR
COL db_ver_info CLEAR

-- main header
SPO &&moat369_main_report.;
@@moat369_0d_html_header.sql
PRO </head>
PRO <body>
PRO <h1><em><a href="&&moat369_sw_url." target="_blank">&&moat369_sw_name.</a></em> &&moat369_sw_vYYNN.: &&moat369_sw_title_desc.&&db_ver_info..</h1>
PRO
PRO <pre>
PRO &&db_lic_info. This report covers the time interval between &&moat369_date_from. and &&moat369_date_to.. Days:&&history_days.. Timestamp:&&moat369_time_stamp..
PRO </pre>
PRO
SPO OFF;

UNDEF db_lic_info
UNDEF db_ver_info

-- zip into main the esp zip so far, then remove zip but preserve source esp files. let moat369.sql and run_moat369.sh do the clean up
@@&&fc_def_output_file. step_ren_cpuinfo 'step_ren_cpuinfo.sql'
HOS if [ -f esp_requirements_&&host_name_short..zip ]; then echo > &&step_ren_cpuinfo.; else echo '@@&&fc_zip_driver_files. &&moat369_cpuinfo.' > &&step_ren_cpuinfo.; fi
@@&&step_ren_cpuinfo.
HOS rm -f &&step_ren_cpuinfo.
UNDEF step_ren_cpuinfo

-- zip other files
HOS if [ '&&moat369_conf_sql_highlight.' == 'Y' ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./highlight.pack.js  >> &&moat369_log3.; fi
HOS if [ '&&moat369_conf_sql_highlight.' == 'Y' ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./vs.css             >> &&moat369_log3.; fi
HOS if [ '&&moat369_conf_sql_format.' == 'Y' ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./sql-formatter.js      >> &&moat369_log3.; fi
HOS if [ '&&moat369_conf_compress_html.' == 'ON' ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./gunzip.js         >> &&moat369_log3.; fi
HOS if [ -f &&moat369_sw_base./&&moat369_sw_misc_fdr./&&moat369_sw_logo_file. ]; then zip -j &&moat369_zip_filename. &&moat369_sw_base./&&moat369_sw_misc_fdr./&&moat369_sw_logo_file. >> &&moat369_log3.; fi
HOS if [ -f &&moat369_sw_base./&&moat369_sw_misc_fdr./&&moat369_sw_icon_file. ]; then zip -j &&moat369_zip_filename. &&moat369_sw_base./&&moat369_sw_misc_fdr./&&moat369_sw_icon_file. >> &&moat369_log3.; fi

HOS if [ '&&moat369_conf_compress_html.' == 'ON' -o -f &&enc_key_file..enc ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./decode.min.js  >> &&moat369_log3.; fi
HOS if [ -f &&enc_key_file..enc ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./aes.js >> &&moat369_log3.; fi
HOS if [ -f &&enc_key_file..enc ]; then zip -mj &&moat369_zip_filename. &&enc_key_file..enc     >> &&moat369_log3.; fi

HOS cp &&moat369_fdr_js./../LICENSE-3RD-PARTY &&moat369_sw_output_fdr./LICENSE-3RD-PARTY.txt >> &&moat369_log3.
HOS if [ -f &&moat369_sw_base./LICENSE-3RD-PARTY ]; then cat &&moat369_sw_base./LICENSE-3RD-PARTY >> &&moat369_sw_output_fdr./LICENSE-3RD-PARTY.txt; fi
HOS zip -mj &&moat369_zip_filename. &&moat369_sw_output_fdr./LICENSE-3RD-PARTY.txt >> &&moat369_log3.

HOS cp &&moat369_fdr_js./style.css  &&moat369_sw_output_fdr./&&moat369_style_css. >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_sw_output_fdr./&&moat369_style_css. >> &&moat369_log3.

HOS if [ '&&moat369_conf_tablefilter.' == 'N' ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./sorttable.js >> &&moat369_log3.; fi

--WHENEVER SQLERROR CONTINUE;
