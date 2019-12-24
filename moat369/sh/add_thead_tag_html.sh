#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Oct/2018 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error

if [ $# -ne 1 ]
then
  echo "One argument is needed..."
  exit 1
fi

in_file=$1
out_file=$1.tmp

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=/usr/xpg4/bin/awk
  SEDCMD=/usr/xpg4/bin/sed
else
  AWKCMD=awk
  SEDCMD=sed
fi

test -f $in_file || exit 1

in_fst_tr_line=`$SEDCMD -ne '/<tr>/=' $in_file | $SEDCMD -n 1p`
in_sec_tr_line=`$SEDCMD -ne '/<\/tr>/=' $in_file | $SEDCMD -n 1p`
in_last_line=`cat $in_file | wc -l`

test -n "${in_fst_tr_line}" || exit 1
test -n "${in_sec_tr_line}" || exit 1
test -n "${in_last_line}"   || exit 1

$AWKCMD "NR >= 1 && NR < $in_fst_tr_line {print;}" $in_file > $out_file
echo '<thead>' >> $out_file
$AWKCMD "NR >= $in_fst_tr_line && NR <= $in_sec_tr_line {print;}" $in_file >> $out_file
echo '</thead>' >> $out_file
$AWKCMD "NR > $in_sec_tr_line && NR <= $in_last_line {print;}" $in_file >> $out_file
mv $out_file $in_file

exit 0
###