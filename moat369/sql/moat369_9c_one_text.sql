-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename..txt'

-- display
SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') hh_mm_ss FROM DUAL;
SET TERM ON
SPO &&moat369_log. APP
PRO &&hh_mm_ss. &&section_id. "&&one_spool_filename..txt"
SPO OFF
@@&&fc_set_term_off.

-- update main report
SPO &&moat369_main_report. APP;
PRO <a href="&&one_spool_filename..txt">text</a>
SPO OFF;

-- get time t0
EXEC :get_time_t0 := DBMS_UTILITY.get_time;

-- get sql
GET &&moat369_query.

-- header
SPO &&one_spool_fullpath_filename.;
PRO &&title.&&title_suffix. (&&main_table.) 
PRO
PRO &&abstract.
PRO &&abstract2.
PRO

-- body
/
SPO OFF

-- get sql_id
SELECT prev_sql_id moat369_prev_sql_id, TO_CHAR(prev_child_number) moat369_prev_child_number FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID');

@@&&fc_check_last_sql_status.

SPO &&one_spool_fullpath_filename. APP
-- footer
PRO &&foot.
SET LIN &&moat369_sw_desc_linesize.
DESC &&main_table.
SET HEA OFF LIN 32767
PRINT sql_text_display;
SET HEA ON
PRO &&row_num. rows selected.

PRO 
PRO &&moat369_sw_copyright. &&moat369_sw_name. &&moat369_sw_vrsn. based on moat369 &&moat369_fw_vrsn.. Timestamp: &&moat369_time_stamp. &&total_hours.
SPO OFF;

-- get time t1
EXEC :get_time_t1 := DBMS_UTILITY.get_time;

-- update log2
SET HEA OFF;
SPO &&moat369_log2. APP;
SELECT TO_CHAR(SYSDATE, '&&moat369_date_format.')||' , '||
       TO_CHAR((:get_time_t1 - :get_time_t0)/100, '999,999,990.00')||'s , rows:'||
       '&&row_num., &&section_id., &&main_table., &&moat369_prev_sql_id., &&moat369_prev_child_number., &&title_no_spaces., txt , &&one_spool_filename..txt'
  FROM DUAL
/
SPO OFF;
SET HEA ON;

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

UNDEF one_spool_fullpath_filename