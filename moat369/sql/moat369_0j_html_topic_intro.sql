-- Param1: file_name / Param2: Type
def 0j_param1 = '&&1.'
def 0j_param2 = '&&2.'
undef 1 2

-- display
SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') hh_mm_ss FROM DUAL;
@@&&fc_spool_start.
SET TERM ON
SPO &&moat369_log. APP
PRO &&hh_mm_ss. &&section_id. "&&0j_param1."
SPO OFF
@@&&fc_set_term_off.
@@&&fc_spool_end.

-- update main report
@@&&fc_spool_start.
SPO &&moat369_main_report. APP
PRO <a href="&&0j_param1.">&&0j_param2.</a>
SPO OFF
@@&&fc_spool_end.

-- get time t0
EXEC :get_time_t0 := DBMS_UTILITY.get_time;

-- header
@@&&fc_spool_start.
SPO &&moat369_sw_output_fdr./&&0j_param1.
@@moat369_0d_html_header.sql
SPO OFF
@@&&fc_spool_end.

-- javascripts
HOS if [ '&&sql_format.' == 'Y' ]; then echo '<script type="text/javascript" src="sql-formatter.js"></script>' >> &&moat369_sw_output_fdr./&&0j_param1.; fi
HOS if [ '&&sql_hl.' == 'Y' ]; then echo '<script type="text/javascript" src="highlight.pack.js"></script>' >> &&moat369_sw_output_fdr./&&0j_param1.; fi
HOS if [ '&&sql_hl.' == 'Y' ]; then echo '<link rel="stylesheet" href="vs.css">' >> &&moat369_sw_output_fdr./&&0j_param1.; fi

@@&&fc_def_empty_var. main_table_print
@@&&fc_set_value_var_nvl2. main_table_print '&&main_table.' ' <em>(&&main_table.)</em>' ''

-- topic begin
@@&&fc_spool_start.
SPO &&moat369_sw_output_fdr./&&0j_param1. APP
PRO
PRO <!-- &&0j_param1. $ -->
PRO </head>
PRO <body>
PRO <h1> <img src="&&moat369_sw_logo_file." alt="&&moat369_sw_name." height="46" width="47" /> &&section_id..&&report_sequence.. &&title.&&title_suffix.&&main_table_print.</h1>
PRO <!--BEGIN_SENSITIVE_DATA-->
PRO <br>
PRO &&abstract.
PRO &&abstract2.
PRO
SPO OFF
@@&&fc_spool_end.

undef main_table_print
undef 0j_param1 0j_param2