-- If variable exists, does not declare it again. So the current value is maintained.
-- The select below will drop an error if variable doesn't exist.

DEF in_param_var = '&&1.'
UNDEF 1

COL moat369_var_declare NEW_V moat369_var_declare NOPRI
DEF moat369_var_declare = 'VAR &&in_param_var. NUMBER'
SELECT '' moat369_var_declare FROM DUAL WHERE :&&in_param_var. IS NULL OR :&&in_param_var. IS NOT NULL;
COL moat369_var_declare CLEAR

@@&&fc_def_output_file. step_file_dec_var 'step_file_dec_var.sql'
SPO &&step_file_dec_var.
PRO &&moat369_var_declare.
SPO OFF
@&&step_file_dec_var.
HOS rm -f &&step_file_dec_var.
UNDEF step_file_dec_var moat369_var_declare

UNDEF in_param_var