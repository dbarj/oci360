@@&&fc_def_output_file. oci360_monit_report  'monit_section.html'

@@&&fc_spool_start.
SPO &&oci360_monit_report.
PRO <ol class="ol1">
SPO OFF
@@&&fc_spool_end.

DEF oci360_main_report_save = '&&moat369_main_report.'

DEF moat369_main_report = '&&oci360_monit_report.'