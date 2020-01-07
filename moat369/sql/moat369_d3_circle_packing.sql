-- add seq to one_spool_filename
DEF one_spool_filename = '&&spool_filename.'
@@&&fc_seq_output_file. one_spool_filename
@@&&fc_def_output_file. one_spool_fullpath_filename '&&one_spool_filename._circle_packing.html'

@@moat369_0j_html_topic_intro.sql &&one_spool_filename._circle_packing.html circle

SPO &&one_spool_fullpath_filename. APP
PRO <script type="text/javascript" src="d3.min.js"></script>

PRO <style>
PRO 
PRO .node {
PRO   cursor: pointer;;
PRO }
PRO 
PRO .node:hover {
PRO   stroke: #000;;
PRO   stroke-width: 1.5px;;
PRO }
PRO 
PRO .node--leaf {
PRO   fill: white;;
PRO }
PRO 
PRO .label {
PRO   font: 11px "Helvetica Neue", Helvetica, Arial, sans-serif;;
PRO   text-anchor: middle;;
PRO   text-shadow: 0 1px 0 #fff, 1px 0 0 #fff, -1px 0 0 #fff, 0 -1px 0 #fff;;
PRO }
PRO 
PRO .label,
PRO .node--root,
PRO .node--leaf {
PRO   pointer-events: none;;
PRO }
PRO 
PRO </style>

PRO <svg id="chart_div" width="900" height="900"></svg>

-- chart header
PRO <script type="text/javascript" id="d3_script">
PRO var jsonText = '' +

-- Count lines returned by PL/SQL
VAR row_count NUMBER;
EXEC :row_count := -1;

-- :sql_text must be in the format and has the column names as below:
-- 1st - ID (PK of row)
-- 1st - PARENT_ID (PK of Parent Row)
-- 1st - DISPLAY_NAME (Display Name text)
-- 1st - VALUE (Value that will represent the circle size)

-- body
SET SERVEROUT ON;
SET SERVEROUT ON SIZE 1000000;
SET SERVEROUT ON SIZE UNL;
DECLARE
  cur SYS_REFCURSOR;
  l_name   VARCHAR2(1000);
  l_value  VARCHAR2(1000);
  l_lvl    NUMBER;
  l_nxtlvl NUMBER;
  l_leaf   NUMBER;
  l_sql_text   VARCHAR2(32767);
  v_print_line VARCHAR2(32767);
  FUNCTION QA (p_string IN VARCHAR2,
               p_delim in varchar2 default chr(10)) RETURN VARCHAR2 -- Convert output to javascript string concatenation pattern
  as
    i_prev_pos integer := 1;
    i_pos integer;
    i_max_pos integer := length(p_string) + 1;
    i_delim_length integer := length(p_delim);
    l_output VARCHAR2(32767);
    l_token VARCHAR2(32767);
  begin
    loop
      i_pos := instr(p_string, p_delim, i_prev_pos);
      if i_pos = 0 then
        i_pos := i_max_pos;
      end if;
      l_token := substr(p_string, i_prev_pos, i_pos - i_prev_pos);
      IF l_token IS NOT NULL THEN
        l_output := l_output || q'[']' || rpad(l_token,100, ' ')  || q'[' +]';
        if i_pos != i_max_pos THEN
          l_output := l_output || p_delim;
        end if;
      end if;
      exit when i_pos = i_max_pos;
      i_prev_pos := i_pos + i_delim_length;
    end loop;
    return l_output;
  END;
BEGIN
  --OPEN cur FOR :sql_text;
  l_sql_text := q'[
  SELECT display_name,
         value,
         lvl,
         lead(lvl) over (order by lin) next_level,
         leaf
  FROM (
    SELECT rownum lin,
           id,
           parent_id,
           display_name,
           value,
           level lvl,
           CONNECT_BY_ISLEAF AS leaf
    FROM   (]' || DBMS_LOB.SUBSTR(:sql_text) || q'[)
    START WITH parent_id IS NULL
    CONNECT BY parent_id = PRIOR id
    ORDER SIBLINGS BY id
  ) order by lin
  ]';
  -- l_sql_text := DBMS_LOB.SUBSTR(:sql_text); -- needed for 10g
  OPEN cur FOR l_sql_text; -- needed for 10g
  LOOP
    FETCH cur INTO l_name, l_value, l_lvl, l_nxtlvl, l_leaf;
    EXIT WHEN cur%NOTFOUND;
    IF l_leaf = 1 THEN
      v_print_line := RPAD(' ',(l_lvl-1),' ') || '{ "name": "' || l_name || '", "size": ' || l_value || ' }';
    ELSE
      v_print_line := RPAD(' ',(l_lvl-1),' ') || '{' || CHR(10);
      v_print_line := v_print_line || RPAD(' ',l_lvl,' ') || '"name": "' || l_name || '",' || CHR(10);
      v_print_line := v_print_line || RPAD(' ',l_lvl,' ') || '"children": [';
    END IF;
    IF l_lvl = l_nxtlvl THEN
      v_print_line := v_print_line || ',';
    ELSIF l_lvl > l_nxtlvl THEN
      v_print_line := v_print_line ||  CHR(10) || RPAD(' ',(l_lvl-1),' ') || RPAD(']}', (l_lvl-l_nxtlvl)*LENGTH(']}'), ']}') || ',';
    ELSIF l_nxtlvl is null THEN
      v_print_line := v_print_line ||  CHR(10) || RPAD(' ',(l_lvl-1),' ') || RPAD(']}', (l_lvl-1)*LENGTH(']}'), ']}');
    END IF;
    dbms_output.put_line(QA(v_print_line));
  END LOOP;
  :row_count := cur%ROWCOUNT;
  CLOSE cur;
  dbms_output.put_line(q'['';]');
