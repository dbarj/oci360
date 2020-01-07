-- Define variable as empty string >>> IF UNSET <<<
-- Useful if you don't know if the variable is declared but don't want to stop the code asking for it.

COL c_def_empty_var NEW_V &&1. NOPRI
SELECT '' c_def_empty_var FROM dual WHERE ROWNUM = 0;
COL c_def_empty_var clear

UNDEF 1
