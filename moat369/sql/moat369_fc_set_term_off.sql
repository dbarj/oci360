-- This module will turn term output off only if debug mode is not enabled.
SET TERM OFF

COL c_set_term_off NEW_V c_set_term_off NOPRI
DEF c_set_term_off = 'TERM OFF'

SELECT 'TERM ON' c_set_term_off FROM DUAL WHERE UPPER(TRIM('&&DEBUG.')) = 'ON';
SET &&c_set_term_off.

COL c_set_term_off clear
UNDEF c_set_term_off