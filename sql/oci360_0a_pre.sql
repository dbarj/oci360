-- https://docs.oracle.com/en/database/oracle/oracle-database/12.2/adjsn/loading-external-json-data.html#GUID-52EFC452-5E65-4148-8070-1FA588A6E697

-- Costs Table - Updated in Aug/2018

-- Define custom oci360 functions
DEF oci360_collector  = '&&moat369_sw_base./sh/oci_json_export.sh'
DEF oci360_tables     = '&&moat369_sw_base./sh/oci_table_json.csv'
DEF oci360_columns    = '&&moat369_sw_base./sh/oci_cols_json.csv'
DEF fc_json_loader    = '&&moat369_sw_folder./oci360_fc_json_loader.sql'
DEF fc_json_metadata  = '&&moat369_sw_folder./oci360_fc_json_metadata.sql'

DEF oci360_tzcolformat = 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM'
DEF moat369_sw_desc_linesize = 150

@@&&fc_def_output_file. oci360_log 'internal.log'
@@&&fc_seq_output_file. oci360_log

-- Generate JSON Outputs
SET TERM ON
PRO Getting JSON Files
PRO Please wait ...
@@&&fc_set_term_off.

-- Check oci360_exec_mode variable
@@&&fc_def_empty_var. oci360_exec_mode
@@&&fc_set_value_var_nvl. 'oci360_exec_mode' '&&oci360_exec_mode.' 'REPORT_ONLY'
@@&&fc_validate_variable. oci360_exec_mode NOT_NULL

-- Check oci360_load_mode variable
-- Default value: PRE_LOAD if moat369_sections is unset, otherwise ON_DEMAND
@@&&fc_def_empty_var. oci360_load_mode
@@&&fc_set_value_var_nvl. 'oci360_load_mode' '&&oci360_load_mode_param.' '&&oci360_load_mode.'
COL oci360_load_mode NEW_V oci360_load_mode
SELECT DECODE('&&oci360_load_mode.',NULL,DECODE('&&moat369_sections.',NULL,'PRE_LOAD','ON_DEMAND'),'&&oci360_load_mode.') oci360_load_mode FROM DUAL;
COL oci360_load_mode clear
@@&&fc_validate_variable. oci360_load_mode NOT_NULL

-- Check oci360_clean_on_exit variable
-- Default value: OFF if oci360_load_mode is OFF, otherwise ON
@@&&fc_def_empty_var. oci360_clean_on_exit
-- COL oci360_clean_on_exit NEW_V oci360_clean_on_exit
-- SELECT DECODE('&&oci360_clean_on_exit.',NULL,DECODE('&&oci360_load_mode.','OFF','OFF','ON'),'&&oci360_clean_on_exit.') oci360_clean_on_exit FROM DUAL;
-- COL oci360_clean_on_exit clear
@@&&fc_set_value_var_nvl. 'oci360_clean_on_exit' '&&oci360_clean_on_exit.' 'OFF'
@@&&fc_validate_variable. oci360_clean_on_exit NOT_NULL
@@&&fc_validate_variable. oci360_clean_on_exit ON_OFF

-- Define ADB variables
@@&&fc_def_empty_var. oci360_adb_cred
@@&&fc_def_empty_var. oci360_adb_uri


-- Check oci360_skip_billing variable
@@&&fc_def_empty_var. oci360_skip_billing
@@&&fc_set_value_var_nvl. 'oci360_skip_billing' '&&oci360_skip_billing.' 'N'
@@&&fc_validate_variable. oci360_skip_billing NOT_NULL
@@&&fc_validate_variable. oci360_skip_billing Y_N

-- Check oci360_tables_override variable. This variable will replace oci360_tables default value.
@@&&fc_def_empty_var. oci360_tables_override
@@&&fc_set_value_var_nvl. 'oci360_tables' '&&oci360_tables_override.' '&&oci360_tables.'

SET TERM ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Check oci360_exec_mode variable
DECLARE
  V_VAR         VARCHAR2(30)  := 'oci360_exec_mode';
  V_VAR_CONTENT VARCHAR2(500) := '&&oci360_exec_mode.';
