-- This code will check if SQL file passed as first parameter exists and will return T or F in the second argument variable.
DEF in_file_name = '&1.'
DEF in_var_name  = '&2.'
DEF in_if_true   = '&3.'
DEF in_if_false  = '&4.'
UNDEF 1 2 3 4

@@&&fc_def_output_file. step_load_file_name 'step_load_file_name.sql'

HOS echo "DEF &&in_var_name. = '&&in_if_false.'" > &&step_load_file_name.
HOS if [ -f &&in_file_name. ]; then echo "DEF &&in_var_name. = '&&in_if_true.'" > &&step_load_file_name.; fi
@&&step_load_file_name.
HOS rm -f &&step_load_file_name.
UNDEF step_load_file_name

UNDEF in_file_name in_var_name in_if_true in_if_false