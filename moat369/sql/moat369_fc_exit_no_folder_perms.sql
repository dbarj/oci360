-- Exit the program if not connect to any database in sqlplus.
-- Do not use "fc_set_term_off" in this script to avoid replacing main 1st parameter.
SET TERM OFF

DEF exit_file = '/tmp/exit_now.sql'

HOS printf "HOS rm -f &&exit_file." > &&exit_file.
HOS [ -w "&&moat369_sw_output_fdr." ] || printf "PRO OUTPUT FOLDER '&&moat369_sw_output_fdr.' NOT WRITABLE\nHOS rm -f original_settings.sql\nHOS rm -f &&exit_file.\nEXIT 1" > &&exit_file.

SET TERM ON

@&&exit_file.
UNDEF exit_file

SET TERM OFF