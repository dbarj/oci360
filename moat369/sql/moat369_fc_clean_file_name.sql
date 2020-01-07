-- Convert string on variable specified at parameter 1 to file_name string returned on variable specified on parameter 2
-- Param 1 = Input Variable
-- Param 2 = Output Variable
-- Param 3 = (Optional) If defined to PATH, remove PATH from variable. If NULL clear file as usual.

DEF in_param  = '&1.'
DEF out_param = '&2.'
UNDEF 1 2

@@&&fc_def_empty_var. 3
def type_param = '&&3.'
undef 3

@@&&fc_def_output_file. step_file 'step_file.sql'
@@&&fc_spool_start.
SPOOL &&step_file.
PRO DEF in_param_content = '&&&&in_param..'
SPOOL OFF
@@&&fc_spool_end.
@&&step_file.
HOS rm -f &&step_file.
UNDEF step_file

-- CHR:
-- 00 = NULL
-- 09 = TAB
-- 10 = LF
-- 13 = CR
-- 38 = &

COL &&out_param. NEW_V &&out_param.
SELECT REPLACE(TRANSLATE('&&in_param_content.',
'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ''`~!@#$%^*()-_=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789_'), '__', '_') &&out_param. FROM DUAL WHERE '&&type_param.' IS NULL;
SELECT SUBSTR('&&in_param_content.',INSTR('&&in_param_content.','/',-1)+1) &&out_param. FROM DUAL WHERE '&&type_param.' = 'PATH';
COL &&out_param. clear

UNDEF in_param in_param_content out_param type_param