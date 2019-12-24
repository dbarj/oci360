-- Param1: file_name 
-- Param2: Type
-- Param3: Print Table (Default Y)
-- Param4: Print SQL (Default Y)

def 0k_param1 = '&&1.'
def 0k_param2 = '&&2.'
undef 1 2
@@&&fc_def_empty_var. 3
@@&&fc_def_empty_var. 4
def 0k_param3 = '&&3.'
def 0k_param4 = '&&4.'
undef 3 4
@@&&fc_set_value_var_nvl. '0k_param3' '&&0k_param3.' 'Y'
@@&&fc_set_value_var_nvl. '0k_param4' '&&0k_param4.' 'Y'

-- DOES NOT WORK setting one_spool_fullpath_filename as 1st parameter. Why? IDK..
def 0k_var1 = '&&moat369_sw_output_fdr./&&0k_param1.'

@@&&fc_spool_start.
SPO &&0k_var1. APP
PRO <pre>
SPO &&0k_var1..tmp
SET LIN &&moat369_sw_desc_linesize.
DESC &&main_table.
SET HEA OFF LIN 32767
SPO OFF
HOS if [ '&&0k_param3.' == 'Y' -a -n '&&main_table.' ]; then cat &&0k_var1..tmp >> &&0k_var1.; fi
SPO &&0k_var1. APP
PRO <code class="sql" id="SQL_Query">
SPO &&0k_var1..tmp
PRINT sql_text_display
SPO OFF
HOS if [ '&&sql_format.' == 'N' -a '&&0k_param4.' == 'Y' ]; then cat &&0k_var1..tmp >> &&0k_var1.; fi
SPO &&0k_var1. APP
PRO </code>
SPO &&0k_var1..tmp
PRO &&row_num. rows selected.
SPO OFF
HOS if [ '&&0k_param4.' == 'Y' ]; then cat &&0k_var1..tmp >> &&0k_var1.; fi
SPO &&0k_var1. APP
PRO </pre>
SPO &&0k_var1..tmp
PRO <script type="text/javascript" id="sqlfor_script">
PRO document.getElementById("SQL_Query").innerHTML = window.sqlFormatter.format(" " +
SELECT 
  CHR(34) || REPLACE(REPLACE(:sql_text_display,CHR(34),CHR(92)||CHR(34)),CHR(10),' " +'||CHR(10)||'" ') || CHR(34) || '+'
FROM dual;
SET HEA ON
PRO " ");
PRO </script>
SPO OFF
HOS if [ '&&sql_format.' == 'Y' -a '&&0k_param4.' == 'Y' ]; then cat &&0k_var1..tmp >> &&0k_var1.; fi
SPO &&0k_var1..tmp
PRO <script type="text/javascript" id="sqlhl_script">hljs.initHighlighting();</script>
SPO OFF
HOS if [ '&&sql_hl.' == 'Y' -a '&&0k_param4.' == 'Y' ]; then cat &&0k_var1..tmp >> &&0k_var1.; fi
HOS rm -f &&0k_var1..tmp
SPO &&0k_var1. APP
PRO <!--END_SENSITIVE_DATA-->
@@moat369_0e_html_footer.sql
SPO OFF
@@&&fc_spool_end.

-- get time t1
EXEC :get_time_t1 := DBMS_UTILITY.get_time;

-- update log2
SET HEA OFF
SPO &&moat369_log2. APP
SELECT TO_CHAR(SYSDATE, '&&moat369_date_format.')||' , '||
       TO_CHAR((:get_time_t1 - :get_time_t0)/100, '999,999,990.00')||'s , rows:'||
       '&&row_num., &&section_id., &&main_table., &&moat369_prev_sql_id., &&moat369_prev_child_number., &&title_no_spaces., &&0k_param2. , &&0k_param1.'
  FROM DUAL
/
SPO OFF
SET HEA ON

undef 0k_param1 0k_param2 0k_param3 0k_param4 0k_var1