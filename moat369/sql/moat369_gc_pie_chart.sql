-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename._pie_chart.html'

@@moat369_0j_html_topic_intro.sql &&one_spool_filename._pie_chart.html pie

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
DECLARE
  cur SYS_REFCURSOR;
  l_slice VARCHAR2(32767);
  l_value NUMBER;
  l_display_value VARCHAR2(32767);
  l_sql_text VARCHAR2(32767);
BEGIN
  DBMS_OUTPUT.PUT_LINE('[''Slice'', ''Value'']');
  --OPEN cur FOR :sql_text;
  l_sql_text := DBMS_LOB.SUBSTR(:sql_text); -- needed for 10g
  OPEN cur FOR l_sql_text; -- needed for 10g
  LOOP
    FETCH cur INTO l_slice, l_value, l_display_value;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(',['''||l_slice||''', {v: '||l_value||', f: '''||l_display_value||'''}]');
  END LOOP;
  :row_count := cur%ROWCOUNT;
  CLOSE cur;
END;
/
SET SERVEROUT OFF;

-- get sql_id
SELECT prev_sql_id moat369_prev_sql_id, TO_CHAR(prev_child_number) moat369_prev_child_number FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID');

-- Set row_num to row_count;
COL row_num NOPRI
select TRIM(:row_count) row_num from dual;
COL row_num PRI

-- chart footer
PRO        ]);;
PRO        
PRO        var options = {
PRO          is3D: true,
PRO          backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1},
PRO          title: '&&title.&&title_suffix.',
PRO          titleTextStyle: {fontSize: 16, bold: false},
PRO          legend: {position: 'right', textStyle: {fontSize: 12}},
PRO          tooltip: {textStyle: {fontSize: 14}},
PRO          sliceVisibilityThreshold: 1/10000,
PRO          pieSliceText: 'percentage',
PRO          tooltip: {
PRO                    showColorCode: true,
PRO                    text: 'both',
PRO                    trigger: 'focus'
PRO                  }
PRO          };
PRO
PRO        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d'));
PRO        chart.draw(data, options);
PRO      }
PRO    </script>
PRO
PRO    <div id="piechart_3d" class="google-chart"></div>
PRO

-- footer
PRO<font class="n">Notes:<br>&&foot.</font>
PRO
SPO OFF

@@moat369_0k_html_topic_end.sql &&one_spool_filename._pie_chart.html pie '' &&sql_show.

@@&&fc_encode_html. &&one_spool_fullpath_filename.

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

UNDEF one_spool_fullpath_filename
