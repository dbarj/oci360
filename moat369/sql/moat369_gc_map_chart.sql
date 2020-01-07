-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename._map_chart.html'

@@moat369_0j_html_topic_intro.sql &&one_spool_filename._map_chart.html map

SPO &&one_spool_fullpath_filename. APP
PRO <link rel="stylesheet" href="https://unpkg.com/leaflet@1.4.0/dist/leaflet.css"
PRO   integrity="sha512-puBpdR0798OZvTTbP4A8Ix/l+A4dHDD0DGqYW6RQ+9jxkRFclaxxQb/SJAWZfWAkuyeQUytO7+7N4QKrDh+drA=="
PRO   crossorigin=""/>
PRO <script src="https://unpkg.com/leaflet@1.4.0/dist/leaflet.js"
PRO   integrity="sha512-QVftwZFqvtRNi0ZyCtsznlKSWOStnDORoefr1enyq5mVL4tmKB3S/EnC3rRJcxCPavG10IcrVGSmPh6Qw5lwrg=="
PRO   crossorigin=""></script>
PRO <script type="text/javascript" src="http://maps.stamen.com/js/tile.stamen.js?v1.3.0"></script>

-- chart header
PRO    <div id="chart_div" class="google-chart"></div>
PRO    <script type="text/javascript" id="gchart_script">
PRO      var mymap = L.map('chart_div').setView([0, 0], 2);;
PRO      var layer = new L.StamenTileLayer("terrain");;
PRO      mymap.addLayer(layer);;
PRO      var arrayOfLatLngs = [];;

-- Count lines returned by PL/SQL
VAR row_count NUMBER;
EXEC :row_count := -1;

-- body
SET SERVEROUT ON;
SET SERVEROUT ON SIZE 1000000;
SET SERVEROUT ON SIZE UNL;
DECLARE
  cur SYS_REFCURSOR;
  l_name VARCHAR2(1000);
  l_lat VARCHAR2(1000);
  l_long VARCHAR2(1000);
  l_sql_text VARCHAR2(32767);
  l_i number := 1;
BEGIN
  --OPEN cur FOR :sql_text;
  l_sql_text := DBMS_LOB.SUBSTR(:sql_text); -- needed for 10g
  OPEN cur FOR l_sql_text; -- needed for 10g
  LOOP
    FETCH cur INTO l_name, l_lat, l_long;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('var c_'||l_i||' = ['||l_lat||', '||l_long||'];');
    DBMS_OUTPUT.PUT_LINE('arrayOfLatLngs.push([c_'||l_i||']);');
    DBMS_OUTPUT.PUT_LINE('var v_'||l_i||' = L.marker(c_'||l_i||').addTo(mymap);');
    DBMS_OUTPUT.PUT_LINE('v_'||l_i||'.bindPopup("<b>'||l_name||'</b>", {closeOnClick: false, autoClose: false}).openPopup();');
    l_i := l_i + 1;
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

-- map chart footer
PRO      var bounds = new L.LatLngBounds(arrayOfLatLngs).pad(0.5);;
PRO      mymap.fitBounds(bounds);;
PRO    </script>

-- footer
PRO <br />
PRO <font class="n">Notes:<br>1) Locations are approximated<br></font>
PRO <font class="n">2) &&foot.</font>
PRO
SPO OFF

@@moat369_0k_html_topic_end.sql &&one_spool_filename._map_chart.html map '' &&sql_show.

@@&&fc_encode_html. &&one_spool_fullpath_filename.

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

UNDEF one_spool_fullpath_filename