BEGIN
  IF V_VAR_CONTENT NOT IN ('FULL','REPORT_ONLY','LOAD_ONLY') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '" in 00_config.sql. Valid values are "FULL", "REPORT_ONLY" or "LOAD_ONLY".');
  END IF;
END;
/

-- Check oci360_load_mode variable
DECLARE
  V_VAR         VARCHAR2(30)  := 'oci360_load_mode';
  V_VAR_CONTENT VARCHAR2(500) := '&&oci360_load_mode.';
BEGIN
  IF V_VAR_CONTENT NOT IN ('PRE_LOAD','ON_DEMAND', 'OFF') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '" in 00_config.sql. Valid values are "PRE_LOAD", "ON_DEMAND" or "OFF".');
  END IF;
END;
/

-- Check oci360_exec_mode variable
DECLARE
  V_VAR         VARCHAR2(30)  := 'oci360_exec_mode';
  V_VAR_CONTENT VARCHAR2(500) := '&&oci360_exec_mode.';
BEGIN
  IF '&&oci360_exec_mode.' = 'LOAD_ONLY' and '&&oci360_load_mode.' in ('OFF','ON_DEMAND') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid combination. When oci360_exec_mode is "LOAD_ONLY", oci360_load_mode must be set as "PRE_LOAD". Found: "&&oci360_load_mode."');
  END IF;
END;
/

-- Check oci360_exec_mode variable
BEGIN
  IF ('&&oci360_adb_cred.' IS NULL and '&&oci360_adb_uri.' IS NOT NULL) OR
     ('&&oci360_adb_cred.' IS NOT NULL and '&&oci360_adb_uri.' IS NULL) THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid combination. When using Autonomous DB mode, both oci360_adb_cred and oci360_adb_uri must be defined."');
  END IF;
END;
/

-- Check Database version
BEGIN
  IF '&&is_ver_ge_12_2.' = 'N' AND '&&oci360_load_mode.' != 'OFF' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Database must be at least 12.2 as the tool uses DBMS_JSON.' || CHR(10) ||
    'Check https://docs.oracle.com/en/database/oracle/oracle-database/12.2/newft/new-features.html#GUID-71B4582E-A6E2-425D-8D0C-A60D70F7050C');
  END IF;
END;
/

-- Check "compatible" parameter
DECLARE
  V_RESULT      VARCHAR2(30);
  V_1_DIG       NUMBER;
  V_2_DIG       NUMBER;
BEGIN
  select value into v_result from v$parameter where name='compatible';
  V_1_DIG := SUBSTR(v_result,1,instr(v_result,'.'));
  V_2_DIG := SUBSTR(v_result,instr(v_result,'.')+1,instr(v_result,'.',1,2)-instr(v_result,'.')-1);
  IF NOT (V_1_DIG>12 OR (V_1_DIG=12 AND V_2_DIG>=2))  AND '&&oci360_load_mode.' != 'OFF' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Database compatible parameter must be at least 12.2 to run this tool (Long Identifiers).' || CHR(10) ||
   'Check https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqlrf/Database-Object-Names-and-Qualifiers.html#GUID-75337742-67FD-4EC0-985F-741C93D918DA');
  END IF;
END;
/

-- Check "max_string_size" parameter
DECLARE
  V_RESULT      VARCHAR2(30);
BEGIN
  select value into v_result from v$parameter where name='max_string_size';
  IF UPPER(V_RESULT) != 'EXTENDED' AND '&&oci360_load_mode.' != 'OFF' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Database must have extended max_string_size parameter to work with this tool.' || CHR(10) ||
   'Check https://docs.oracle.com/database/121/REFRN/GUID-D424D23B-0933-425F-BC69-9C0E6724693C.htm#REFRN10321');
  END IF;
END;
/

-- Check UTL_FILE permission
DECLARE
  V_RESULT      NUMBER;
BEGIN
  select count(*) into V_RESULT from all_procedures where owner='SYS' and object_name='UTL_FILE';
  IF V_RESULT = 0 THEN
    RAISE_APPLICATION_ERROR(-20000, 'SYS.UTL_FILE package is not visible by current user. Check if you have execute permissions.');
  END IF;
