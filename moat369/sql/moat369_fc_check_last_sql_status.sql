-- This code will if row_num is -1 meaning no lines were returned by the sql_text.
-- If it is, it will count lines on table to ensure it is empty and update to 0.

@@&&fc_def_output_file. step_file  'step_file_recount.sql'

-- Define SELECT start line. Var used in cfc_check_last_sql_status
COL line_no NEW_V moat369_select_start_line
SELECT NVL(LENGTH(:sql_with_clause) - LENGTH(REPLACE(:sql_with_clause, CHR(10), '')),0)+1 line_no from dual;
COL line_no clear

@@&&fc_spool_start.
SPO &&step_file.
PRO COL row_num NOPRI
PRO GET &&moat369_query.
PRO -- remove rownum
PRO &&moat369_select_start_line.
PRO c/TO_CHAR(ROWNUM) row_num, v0.*/TRIM(COUNT(*)) row_num
PRO /
PRO COL row_num PRI
SPO OFF
@@&&fc_spool_end.

@@&&fc_set_value_var_decode. 'step_file_exec' '&&row_num.' '-1' '&&step_file.' '&&fc_skip_script. &&step_file.'

@&&step_file_exec.
HOS rm -f &&step_file.
UNDEF step_file step_file_exec moat369_select_start_line