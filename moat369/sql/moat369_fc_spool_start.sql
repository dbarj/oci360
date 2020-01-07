-- This module will prepare SQL*Plus to begin SPOOL
-- This module will turn term output off only if debug mode is not enabled.
COL c_spool_start NEW_V c_spool_start NOPRI
DEF c_spool_start = 'TERM OFF ECHO OFF FEED OFF VER OFF HEAD OFF'

SELECT 'TERM ON ECHO OFF FEED OFF VER OFF HEAD OFF' c_spool_start FROM DUAL WHERE UPPER(TRIM('&&DEBUG.')) = 'ON';
SET &&c_spool_start.

COL c_spool_start clear
UNDEF c_spool_start