END;
/

-- Check UTL_COMPRESS permission
DECLARE
  V_RESULT      NUMBER;
BEGIN
  select count(*) into V_RESULT from all_procedures where owner='SYS' and object_name='UTL_COMPRESS';
  IF V_RESULT = 0 THEN
    RAISE_APPLICATION_ERROR(-20000, 'SYS.UTL_COMPRESS package is not visible by current user. Check if you have execute permissions.');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

----------------------------------------
-- Define Local or ADB skip variables
----------------------------------------

COL oci360_loc_skip NEW_V oci360_loc_skip
COL oci360_loc_code NEW_V oci360_loc_code
COL oci360_adb_skip NEW_V oci360_adb_skip
COL oci360_adb_code NEW_V oci360_adb_code
SELECT DECODE('&&oci360_adb_cred.','','','&&fc_skip_script.') oci360_loc_skip,
       DECODE('&&oci360_adb_cred.','','&&fc_skip_script.','') oci360_adb_skip,
       DECODE('&&oci360_adb_cred.','','','--') oci360_loc_code,
       DECODE('&&oci360_adb_cred.','','--','') oci360_adb_code
FROM DUAL;
COL oci360_loc_skip clear
COL oci360_loc_code clear
COL oci360_adb_skip clear
COL oci360_adb_code clear

@@&&oci360_adb_skip.&&moat369_sw_folder./oci360_fc_validate_adb.sql

-- Print execution mode

@@&&fc_def_output_file. oci360_step_file 'oci360_step_file.sql'
@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO SET TERM ON
PRO &&oci360_adb_code.PRO OCI360 running for Autonomous Database mode
PRO &&oci360_loc_code.PRO OCI360 running for Local Database mode
PRO @@&&fc_set_term_off.
SPO OFF
@@&&fc_spool_end.
@@&&oci360_step_file.
HOS rm -f "&&oci360_step_file."
UNDEF oci360_step_file

----------------------------------------
-- Load JSON list in oci360_json_files
----------------------------------------

@@&&fc_def_empty_var. oci360_json_zip
@@&&oci360_loc_skip.&&moat369_sw_folder./oci360_fc_json_extractor.sql

@@&&fc_def_output_file. oci360_json_files 'oci_json_export_list.txt'
@@&&fc_clean_file_name. oci360_json_files oci360_json_files_nopath "PATH"

-- If Local
@@&&fc_def_output_file. oci360_step_file 'oci360_step_zip_file.sql'
@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO HOS unzip -Z -1 &&oci360_json_zip. | &&cmd_grep. -E '.json$' > &&oci360_json_files.
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loc_skip.&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

-- If ADB
@@&&fc_def_output_file. oci360_step_file 'oci360_step_zip_file.sql'
@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO @@&&fc_spool_start.
PRO SPO &&oci360_json_files.
PRO SELECT object_name from 
PRO table(DBMS_CLOUD.LIST_OBJECTS (
PRO        credential_name      => '&&oci360_adb_cred.',
PRO        location_uri         => '&&oci360_adb_uri.'))
PRO WHERE REGEXP_LIKE(object_name,'.json$') OR REGEXP_LIKE(object_name,'.json.gz$')
PRO ;;
PRO SPO OFF
PRO @@&&fc_spool_end.
SPO OFF
@@&&fc_spool_end.
@@&&oci360_adb_skip.&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

----------------------------------------
-- Load CSV list in oci360_csv_files
----------------------------------------

@@&&fc_def_empty_var. oci360_csv_files
@@&&moat369_sw_folder./oci360_fc_csv_usage_extractor.sql

@@&&fc_def_output_file. oci360_csv_files 'oci_csv_export_list.txt'
@@&&fc_clean_file_name. oci360_csv_files oci360_csv_files_nopath "PATH"

-- If Local
@@&&fc_def_output_file. oci360_step_file 'oci360_step_csv_file.sql'
@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO HOS unzip -Z -1 &&oci360_csv_report_zip. | &&cmd_grep. -E '.csv.gz$' > &&oci360_csv_files.
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loc_skip.&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

