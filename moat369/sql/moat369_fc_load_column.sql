-- This code will check for all sections configured for a given column (parameter 1) and load them.
DEF moat369_cur_col_id = '&1.'
UNDEF 1

DEF moat369_sections_file  = '&&moat369_sw_folder./00_sections.csv'

-- The variable below will be changed to YES if the code ever enter in 9a
DEF moat369_column_print = 'NO'

@@&&fc_def_output_file. moat369_col_temp_file 'moat369_temp_onload_section_&&moat369_cur_col_id..sql'
HOS &&cmd_grep. -e "^&&moat369_cur_col_id." &&moat369_sections_file. | while read line || [ -n "$line" ]; do echo $line | &&cmd_awk. -F',' '{printf("@"$4"&&""&&moat369_sw_name._"$1".&&""fc_call_secion. "$1" &&moat369_sw_name._"$1"_"$2" "$3"\n")}'; done > &&moat369_col_temp_file.
@&&moat369_col_temp_file.
@@&&fc_zip_driver_files. &&moat369_col_temp_file.
UNDEF moat369_col_temp_file

HOS unzip &&moat369_zip_filename. &&moat369_style_css. -d &&moat369_sw_output_fdr. >> &&moat369_log3.
HOS if [ "&&moat369_column_print." == "NO" ];  then echo "td.i&&moat369_cur_col_id.            {display:none;}" >> &&moat369_sw_output_fdr./&&moat369_style_css.; fi 
HOS if [ "&&moat369_column_print." == "YES" ]; then echo "td.i&&moat369_cur_col_id.            {}" >> &&moat369_sw_output_fdr./&&moat369_style_css.; fi 
HOS zip -mj &&moat369_zip_filename. &&moat369_sw_output_fdr./&&moat369_style_css. >> &&moat369_log3.

UNDEF moat369_cur_col_id moat369_sections_file moat369_column_print