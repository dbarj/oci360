-- Check mandatory variables
@@&&fc_def_empty_var. one_spool_text_file
@@&&fc_def_empty_var. one_spool_text_file_type
@@&&fc_def_empty_var. one_spool_text_file_rename

-- add seq to one_spool_filename
BEGIN IF '&&one_spool_text_file_rename.' = 'Y' THEN :file_seq := :file_seq + 1; END IF; END;
/

@@&&fc_set_value_var_nvl. one_spool_text_file_type '&&one_spool_text_file_type.' 'text'

-- one_spool_filename receive just the file_name of one_spool_text_file adapted.
SELECT DECODE(
 '&&one_spool_text_file_rename.','Y',
 LPAD(:file_seq, 5, '0')||'_&&common_moat369_prefix._&&section_id._&&report_sequence._' || FILE_NAME,
 FILE_NAME) one_spool_filename
FROM (
select substr(word,1,instr(word,'/',-1)) PATH, substr(word,instr(word,'/',-1)+1) FILE_NAME
from (select '&&one_spool_text_file.' word from dual));

@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename.'

-- display
SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') hh_mm_ss FROM DUAL;
SET TERM ON;
SPO &&moat369_log. APP
PRO &&hh_mm_ss. &&section_id. "&&one_spool_filename."
SPO OFF
@@&&fc_set_term_off.

-- get time t0
EXEC :get_time_t0 := DBMS_UTILITY.get_time;

-- Protect accidentally renaming files not in Output Folder. Check if one_spool_text_file is on Output Folder if renaming is enabled.
COL one_spool_text_file_chk NEW_V one_spool_text_file_chk NOPRI
select
  decode(PATH,'&&moat369_sw_output_fdr./',decode(FILE_NAME,translate(FILE_NAME,'/\\',' '),'OK','NOK1'),'NOK2') one_spool_text_file_chk
from (
select substr('&&one_spool_text_file.',1,length('&&moat369_sw_output_fdr./')) PATH, -- PATH
       substr('&&one_spool_text_file.',length('&&moat369_sw_output_fdr./')+1) FILE_NAME -- FILENAME
from dual);
COL one_spool_text_file_chk clear

HOS if [ '&&one_spool_text_file_rename.' == 'Y' ]; then touch &&one_spool_fullpath_filename.; fi
HOS if [ '&&one_spool_text_file_rename.' == 'Y' -a -f &&one_spool_text_file. -a '&&one_spool_text_file_chk.' == 'OK' ]; then mv &&one_spool_text_file. &&one_spool_fullpath_filename.; fi
UNDEF one_spool_text_file_chk

@@&&fc_def_output_file. step_file 'step_file.sql'
HOS echo "DEF row_num = '"$(if [ -f &&one_spool_fullpath_filename. ]; then cat &&one_spool_fullpath_filename. | wc -l | tr -d '[:space:]'; else echo -1; fi)"'" > &&step_file.
@&&step_file.
HOS rm -f &&step_file.
UNDEF step_file

-- get sql_id
SELECT prev_sql_id moat369_prev_sql_id, TO_CHAR(prev_child_number) moat369_prev_child_number FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID');

-- get time t1
EXEC :get_time_t1 := DBMS_UTILITY.get_time;

-- update log2
SET HEA OFF;
SPO &&moat369_log2. APP;
SELECT TO_CHAR(SYSDATE, '&&moat369_date_format.')||' , '||
       TO_CHAR((:get_time_t1 - :get_time_t0)/100, '999,999,990.00')||'s , rows:'||
       '&&row_num., &&section_id., &&main_table., &&moat369_prev_sql_id., &&moat369_prev_child_number., &&one_spool_filename., txt , &&one_spool_filename.'
  FROM DUAL
/
SPO OFF;
SET HEA ON;

@@&&fc_def_output_file. step_file 'step_file.sql'
HOS if [ '&&one_spool_text_file_rename.' == 'Y' ]; then echo "@&&fc_convert_txt_to_html. one_spool_fullpath_filename" > &&step_file.; fi
HOS if [ '&&one_spool_text_file_rename.' == 'Y' ]; then echo "@&&fc_encode_html. &&""one_spool_fullpath_filename." >> &&step_file.; fi
@&&step_file.
HOS rm -f &&step_file.
UNDEF step_file

-- Get one_spool_filename from one_spool_fullpath_filename in case it was renamed by functions above.
SELECT FILE_NAME one_spool_filename
FROM (
select substr(word,1,instr(word,'/',-1)) PATH, substr(word,instr(word,'/',-1)+1) FILE_NAME
from (select '&&one_spool_fullpath_filename.' word from dual));

-- update main report
@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
PRO <a href="&&one_spool_filename.">&&one_spool_text_file_type.</a>
SPO OFF;
@@&&fc_spool_end.

HOS if [ '&&one_spool_text_file_rename.' == 'Y' ]; then zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.; fi

UNDEF one_spool_text_file one_spool_text_file_rename one_spool_text_file_type

UNDEF one_spool_fullpath_filename