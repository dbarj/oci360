--------------------------------------------------------------------
------- THIS FUNCTION IS DEPRECATED AND WILL BE REMOVED SOON -------
--------------------------------------------------------------------

-- This code will execute SQL file passed as first parameter only if it exists.
DEF in_file_name = '&1.'
UNDEF 1

@@&&fc_def_output_file. step_load_file_name 'step_load_file_name.sql'
DEF step_skip_file_name = '&&fc_skip_script.'

HOS echo "" > &&step_load_file_name.
HOS if [ -f &&in_file_name. ]; then echo "DEF step_skip_file_name = ''" > &&step_load_file_name.; fi
@&&step_load_file_name.
HOS rm -f &&step_load_file_name.
UNDEF step_load_file_name

@&&step_skip_file_name.&&in_file_name.

UNDEF in_file_name step_skip_file_name

--------------------------------------------------------------------
------- THIS FUNCTION IS DEPRECATED AND WILL BE REMOVED SOON -------
--------------------------------------------------------------------