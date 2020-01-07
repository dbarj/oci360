-- This code will call a section and print it.
-- Param 1 = Section ID 
-- Param 2 = Section Name
-- Param 3 = File Name

DEF moat369_sec_id = '&1.'
DEF moat369_sec_fl = '&2.'
DEF moat369_sec_nm = '&3.'
UNDEF 1 2 3

@@&&skip_tkprof.moat369_0g_tkprof.sql
DEF section_id = '&&moat369_sec_id.';
DEF section_name = '&&moat369_sec_nm.';
EXEC DBMS_APPLICATION_INFO.SET_MODULE('&&moat369_prefix.','&&section_id.');
@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
PRO <h2>&&section_id.. &&section_name.</h2>
PRO <ol start="&&report_sequence.">
SPO OFF;
@@&&fc_spool_end.

-- Reset section related DEFs
@@&&fc_reset_defs.

@@&&fc_def_output_file. section_fifo '&&moat369_sec_id._fifo.sql'
-- HOS mkfifo &&section_fifo.
set define ^
HOS [ '^^moat369_sw_enc_sql.' == 'Y' ] && (cat ^^moat369_sw_folder./^^moat369_sec_fl. | openssl enc -d -aes256 -a -salt -pass file:^^moat369_enc_pub_file. > ^^section_fifo.)
-- HOS [ '^^moat369_sw_enc_sql.' != 'Y' ] && (echo "@@^^moat369_sw_folder./^^moat369_sec_fl." > ^^section_fifo.) Commented to reduce nested queries
HOS [ '^^moat369_sw_enc_sql.' != 'Y' ] && (cat ^^moat369_sw_folder./^^moat369_sec_fl. > ^^section_fifo.)
set define &

@&&section_fifo.
HOS rm &&section_fifo.

@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
PRO </ol>
SPO OFF;
@@&&fc_spool_end.

UNDEF section_id section_name section_fifo

UNDEF moat369_sec_id moat369_sec_fl moat369_sec_nm