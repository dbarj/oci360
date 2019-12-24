-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename._bar_chart.html'

-- Define bar_height and set value if undef
@@&&fc_def_empty_var. bar_height
@@&&fc_set_value_var_nvl. 'bar_height' '&&bar_height.' '65%'

@@&&fc_def_empty_var. bar_minperc
@@&&fc_set_value_var_nvl. 'bar_minperc' '&&bar_minperc.' '5'

-- Define options
@@&&fc_def_empty_var. chart_option1
@@&&fc_def_empty_var. chart_option2
@@&&fc_def_empty_var. chart_option3
@@&&fc_def_empty_var. chart_option4
@@&&fc_def_empty_var. chart_option5
@@&&fc_def_empty_var. chart_option6
@@&&fc_def_empty_var. chart_option7
@@&&fc_def_empty_var. chart_option8

@@&&fc_set_value_var_nvl. 'chart_option1' "&&chart_option1." "chartArea:{left:90, top:90, width:'85%', height:'&&bar_height.'},"
@@&&fc_set_value_var_nvl. 'chart_option2' "&&chart_option2." "backgroundColor: {fill: 'white', stroke: '#336699', strokeWidth: 1},"
@@&&fc_set_value_var_nvl. 'chart_option3' "&&chart_option3." "title: '&&section_id..&&report_sequence.. &&title.&&title_suffix.',"
@@&&fc_set_value_var_nvl. 'chart_option4' "&&chart_option4." "titleTextStyle: {fontSize: 18, bold: false},"
@@&&fc_set_value_var_nvl. 'chart_option5' "&&chart_option5." "legend: {position: 'none'},"
@@&&fc_set_value_var_nvl. 'chart_option6' "&&chart_option6." "vAxis: {minValue: 0, title: '&&vaxis.', titleTextStyle: {fontSize: 16, bold: false}},"
@@&&fc_set_value_var_nvl. 'chart_option7' "&&chart_option7." "hAxis: {title: '&&haxis.', titleTextStyle: {fontSize: 16, bold: false}},"
@@&&fc_set_value_var_nvl. 'chart_option8' "&&chart_option8." "tooltip: {textStyle: {fontSize: 14}}"

@@moat369_0j_html_topic_intro.sql &&one_spool_filename._bar_chart.html bar

SPO &&one_spool_fullpath_filename. APP
PRO <script type="text/javascript" src="&&moat369_sw_gchart_path."></script>

-- chart header
PRO    <script type="text/javascript" id="gchart_script">
PRO      google.charts.load("current", {packages:["corechart"]});
PRO      google.charts.setOnLoadCallback(drawChart);
PRO      function drawChart() {
PRO        var data = google.visualization.arrayToDataTable([

-- Count lines returned by PL/SQL
VAR row_count NUMBER;
EXEC :row_count := -1;

-- body
SET SERVEROUT ON;
SET SERVEROUT ON SIZE 1000000;
SET SERVEROUT ON SIZE UNL;
DECLARE
  cur SYS_REFCURSOR;
  l_bar VARCHAR2(1000);
  l_value NUMBER;
  l_others NUMBER := 100;
  l_style VARCHAR2(1000);
  l_tooltip VARCHAR2(1000);
  l_sql_text VARCHAR2(32767);
BEGIN
  DBMS_OUTPUT.PUT_LINE('[''Bucket'', ''Number of Rows'', { role: ''style'' }, { role: ''tooltip'' }]');
  --OPEN cur FOR :sql_text;
  l_sql_text := DBMS_LOB.SUBSTR(:sql_text); -- needed for 10g
  OPEN cur FOR l_sql_text; -- needed for 10g
  LOOP
    FETCH cur INTO l_bar, l_value, l_style, l_tooltip;
    EXIT WHEN cur%NOTFOUND;
    IF l_value >= &&bar_minperc. THEN
      DBMS_OUTPUT.PUT_LINE(',['''||l_bar||''', '||l_value||', '''||l_style||''', '''||l_tooltip||''']');
      l_others := l_others - l_value;
    END IF;
  END LOOP;
  :row_count := cur%ROWCOUNT;
  CLOSE cur;
  l_bar := 'The rest ('||l_others||'%)';
  l_value := l_others;
  l_style := 'D3D3D3'; -- light gray
  l_tooltip := '('||l_others||'% of remaining data)';
  IF l_others > 0 AND &&bar_minperc. > 0 -- For non-percentage bar charts
  THEN
    DBMS_OUTPUT.PUT_LINE(',['''||l_bar||''', '||l_value||', '''||l_style||''', '''||l_tooltip||''']');
  END IF;
END;
/
SET SERVEROUT OFF;

-- get sql_id
SELECT prev_sql_id moat369_prev_sql_id, TO_CHAR(prev_child_number) moat369_prev_child_number FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID');

-- Set row_num to row_count;
COL row_num NOPRI
select TRIM(:row_count) row_num from dual;
COL row_num PRI

-- bar chart footer
PRO        ]);;
PRO        
PRO        var options = {
PRO                &&chart_option1.
PRO                &&chart_option2.
PRO                &&chart_option3.
PRO                &&chart_option4.
PRO                &&chart_option5.
PRO                &&chart_option6.
PRO                &&chart_option7.
PRO                &&chart_option8.
PRO        };;
PRO
PRO        var chart = new google.visualization.ColumnChart(document.getElementById('barchart'));;
PRO        chart.draw(data, options);;
PRO      }
PRO    </script>
PRO
PRO    <div id="barchart" class="google-chart"></div>
PRO

-- footer
PRO <br />
PRO <font class="n">Notes:<br>1) Values are approximated<br>2) Hovering on the bars show more info.</font>
PRO <font class="n"><br />3) &&foot.</font>
PRO
SPO OFF

@@moat369_0k_html_topic_end.sql &&one_spool_filename._bar_chart.html bar '' &&sql_show.

@@&&fc_encode_html. &&one_spool_fullpath_filename.

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

UNDEF chart_option1 chart_option2 chart_option3 chart_option4
UNDEF chart_option5 chart_option6 chart_option7 chart_option8

UNDEF bar_height bar_minperc

UNDEF one_spool_fullpath_filename