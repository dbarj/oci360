-- Parameter 1 : HTML file to have tag fixed
DEF in_html_src_file = '&1.'
UNDEF 1
--

SPO &&in_html_src_file. APP
PRO #: click on a column heading to sort on it
PRO <br>
SPO OFF

SPO &&in_html_src_file. APP
-- Sort TABLE
PRO <script type="text/javascript" src="sorttable.js"></script>
SPO OFF

UNDEF in_html_src_file

DEF moat369_tf_usage = 'N'
--
