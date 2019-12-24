DEF in_json_param_1 = "&&1."
DEF in_json_param_2 = "&&2."

-----------------------------------------
DEF title = '&&in_json_param_1.'
DEF main_table = '&&in_json_param_2.'

@@&&fc_def_output_file. out_filename '&&in_json_param_2..txt'

HOS if [ -f &&moat369_sw_output_fdr./&&in_json_param_2. ]; then cp &&moat369_sw_output_fdr./&&in_json_param_2. &&out_filename.; fi

DEF one_spool_text_file = '&&out_filename.'
DEF one_spool_text_file_type = 'json'
DEF one_spool_text_file_rename = 'Y'
DEF skip_html = '--'
DEF skip_text_file = ''
@@&&9a_pre_one.

UNDEF out_filename
-----------------------------------------

UNDEF in_json_param_1
UNDEF in_json_param_2
