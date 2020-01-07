#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: May/2017 by Rodrigo Jorge
# ----------------------------------------------------------------------------
if [ $# -ne 2 ]
then
  echo "Two arguments are needed..."
  exit 1
fi

v_sep=$1
v_sourcecsv=$2

test -f $v_sourcecsv || exit 1

v_fl_col_tag_o="'"
v_fl_col_tag_c="'"
v_al_col_tag_o=""
v_al_col_tag_c=""
v_col_sep=","
v_line_o="["
v_line_c="]"
v_line_sep=","

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=/usr/xpg4/bin/awk
  SEDCMD=/usr/xpg4/bin/sed
  # echo -e "xxx" in solaris prints "-e xxx" when using /bin/sh.
  ECHO_E="echo"
else
  AWKCMD=awk
  SEDCMD=sed
  ECHO_E="echo -e"
fi

v_firstline=true

v_head_ncols=$(head -n 1 $v_sourcecsv | $AWKCMD '{n=split($0, array, "'$v_sep'")} END{print n }')

v_tot=$(cat $v_sourcecsv | wc -l | $AWKCMD '{print $1}')

v_count=0

while read -r line || [ -n "$line" ]
do
  v_ncols=$($AWKCMD '{n=split($0, array, "'$v_sep'")} END{print n }' <<< "$line")
  if [ $v_head_ncols -ne $v_ncols ]
  then
    echo ERROR
    break
  fi
  $ECHO_E $v_line_o\\c
  if $v_firstline
  then
    v_linerep=$($SEDCMD "s|$v_sep|${v_fl_col_tag_c}${v_col_sep}${v_fl_col_tag_o}|g" <<< "$line")
    $ECHO_E ${v_fl_col_tag_o}${v_linerep}${v_fl_col_tag_c}\\c
    v_firstline=false
  else
    v_linerep=$($SEDCMD "s|$v_sep|${v_al_col_tag_c}${v_col_sep}${v_al_col_tag_o}|g" <<< "$line")
    $ECHO_E ${v_al_col_tag_o}${v_linerep}${v_al_col_tag_c}\\c
  fi
  $ECHO_E $v_line_c\\c
  v_count=$((v_count+1))
  [ $v_count -eq $v_tot ] && echo "" || echo ${v_line_sep}
done < ${v_sourcecsv}

exit 0
####