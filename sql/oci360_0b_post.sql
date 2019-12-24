-- Remove JSON files

---- Clean external table objects
@@&&moat369_sw_folder./oci360_fc_exttables_drop.sql
--
HOS zipinfo -1 &&oci360_json_zip. | xargs -i rm -f &&moat369_sw_output_fdr./{}
--
HOS zip -mj &&moat369_zip_filename. &&oci360_log. >> &&moat369_log3.
UNDEF oci360_log

--
HOS rm -f &&oci360_json_files. 
HOS rm -f &&oci360_jsoncol_file.
HOS rm -f &&oci360_jsontab_file.

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
UNDEF oci360_jsoncol_file
UNDEF oci360_jsoncol_file_nopath
UNDEF oci360_jsontab_file
UNDEF oci360_jsontab_file_nopath