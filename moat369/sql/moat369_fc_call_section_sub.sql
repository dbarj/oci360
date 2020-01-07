-- This code will call a section and print it.
-- Param 1 = Section ID 
-- Param 2 = Section Name
-- Param 3 = File Name

DEF moat369_subsec_id = '&1.'
DEF moat369_subsec_fl = '&2.'
DEF moat369_subsec_nm = '&3.'
UNDEF 1 2 3

@@&&skip_tkprof.moat369_0g_tkprof.sql
DEF section_id = '&&moat369_subsec_id.';
DEF section_name = '&&moat369_subsec_nm.';
EXEC DBMS_APPLICATION_INFO.SET_MODULE('&&moat369_prefix.','&&section_id.');
@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
PRO <h3>&&section_id.. &&section_name.</h3>
PRO <ol start="&&report_sequence.">
SPO OFF;
@@&&fc_spool_end.

-- Reset section related DEFs
@@&&fc_reset_defs.

@@&&fc_def_output_file. sub_section_fifo '&&moat369_subsec_id._fifo.sql'
-- HOS mkfifo &&sub_section_fifo.
set define ^
HOS [ '^^moat369_sw_enc_sql.' == 'Y' ] && (cat ^^moat369_sw_folder./^^moat369_subsec_fl. | openssl enc -d -aes256 -a -salt -pass file:^^moat369_enc_pub_file. > ^^sub_section_fifo.)
-- HOS [ '^^moat369_sw_enc_sql.' != 'Y' ] && (echo "@@^^moat369_sw_folder./^^moat369_subsec_fl." > ^^sub_section_fifo.) Commented to reduce nested queries
HOS [ '^^moat369_sw_enc_sql.' != 'Y' ] && (cat ^^moat369_sw_folder./^^moat369_subsec_fl. > ^^sub_section_fifo.)
set define &

@&&sub_section_fifo.
HOS rm &&sub_section_fifo.

@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
PRO </ol>
SPO OFF;
@@&&fc_spool_end.

UNDEF section_id section_name sub_section_fifo

UNDEF moat369_subsec_id moat369_subsec_fl moat369_subsec_nm