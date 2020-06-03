@@&&fc_def_output_file. step_json_file_name   'step_json_file_name.txt'
@@&&fc_def_output_file. step_json_file_driver 'step_json_file_driver.sql'

@@&&fc_set_term_off.

HOS ls -1 &&moat369_sw_output_fdr./oci_json_export_*.zip 2>&- > &&step_json_file_name.
HOS printf "HOS rm -f &&step_json_file_driver." > &&step_json_file_driver.
HOS if [ $(cat &&step_json_file_name. | wc -l) -eq 0 ]; then printf "PRO No zip file found in '&&moat369_sw_output_fdr.'.\nHOS rm -f original_settings.sql &&step_json_file_name. &&step_json_file_driver.\nEXIT SQL.SQLCODE" > &&step_json_file_driver.; fi
HOS if [ $(cat &&step_json_file_name. | wc -l) -ge 2 ]; then printf "PRO More than ONE zip file like oci_json_export_*.zip found in '&&moat369_sw_output_fdr.'.\nHOS rm -f original_settings.sql &&step_json_file_name. &&step_json_file_driver.\nEXIT SQL.SQLCODE" > &&step_json_file_driver.; fi

SET TERM ON

@@&&step_json_file_driver.
@@&&fc_set_term_off.

HOS echo "DEF oci360_json_zip = \"$(cat &&step_json_file_name.)\"" > &&step_json_file_driver.
@@&&step_json_file_driver.

-- Files will be unzipped on-demand now.
-- HOS unzip -o -d &&moat369_sw_output_fdr. &&oci360_json_zip.

HOS rm -f &&step_json_file_name.
HOS rm -f &&step_json_file_driver.

UNDEF step_json_file_name
UNDEF step_json_file_driver

-- HOS cd &&moat369_sw_folder.; echo "DEF oci360_export_file=\"$(ls -1 oci_json_export_*.zip)\"" > &&step_json_file_driver.
-- HOS cd &&moat369_sw_folder.; ls -1 oci_json_export_* | xargs unzip -d &&moat369_sw_output_fdr.
-- 
-- 
-- 
