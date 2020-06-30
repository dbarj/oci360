-- Remove JSON files

---- Clean external table objects
@@&&moat369_sw_folder./oci360_fc_exttables_drop.sql
--

-- If Local
@@&&fc_def_output_file. oci360_step_file 'oci360_step_zip_file.sql'
@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO HOS cat "&&oci360_json_files." | xargs -i rm -f &&moat369_sw_output_fdr./{}
SPO OFF
@@&&fc_spool_end.
@@&&oci360_loc_skip.&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file
--

HOS zip -mj &&moat369_zip_filename. &&oci360_log_json. >> &&moat369_log3.
UNDEF oci360_log_json

HOS zip -mj &&moat369_zip_filename. &&oci360_log_csv.  >> &&moat369_log3.
UNDEF oci360_log_csv

--
@@&&fc_zip_driver_files. &&oci360_json_files. 
@@&&fc_zip_driver_files. &&oci360_csv_files. 
--HOS rm -f &&oci360_jsoncol_file.
--HOS rm -f &&oci360_jsontab_file.

-- Undef variables
UNDEF oci360_collector
UNDEF oci360_tables
UNDEF fc_json_loader
UNDEF fc_json_metadata
UNDEF oci360_tzcolformat
UNDEF skip_billing_sql

-- Undef config variables
UNDEF oci360_exec_mode
UNDEF oci360_load_mode
UNDEF oci360_clean_on_exit
UNDEF oci360_skip_billing

-- Undef other variables
UNDEF oci360_json_zip
UNDEF oci360_json_files
UNDEF oci360_json_files_nopath
UNDEF oci360_csv_report_zip
UNDEF oci360_csv_files
UNDEF oci360_csv_files_nopath

-- UNDEF oci360_jsoncol_file
-- UNDEF oci360_jsoncol_file_nopath
-- UNDEF oci360_jsontab_file
-- UNDEF oci360_jsontab_file_nopath