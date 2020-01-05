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
@@&&fc_def_empty_var. oci360_load_mode
@@&&fc_set_value_var_nvl. 'oci360_load_mode' '&&oci360_load_mode_param.' '&&oci360_load_mode.'
COL oci360_load_mode NEW_V oci360_load_mode
SELECT DECODE('&&oci360_load_mode.',NULL,DECODE('&&moat369_sections.',NULL,'PRE_LOAD','ON_DEMAND'),'&&oci360_load_mode.') oci360_load_mode FROM DUAL;
COL oci360_load_mode clear
@@&&fc_validate_variable. oci360_load_mode NOT_NULL

-- Check oci360_clean_on_exit variable
@@&&fc_def_empty_var. oci360_clean_on_exit
@@&&fc_set_value_var_nvl. 'oci360_clean_on_exit' '&&oci360_clean_on_exit.' 'ON'
@@&&fc_validate_variable. oci360_clean_on_exit NOT_NULL
@@&&fc_validate_variable. oci360_clean_on_exit ON_OFF

-- Check oci360_skip_billing variable
@@&&fc_def_empty_var. oci360_skip_billing
@@&&fc_set_value_var_nvl. 'oci360_skip_billing' '&&oci360_skip_billing.' 'N'
@@&&fc_validate_variable. oci360_skip_billing NOT_NULL
@@&&fc_validate_variable. oci360_skip_billing Y_N

SET TERM ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Check oci360_exec_mode variable
DECLARE
  V_VAR         VARCHAR2(30)  := 'oci360_exec_mode';
  V_VAR_CONTENT VARCHAR2(500) := '&&oci360_exec_mode.';
BEGIN
  IF V_VAR_CONTENT NOT IN ('FULL','REPORT_ONLY') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '" in 00_config.sql. Valid values are "FULL" or "REPORT_ONLY".');
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

WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.


@@&&moat369_sw_folder./oci360_fc_json_extractor.sql

@@&&fc_def_output_file. oci360_json_files 'oci_json_export_list.txt'
@@&&fc_clean_file_name. oci360_json_files oci360_json_files_nopath "PATH"

HOS unzip -Z -1 &&oci360_json_zip. | &&cmd_grep. -E '.json$' > &&oci360_json_files.

@@&&fc_def_output_file. oci360_jsoncol_file 'oci360_jsoncol_file.csv'
@@&&fc_clean_file_name. oci360_jsoncol_file oci360_jsoncol_file_nopath "PATH"
HOS cp -a &&oci360_columns. &&oci360_jsoncol_file.

@@&&fc_def_output_file. oci360_jsontab_file 'oci360_jsontab_file.csv'
@@&&fc_clean_file_name. oci360_jsontab_file oci360_jsontab_file_nopath "PATH"
HOS cp -a &&oci360_tables. &&oci360_jsontab_file.

---- Create external table objects to query CSV files better
@@&&moat369_sw_folder./oci360_fc_exttables_create.sql

---- Skip Billing section if there is no info loaded
-- TODO
---- Skip Audit section if there is no info loaded
-- TODO
---- Skip Monitoring section if there is no info loaded
-- TODO

--
COL skip_billing_sql NEW_V skip_billing_sql
SELECT DECODE('&&oci360_skip_billing.','N','','&&fc_skip_script.') skip_billing_sql FROM DUAL;
COL skip_billing_sql clear
--
COL skip_json_section NEW_V skip_json_section
SELECT DECODE('&&oci360_load_mode.','OFF','&&fc_skip_script.','') skip_json_section FROM DUAL;
COL skip_json_section clear

----------------------------