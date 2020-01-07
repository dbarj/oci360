-- This code will check if parameter 1 has a valid file. If it does, it will convert the file to html and update the input parameter with the new name.
DEF in_param = "&1."
UNDEF 1

@@&&fc_def_output_file. step_file_conv 'step_file_conv.sql'
HOS echo "DEF in_param_content = '&&""&&in_param..'" > &&step_file_conv.
@&&step_file_conv.

HOS if [ -f &&in_param_content. ]; then echo "HOS sh &&moat369_fdr_sh./txt_to_html.sh &&""in_param_content." > &&step_file_conv.; fi
@&&step_file_conv.
HOS if [ -f &&in_param_content..html ]; then echo "DEF &&in_param. = '&&""in_param_content..html'" > &&step_file_conv.; fi
@&&step_file_conv.

HOS rm -f &&step_file_conv.
UNDEF step_file_conv

UNDEF in_param in_param_content