-- If ADB
@@&&fc_def_output_file. oci360_step_file 'oci360_step_csv_file.sql'
@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO @@&&fc_spool_start.
PRO SPO &&oci360_csv_files.
PRO SELECT object_name from 
PRO table(DBMS_CLOUD.LIST_OBJECTS (
PRO        credential_name      => '&&oci360_adb_cred.',
PRO        location_uri         => '&&oci360_adb_uri.'))
PRO WHERE REGEXP_LIKE(object_name,'.csv$') OR REGEXP_LIKE(object_name,'.csv.gz$')
PRO ;;
PRO SPO OFF
PRO @@&&fc_spool_end.
SPO OFF
@@&&fc_spool_end.
@@&&oci360_adb_skip.&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

----------------------------------------
-- Compression Flag
----------------------------------------

@@&&fc_set_value_var_nvl2. 'oci360_tab_compression' '&&oci360_adb_skip.' 'COMPRESS' 'COMPRESS FOR QUERY HIGH'

----------------------------------------

-- The load of those tables inside the database is no longer using External Directories.

-- @@&&fc_def_output_file. oci360_jsoncol_file 'oci360_jsoncol_file.csv'
-- @@&&fc_clean_file_name. oci360_jsoncol_file oci360_jsoncol_file_nopath "PATH"
-- HOS cp -a &&oci360_columns. &&oci360_jsoncol_file.

-- @@&&fc_def_output_file. oci360_jsontab_file 'oci360_jsontab_file.csv'
-- @@&&fc_clean_file_name. oci360_jsontab_file oci360_jsontab_file_nopath "PATH"
-- HOS cp -a &&oci360_tables. &&oci360_jsontab_file.

----------------------------------------
-- Load ALL OCI360 tool tables
----------------------------------------

@@&&moat369_sw_folder./oci360_fc_exttables_create.sql

----------------------------------------

--
COL skip_billing_sql NEW_V skip_billing_sql
SELECT DECODE('&&oci360_skip_billing.','N','','&&fc_skip_script.') skip_billing_sql FROM DUAL;
COL skip_billing_sql clear
--
COL skip_section_json NEW_V skip_section_json
SELECT DECODE('&&oci360_load_mode.','OFF','&&fc_skip_script.','') skip_section_json FROM DUAL;
COL skip_section_json clear

--
COL skip_section_repusage NEW_V skip_section_repusage
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_section_repusage
FROM   ALL_TABLES
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_REPORTS_USAGE';
COL skip_section_repusage clear
--
COL skip_section_repcost NEW_V skip_section_repcost
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_section_repcost
FROM   ALL_TABLES
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_REPORTS_COST';
COL skip_section_repcost clear
--
COL skip_section_monit NEW_V skip_section_monit
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_section_monit
FROM   ALL_TABLES
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_MONIT_METRIC_LIST';
COL skip_section_monit clear
--
COL skip_section_audit NEW_V skip_section_audit
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_section_audit
FROM   ALL_TABLES
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_AUDIT_EVENTS';
COL skip_section_audit clear
--
COL skip_section_billing NEW_V skip_section_billing
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_section_billing
FROM   ALL_TABLES
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_SERV_ENTITLEMENTS';
COL skip_section_billing clear
--
COL skip_section_bigdata NEW_V skip_section_bigdata
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_section_bigdata
FROM   ALL_TAB_COLUMNS
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_BDS_INSTANCES'
AND    column_name = 'ID';
COL skip_section_bigdata clear
--

----------------------------------------
-- Skip all sections if exec_mode is LOAD_ONLY.
----------------------------------------

BEGIN
  IF '&&oci360_exec_mode.' = 'LOAD_ONLY' THEN
    :moat369_sec_from := '9z';
    :moat369_sec_to := '9z';
  END IF;
END;
/

@@&&fc_def_empty_var. oci360_skip_reexec_secvar
@@&&fc_set_value_var_decode. 'oci360_skip_reexec_secvar' '&&oci360_exec_mode.' 'LOAD_ONLY' '' '&&fc_skip_script.'
@@&&oci360_skip_reexec_secvar.&&fc_section_variables.

----------------------------