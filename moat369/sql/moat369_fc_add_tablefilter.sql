-- Parameter 1 : HTML file to have tag fixed
DEF in_html_src_file = '&1.'
UNDEF 1
--
@@&&fc_def_empty_var. filtertab_option1
@@&&fc_def_empty_var. filtertab_option2
@@&&fc_def_empty_var. filtertab_option3
@@&&fc_def_empty_var. filtertab_option4
@@&&fc_set_value_var_nvl. 'filtertab_option1' "&&filtertab_option1." "alternate_rows: true, col_types: ['number'],"
@@&&fc_set_value_var_nvl. 'filtertab_option2' "&&filtertab_option2." "rows_counter: true, btn_reset: true, loader: true,"
@@&&fc_set_value_var_nvl. 'filtertab_option3' "&&filtertab_option3." "status_bar: true, mark_active_columns: true, highlight_keywords: true,"
@@&&fc_set_value_var_nvl. 'filtertab_option4' "&&filtertab_option4." "auto_filter: true, extensions:[{ name: 'sort' }]"

-- Add <thead> to first row so column sort can work.
HOS sh &&moat369_fdr_sh./add_thead_tag_html.sh '&&in_html_src_file.'

SPO &&in_html_src_file. APP
PRO #: click on a column heading to sort on it
PRO <br>
SPO OFF

SPO &&in_html_src_file. APP
-- Filter TABLE
PRO <script id="tablefilter" type="text/javascript" src="tablefilter/tablefilter.js"></script>
PRO <script id="tablefilter-cfg" data-config>
PRO     var filtersConfig = {
PRO         base_path: 'tablefilter/',
PRO         &&filtertab_option1.
PRO         &&filtertab_option2.
PRO         &&filtertab_option3.
PRO         &&filtertab_option4.
PRO     };;
PRO 
PRO     var tf = new TableFilter('maintable', filtersConfig);;
PRO     tf.init();;
PRO 
PRO </script>
SPO OFF

UNDEF in_html_src_file

UNDEF filtertab_option1 filtertab_option2 filtertab_option3 filtertab_option4

DEF moat369_tf_usage = 'Y'
--