-- This code will create/restore/save the define and bind variables of the current execution. Useful when running multiple MOAT369 tools.
-- Param1: CREATE, RESTORE or SAVE
-- Param2: Checkpoint Name
-- Param3: Variable that will receive the PATH where CREATED/SAVED/RESTORED file is placed
-- Param4: (Optional used for RESTORE) If empty full, restore is applied. Single UPPERCASE variable to be read from checkpoint file.
-- Param5: (Optional used for RESTORE) If empty full, restore is applied. Single UPPERCASE variable to be defined with the value from variable of param4.

-- Definitions for Param1
-- CREATE = Create a file with all current bind and define variables.
-- RESTORE = Restore the file with all bind and define variables. Everything is cleared before RESTORE.
-- SAVE = Save the file inside current driver zip file and delete it.

DEF in_param1 = '&1.'
DEF in_param2 = '&2.'
DEF in_param3 = '&3.'
UNDEF 1 2 3

@@&&fc_def_empty_var. 4
@@&&fc_def_empty_var. 5
DEF in_param4 = '&4.'
DEF in_param5 = '&5.'
UNDEF 4 5

@@&&fc_def_output_file. create_step_file     'create_step_file.sql'
@@&&fc_def_output_file. rest_step_file       'rest_step_file.sql'
@@&&fc_def_output_file. save_step_file       'save_step_file.sql'
@@&&fc_def_output_file. gen_filter_step_file 'gen_filter_step_file.sql'
@@&&fc_def_output_file. all_def_step_file    'all_def_step_file.sql'
@@&&fc_def_output_file. filter_def_step_file 'filter_def_step_file.sql'
DEF db_state_file = '&&in_param3./&&in_param2..db_state_file.sql'

-- Create File
SPO &&create_step_file.
-- Script to Generate All DEFs
PRO SPO &&gen_filter_step_file.
PRO PRO SPO &&all_def_step_file.
PRO PRO DEF
PRO PRO SPO OFF
PRO PRO HOS cat &&all_def_step_file. | &&cmd_grep. -Eo '^DEFINE [^ ]+' | sed 's/^DEFINE //' | &&cmd_grep. -Ev '^_' | xargs -n 1 echo DEF > &&filter_def_step_file.
PRO PRO HOS rm -f &&all_def_step_file.
PRO SPO OFF
-- Run Script to Generate All DEFs
PRO @@&&gen_filter_step_file.
PRO HOS rm -f &&gen_filter_step_file.
-- Spool to DB State File
PRO SPO &&db_state_file.
PRO PRO SET DEFINE OFF 
PRO @@&&filter_def_step_file.
PRO HOS rm -f &&filter_def_step_file.
PRO PRO SET DEFINE ON
PRO SET HEA OFF FEED OFF
PRO SELECT 'EXEC :moat369_total_cols := ''' || :moat369_total_cols || ''';' from dual;;
PRO SELECT 'EXEC :moat369_main_time0 := ''' || :moat369_main_time0 || ''';' from dual;;
PRO --SELECT 'EXEC :file_seq :=           ''' || :file_seq           || ''';' from dual;;
PRO SELECT 'EXEC :driver_seq :=         ''' || :driver_seq         || ''';' from dual;;
PRO SELECT 'EXEC :repo_seq :=           ''' || :repo_seq           || ''';' from dual;;
PRO SELECT 'EXEC :temp_seq :=           ''' || :temp_seq           || ''';' from dual;;
PRO SELECT 'EXEC :get_time_t0 :=        ''' || :get_time_t0        || ''';' from dual;;
PRO SELECT 'EXEC :moat369_sec_from :=   ''' || :moat369_sec_from   || ''';' from dual;;
PRO SELECT 'EXEC :moat369_sec_to :=     ''' || :moat369_sec_to     || ''';' from dual;;
PRO SET HEA ON
PRO SPO OFF
SPO OFF

-- Restore File
SPO &&rest_step_file.
-- Script to Generate All DEFs
PRO SPO &&gen_filter_step_file.
PRO PRO HOS if [ '&&in_param4.' != '' ]; then cat &&db_state_file. | &&cmd_grep. -E '^DEFINE &&in_param4. ' | sed 's/ &&in_param4. / &&in_param5. /' > &&filter_def_step_file.; fi
PRO PRO HOS if [ '&&in_param4.' == '' ]; then echo "@@&&fc_clear_defs." > &&filter_def_step_file.; cat &&db_state_file. >> &&filter_def_step_file.; fi
PRO SPO OFF
-- Run Script to Generate All DEFs
PRO @@&&gen_filter_step_file.
PRO HOS rm -f &&gen_filter_step_file.
-- Execute DB State File
PRO @@&&filter_def_step_file.
PRO HOS rm -f &&filter_def_step_file.
SPO OFF

-- Save File
SPO &&save_step_file.
PRO @@&&fc_zip_driver_files. &&db_state_file.
SPO OFF

COL step_run_cmd NEW_V step_run_cmd
SELECT DECODE('&&in_param1.','CREATE','@&&create_step_file.','RESTORE','@&&rest_step_file.','SAVE','@&&save_step_file.','') step_run_cmd FROM DUAL;
COL step_run_cmd clear

@@&&fc_def_output_file. step_file 'step_file.sql'
SPO &&step_file.
PRO &&step_run_cmd.
PRO HOS rm -f &&create_step_file. &&rest_step_file. &&save_step_file.
PRO HOS rm -f &&step_file.
SPO OFF
@&&step_file.

UNDEF in_param1 in_param2 in_param3 in_param4 in_param5
UNDEF create_step_file save_step_file rest_step_file
UNDEF db_state_file step_run_cmd step_file
UNDEF gen_filter_step_file all_def_step_file filter_def_step_file