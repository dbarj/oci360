-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename._treemap_chart.html'

-- Define options
@@&&fc_def_empty_var. chart_option1
@@&&fc_def_empty_var. chart_option2
@@&&fc_def_empty_var. chart_option3
@@&&fc_def_empty_var. chart_option4
@@&&fc_def_empty_var. tremap_popup
@@&&fc_set_value_var_nvl. 'chart_option1' "&&chart_option1." "highlightOnMouseOver: true, maxDepth: 1, maxPostDepth: 2,"
@@&&fc_set_value_var_nvl. 'chart_option2' "&&chart_option2." "minHighlightColor: '#8c6bb1', midHighlightColor: '#8c6bb1', maxHighlightColor: '#8c6bb1',"
@@&&fc_set_value_var_nvl. 'chart_option3' "&&chart_option3." "minColor: '#009688', midColor: '#f7f7f7', maxColor: '#ee8100',"
@@&&fc_set_value_var_nvl. 'chart_option4' "&&chart_option4." "headerHeight: 15, showScale: true, height: 500, useWeightedAverageForAggregation: true, generateTooltip: showFullTooltip"
@@&&fc_set_value_var_nvl. 'tremap_popup'  "&&tremap_popup."  "''"

@@moat369_0j_html_topic_intro.sql &&one_spool_filename._treemap_chart.html treemap

SPO &&one_spool_fullpath_filename. APP
PRO <script type="text/javascript" src="&&moat369_sw_gchart_path."></script>

-- chart header
PRO    <script type="text/javascript" id="gchart_script">
PRO      google.charts.load('current', {'packages': ['treemap']});;
PRO      google.charts.setOnLoadCallback(drawChart);;
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
  l_child VARCHAR2(1000);
  l_parent VARCHAR2(1000);
  l_number VARCHAR2(1000);
  l_color VARCHAR2(1000);
  l_sql_text VARCHAR2(32767);
  v_print_line VARCHAR2(32767);
  v_cursor_id integer;
  v_col_cnt integer;
  v_columns dbms_sql.desc_tab;
BEGIN
  --OPEN cur FOR :sql_text;
  l_sql_text := DBMS_LOB.SUBSTR(:sql_text); -- needed for 10g
  -- Begin Print Column Alias
  v_cursor_id := dbms_sql.open_cursor;
  dbms_sql.parse(v_cursor_id, l_sql_text, dbms_sql.native);
  dbms_sql.describe_columns(v_cursor_id, v_col_cnt, v_columns);
  v_print_line := '[';
  for i in 1 .. v_columns.count
  loop
    v_print_line := v_print_line || '''' || v_columns(i).col_name || '''';
    if i < v_columns.count then
      v_print_line := v_print_line || ',';
    end if;
  end loop;
  v_print_line := v_print_line || ']';
  DBMS_OUTPUT.PUT_LINE(v_print_line);
  dbms_sql.close_cursor(v_cursor_id);
  -- End Print Column Alias
  OPEN cur FOR l_sql_text; -- needed for 10g
  LOOP
    IF v_columns.count = 3
    THEN
      FETCH cur INTO l_child, l_parent, l_number;
      EXIT WHEN cur%NOTFOUND;
      IF l_parent IS NULL THEN l_parent := 'null'; ELSE l_parent := ''''||l_parent||''''; END IF;
      DBMS_OUTPUT.PUT_LINE(',['''||l_child||''', '||l_parent||', '||l_number||']');
    ELSE
      FETCH cur INTO l_child, l_parent, l_number, l_color;
      EXIT WHEN cur%NOTFOUND;
      IF l_parent IS NULL THEN l_parent := 'null'; ELSE l_parent := ''''||l_parent||''''; END IF;
      IF l_color IS NULL THEN l_color := '0'; END IF;
      DBMS_OUTPUT.PUT_LINE(',['''||l_child||''', '||l_parent||', '||l_number||', '||l_color||']');
    END IF;
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

-- treemap chart footer
PRO        ]);;
PRO
PRO        var options = {
PRO                &&chart_option1.
PRO                &&chart_option2.
PRO                &&chart_option3.
PRO                &&chart_option4.       
PRO        };;
PRO
PRO        var chart = new google.visualization.TreeMap(document.getElementById('chart_div'));;
PRO        chart.draw(data, options);;
PRO
PRO        function showFullTooltip(row, size, value) {
PRO          return '<div style="background:#fd9; padding:10px; border-style:solid">' +
PRO                 '<span style="font-family:Courier"><b>' + data.getValue(row, 0) + '</b></span>' +
PRO                 &&tremap_popup. + '</div>';;
PRO        }
PRO      }
PRO
PRO    </script>
PRO
PRO    <div id="chart_div" class="google-chart" style="width: 900px; height: 500px;"></div>
PRO

-- footer
PRO <br />
PRO <font class="n">Notes:<br>1) Values are approximated<br>2) Left-click a node to move down the tree and right-click to move up.</font>
PRO <font class="n"><br />3) &&foot.</font>
PRO
SPO OFF

@@moat369_0k_html_topic_end.sql &&one_spool_filename._treemap_chart.html treemap '' &&sql_show.

@@&&fc_encode_html. &&one_spool_fullpath_filename.

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

UNDEF chart_option1 chart_option2 chart_option3 chart_option4
UNDEF tremap_popup

UNDEF one_spool_fullpath_filename