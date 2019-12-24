#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
if [ $# -ne 3 ]
then
  echo "Three arguments are needed..."
  exit 1
fi

v_sep="$1"
v_sourcecsv="$2"
v_out_html="$3"

v_awk_func_dir="./moat369/sh/csv-parser.awk"

test -f "${v_sourcecsv}" || exit 1

echo "<p>" >> "${v_out_html}"
echo '<table id="maintable">' >> "${v_out_html}"

v_fcol_tag_o='<th scope="col">'
v_fcol_tag_c="</th>"
v_acol_tag_o="<td>"
v_acol_tag_c="</td>"
f_line_o="<tr>"
f_line_c="</tr>"

AWKCMD_P="-f ${v_awk_func_dir} -v separator=${v_sep} -v enclosure=\""

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=gawk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  SEDCMD=/usr/xpg4/bin/sed
  # echo -e "xxx" in solaris prints "-e xxx" when using /bin/sh.
  ECHO_E="echo"
else
  AWKCMD=awk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  SEDCMD=sed
  ECHO_E="echo -e"
fi

v_firstline=true

v_head_ncols=$(head -n 1 "${v_sourcecsv}" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}')

v_count=0

remove_html_tags()
{
  echo "$1" | $SEDCMD 's|&|&amp;|g' | $SEDCMD 's|>|\&gt;|g' | $SEDCMD 's|<|\&lt;|g'
} 

while read -r line || [ -n "$line" ]
do
  v_ncols=$(${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}' <<< "$line")
  if [ $v_head_ncols -ne $v_ncols ]
  then
    echo ERROR >> "${v_out_html}"
    break
  fi
  $ECHO_E "$f_line_o\\c" >> "${v_out_html}"
  if $v_firstline
  then
    v_linerep=$(remove_html_tags "$line" | ${AWKCMD_CSV} -v outsep="${v_fcol_tag_c}${v_fcol_tag_o}" --source '{csv_parse_and_display($0, separator, enclosure, outsep)}')
    $ECHO_E "${v_fcol_tag_o}#${v_fcol_tag_c}${v_fcol_tag_o}${v_linerep}${v_fcol_tag_c}\\c" >> "${v_out_html}"
    v_firstline=false
  else
    v_linerep=$(remove_html_tags "$line" | ${AWKCMD_CSV} -v outsep="${v_acol_tag_c}${v_acol_tag_o}" --source '{csv_parse_and_display($0, separator, enclosure, outsep)}')
    $ECHO_E "${v_acol_tag_o}${v_count}${v_acol_tag_c}${v_acol_tag_o}${v_linerep}${v_acol_tag_c}\\c" >> "${v_out_html}"
  fi
  echo "$f_line_c" >> "${v_out_html}"
  v_count=$((v_count+1))
done < "${v_sourcecsv}"

echo "</table>" >> "${v_out_html}"
echo "<p>" >> "${v_out_html}"

exit 0
####