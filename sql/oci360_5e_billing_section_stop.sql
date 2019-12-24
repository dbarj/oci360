@@&&fc_spool_start.
SPO &&oci360_billing_report. APP
PRO </ol>
SPO OFF
@@&&fc_spool_end.

DEF moat369_main_report = '&&oci360_main_report_save.'

DEF one_spool_html_file = '&&oci360_billing_report.'
DEF one_spool_html_file_type = 'section'

@@&&fc_def_output_file. step_file 'step_file.sql'
HOS echo "DEF row_num_dif = '"$(($(cat &&oci360_billing_report. | grep '</li>' | wc -l)+1))"'" > &&step_file.
@&&step_file.
HOS rm -f &&step_file.
UNDEF step_file

DEF skip_html_file = ''
DEF skip_html = '--'
@@&&9a_pre_one.

UNDEF oci360_billing_report oci360_main_report_save