DEF oci360_6a_json_prefix = "oci_dns_"
-----------------------------------------
@@&&fc_def_output_file. step_meta_pre_loader 'step_meta_pre_loader.sql'
HOS &&cmd_awk. -F',' '$1 ~ /^&&oci360_6a_json_prefix./ { print "@@&&fc_json_metadata. \""$3"\" \""$1"\""; }' &&oci360_tables. > &&step_meta_pre_loader.
@@&&step_meta_pre_loader.
@@&&fc_zip_driver_files. &&step_meta_pre_loader.
UNDEF step_meta_pre_loader
-----------------------------------------
DEF oci360_6a_json_prefix = "oci_email_"
-----------------------------------------
@@&&fc_def_output_file. step_meta_pre_loader 'step_meta_pre_loader.sql'
HOS &&cmd_awk. -F',' '$1 ~ /^&&oci360_6a_json_prefix./ { print "@@&&fc_json_metadata. \""$3"\" \""$1"\""; }' &&oci360_tables. > &&step_meta_pre_loader.
@@&&step_meta_pre_loader.
@@&&fc_zip_driver_files. &&step_meta_pre_loader.
UNDEF step_meta_pre_loader
-----------------------------------------
DEF oci360_6a_json_prefix = "oci_search_"
-----------------------------------------
@@&&fc_def_output_file. step_meta_pre_loader 'step_meta_pre_loader.sql'
HOS &&cmd_awk. -F',' '$1 ~ /^&&oci360_6a_json_prefix./ { print "@@&&fc_json_metadata. \""$3"\" \""$1"\""; }' &&oci360_tables. > &&step_meta_pre_loader.
@@&&step_meta_pre_loader.
@@&&fc_zip_driver_files. &&step_meta_pre_loader.
UNDEF step_meta_pre_loader
-----------------------------------------
DEF oci360_6a_json_prefix = "oci_limits_"
-----------------------------------------
@@&&fc_def_output_file. step_meta_pre_loader 'step_meta_pre_loader.sql'
HOS &&cmd_awk. -F',' '$1 ~ /^&&oci360_6a_json_prefix./ { print "@@&&fc_json_metadata. \""$3"\" \""$1"\""; }' &&oci360_tables. > &&step_meta_pre_loader.
@@&&step_meta_pre_loader.
@@&&fc_zip_driver_files. &&step_meta_pre_loader.
UNDEF step_meta_pre_loader
-----------------------------------------