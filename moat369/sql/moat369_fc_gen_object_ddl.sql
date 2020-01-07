-- Receive 4 parameters: Obj Type, Obj Name and Obj Owner and return in 4th parameter (that must be a variable) the generate .sql file 
COL c_gen_object_ddl_1 NEW_V 1 NOPRI
COL c_gen_object_ddl_2 NEW_V 2 NOPRI
COL c_gen_object_ddl_3 NEW_V 3 NOPRI
COL c_gen_object_ddl_4 NEW_V 4 NOPRI

-- To ignore empty parameters
SELECT '' c_gen_object_ddl_1, '' c_gen_object_ddl_2, '' c_gen_object_ddl_3, '' c_gen_object_ddl_4 FROM dual WHERE ROWNUM = 0;

COL c_gen_object_ddl_1 CLEAR
COL c_gen_object_ddl_2 CLEAR
COL c_gen_object_ddl_3 CLEAR
COL c_gen_object_ddl_4 CLEAR

DEF in_obj_type  = '&1.'
DEF in_obj_name  = '&2.'
DEF in_obj_owner = '&3.'
DEF in_obj_var   = '&4.'

UNDEF 1 2 3 4

@@&&fc_def_output_file. step_file_meta 'step_file_meta.sql'
DEF exec_file_meta    = '&&step_file_meta.'
@@&&fc_def_output_file. meta_pre_settings 'moat369_pre_meta_settings'

COL exec_file_meta NEW_V exec_file_meta
SELECT '&&fc_skip_script.' exec_file_meta from dual where '&&in_obj_type.' IS NULL OR '&&in_obj_name.' IS NULL OR '&&in_obj_owner.' IS NULL OR '&&in_obj_var.' IS NULL;
COL exec_file_meta clear

-- DEF in_obj_fname_type  = '&&in_obj_type.'
-- DEF in_obj_fname_name  = '&&in_obj_name.'
-- DEF in_obj_fname_owner = '&&in_obj_owner.'

DEF sqlout_file_meta  = '&&in_obj_owner. &&in_obj_name. &&in_obj_type.'
@@&&fc_clean_file_name. "sqlout_file_meta" "sqlout_file_meta"
@@&&fc_def_output_file. sqlout_file_meta '&&sqlout_file_meta..sql'

-- @@&&fc_clean_file_name. "in_obj_fname_type"  "in_obj_fname_type"
-- @@&&fc_clean_file_name. "in_obj_fname_name"  "in_obj_fname_name"
-- @@&&fc_clean_file_name. "in_obj_fname_owner" "in_obj_fname_owner"
-- DEF sqlout_file_meta  = '&&in_obj_fname_owner..&&in_obj_fname_name..&&in_obj_fname_type..sql'
-- 
-- UNDEF in_obj_fname_type in_obj_fname_name in_obj_fname_owner


EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT',true);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);

STORE SET &&meta_pre_settings. REPLACE
SET ECHO OFF
SET PAGES 0
SET LONG 2000000000
SET LINES 32767
SET TRIM ON
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET VERIFY OFF
SET TIMING OFF
SET HEAD OFF

SPOOL &&step_file_meta.
PRO SPO &&sqlout_file_meta.
PRO SELECT DBMS_METADATA.GET_DDL('&&in_obj_type.','&&in_obj_name.','&&in_obj_owner.') FROM DUAL;;
PRO SPO OFF
PRO DEF &&in_obj_var. = '&&sqlout_file_meta.'
SPO OFF

@&&exec_file_meta.
HOS rm -f &&step_file_meta.
@&&meta_pre_settings.
HOS rm -f &&meta_pre_settings..sql

UNDEF in_obj_type in_obj_name in_obj_owner in_obj_var
UNDEF sqlout_file_meta step_file_meta exec_file_meta meta_pre_settings