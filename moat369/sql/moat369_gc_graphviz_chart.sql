-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename._graph_chart.html'

@@moat369_0j_html_topic_intro.sql &&one_spool_filename._graph_chart.html graph

SPO &&one_spool_fullpath_filename. APP
PRO
PRO    <img id="graph_chart" style="width: 900px; height: 500px;">
PRO
-- chart header
PRO    <script type="text/javascript" id="gchart_script">
PRO    var dot = 'digraph dot { ' +

-- Count lines returned by PL/SQL
VAR row_count NUMBER;
EXEC :row_count := -1;

-- body
SET SERVEROUT ON;
DECLARE
  cur SYS_REFCURSOR;
  l_node1 VARCHAR2(32767);
  l_node2 VARCHAR2(32767);
  l_attr VARCHAR2(32767);
  l_text VARCHAR2(32767);
  l_sql_text VARCHAR2(32767);
BEGIN
  --OPEN cur FOR :sql_text;
  l_sql_text := DBMS_LOB.SUBSTR(:sql_text); -- needed for 10g
  OPEN cur FOR l_sql_text; -- needed for 10g
  LOOP
    FETCH cur INTO l_node1, l_node2, l_attr, l_text;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('''' || l_node1 || ' -> ' || l_node2 || ' ' || l_attr || ';'' +');
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

PRO    '}';
SET DEF OFF
PRO    src = "https://chart.googleapis.com/chart?cht=gv&chs=720x400&chl="+dot
SET DEF ON
PRO    document.getElementById("graph_chart").src=src
PRO    </script>

-- footer
PRO <br>
PRO<font class="n">Notes:<br>1) up to &&history_days. days of awr history were considered<br>2) ASH reports are based on number of samples</font>
PRO<font class="n"><br>3) &&foot.</font>
PRO
SPO OFF

@@moat369_0k_html_topic_end.sql &&one_spool_filename._graph_chart.html graph '' &&sql_show.

@@&&fc_encode_html. &&one_spool_fullpath_filename.

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

UNDEF one_spool_fullpath_filename