END;
/
SET SERVEROUT OFF;

-- get sql_id
SELECT prev_sql_id moat369_prev_sql_id, TO_CHAR(prev_child_number) moat369_prev_child_number FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID');

-- Set row_num to row_count;
COL row_num NOPRI
select TRIM(:row_count) row_num from dual;
COL row_num PRI


-- footer
PRO var svg = d3.select("svg"),
PRO     margin = 20,
PRO     diameter = +svg.attr("width"),
PRO     g = svg.append("g").attr("transform", "translate(" + diameter / 2 + "," + diameter / 2 + ")");;
PRO 
PRO var color = d3.scaleLinear()
PRO     .domain([-1, 5])
PRO     .range(["hsl(152,80%,80%)", "hsl(228,30%,40%)"])
PRO     .interpolate(d3.interpolateHcl);;
PRO 
PRO var pack = d3.pack()
PRO     .size([diameter - margin, diameter - margin])
PRO     .padding(2);;
PRO 
PRO var root = JSON.parse(jsonText);;
PRO 
PRO root = d3.hierarchy(root)
PRO     .sum(function(d) { return d.size; })
PRO     .sort(function(a, b) { return b.value - a.value; });;
PRO 
PRO var focus = root,
PRO     nodes = pack(root).descendants(),
PRO     view;;
PRO 
PRO var circle = g.selectAll("circle")
PRO   .data(nodes)
PRO   .enter().append("circle")
PRO     .attr("class", function(d) { return d.parent ? d.children ? "node" : "node node--leaf" : "node node--root"; })
PRO     .style("fill", function(d) { return d.children ? color(d.depth) : null; })
PRO     .on("click", function(d) { if (focus !== d) zoom(d), d3.event.stopPropagation(); });;
PRO 
PRO var text = g.selectAll("text")
PRO   .data(nodes)
PRO   .enter().append("text")
PRO     .attr("class", "label")
PRO     .style("fill-opacity", function(d) { return d.parent === root ? 1 : 0; })
PRO     .style("display", function(d) { return d.parent === root ? "inline" : "none"; })
PRO     .text(function(d) { return d.data.name; });;
PRO 
PRO var node = g.selectAll("circle,text");;
PRO 
PRO svg
PRO     .style("background", color(-1))
PRO     .on("click", function() { zoom(root); });;
PRO 
PRO zoomTo([root.x, root.y, root.r * 2 + margin]);;
PRO 
PRO function zoom(d) {
PRO   var focus0 = focus; focus = d;;
PRO 
PRO   var transition = d3.transition()
PRO       .duration(d3.event.altKey ? 7500 : 750)
PRO       .tween("zoom", function(d) {
PRO         var i = d3.interpolateZoom(view, [focus.x, focus.y, focus.r * 2 + margin]);;
PRO         return function(t) { zoomTo(i(t)); };;
PRO       });;
PRO 
PRO   transition.selectAll("text")
PRO     .filter(function(d) { return d.parent === focus || this.style.display === "inline"; })
PRO       .style("fill-opacity", function(d) { return d.parent === focus ? 1 : 0; })
PRO       .on("start", function(d) { if (d.parent === focus) this.style.display = "inline"; })
PRO       .on("end", function(d) { if (d.parent !== focus) this.style.display = "none"; });;
PRO }
PRO 
PRO function zoomTo(v) {
PRO   var k = diameter / v[2]; view = v;;
PRO   node.attr("transform", function(d) { return "translate(" + (d.x - v[0]) * k + "," + (d.y - v[1]) * k + ")"; });;
PRO   circle.attr("r", function(d) { return d.r * k; });;
PRO }
PRO 
PRO </script>
PRO

-- footer
PRO <br />
PRO <font class="n">Notes:<br>1) Values are approximated<br>2) Left-click a circle to drill down the graph.</font>
PRO <font class="n"><br />3) &&foot.</font>
PRO
SPO OFF

@@moat369_0k_html_topic_end.sql &&one_spool_filename._circle_packing.html circle '' &&sql_show.

@@&&fc_encode_html. &&one_spool_fullpath_filename.

HOS zip -mj &&moat369_zip_filename. &&one_spool_fullpath_filename. >> &&moat369_log3.

DEF moat369_d3_usage = 'Y'

UNDEF one_spool_fullpath_filename