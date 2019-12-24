-- Exit the program if not connect to any database in sqlplus.
-- Do not use "fc_set_term_off" in this script to avoid replacing main 1st parameter.
SET TERM OFF

DEF step_file = '/tmp/step_file.sql'
DEF exit_file = '/tmp/exit_now.sql'

SPOOL &&step_file.
SELECT 'I_AM_HERE_' || COUNT(*) FROM DUAL;
SPOOL OFF

HOS printf "HOS rm -f &&exit_file." > &&exit_file.
HOS grep "I_AM_HERE_1" &&step_file. 1>/dev/null || printf "PRO YOU ARE NOT CONNECTED\nHOS rm -f original_settings.sql\nHOS rm -f &&exit_file.\nEXIT SQL.SQLCODE" > &&exit_file.

HOS rm -f &&step_file.
UNDEF step_file

SET TERM ON

@&&exit_file.
UNDEF exit_file

SET TERM OFF