@@&&fc_def_output_file. step_csv_file_name   'step_csv_file_name.txt'
@@&&fc_def_output_file. step_csv_file_driver 'step_csv_file_driver.sql'

@@&&fc_set_term_off.

HOS ls -1 &&moat369_sw_output_fdr./oci_csv_usage_*.zip 2>&- > &&step_csv_file_name.
HOS printf "HOS rm -f &&step_csv_file_driver." > &&step_csv_file_driver.
HOS if [ $(cat &&step_csv_file_name. | wc -l) -ge 2 ]; then printf "PRO More than ONE zip file like oci_csv_usage_*.zip found in '&&moat369_sw_output_fdr.'.\nHOS rm -f original_settings.sql &&step_csv_file_name. &&step_csv_file_driver.\nEXIT SQL.SQLCODE" > &&step_csv_file_driver.; fi

SET TERM ON

@@&&step_csv_file_driver.
@@&&fc_set_term_off.

HOS echo "DEF oci360_csv_report_zip = \"$(cat &&step_csv_file_name.)\"" > &&step_csv_file_driver.
@@&&step_csv_file_driver.

HOS rm -f &&step_csv_file_name.
HOS rm -f &&step_csv_file_driver.

UNDEF step_csv_file_name
UNDEF step_csv_file_driver
