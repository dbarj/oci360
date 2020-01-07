-- This code will clear all the DEFINE variables
@@&&fc_def_output_file. all_def_step_file  'all_def_step_file.sql'
@@&&fc_def_output_file. clear_def_exec_file  'clear_def_exec_file.sql'

-- Save File
SPO &&all_def_step_file.
DEF
SPO OFF

HOS cat &&all_def_step_file. | &&cmd_grep. -Eo '^DEFINE [^ ]+' | sed 's/^DEFINE //' | &&cmd_grep. -Ev '^_' | xargs -n 1 echo UNDEF >> &&clear_def_exec_file.
HOS rm -f &&all_def_step_file.

SPO &&clear_def_exec_file. APP
PRO HOS rm -f &&clear_def_exec_file.
SPO OFF

-- This is working but generating the driver file in wrong zipped file.
-- HOS cp &&clear_def_exec_file. &&clear_def_exec_file..2
-- @@&&fc_zip_driver_files. &&clear_def_exec_file.
-- HOS mv &&clear_def_exec_file..2 &&clear_def_exec_file.

@@&&clear_def_exec_file.

UNDEF all_def_step_file clear_def_exec_file