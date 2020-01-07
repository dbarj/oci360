#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Mar/2017 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error

if [ $# -ne 1 ]
then
  echo "One argument is needed..."
  exit 1
fi

in_file=$1
out_file=$1.html

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  SEDCMD=/usr/xpg4/bin/sed
else
  SEDCMD=sed
fi

test -f $in_file || exit 1

touch $out_file

echo '<html><head></head><body>'                                                       >  $out_file
echo '<!--BEGIN_SENSITIVE_DATA-->'                                                     >> $out_file
echo '<pre style="word-wrap: break-word; white-space: pre-wrap;">'                     >> $out_file
cat $in_file | $SEDCMD 's|\&|\&amp;|g' | $SEDCMD 's|>|\&gt;|g' | $SEDCMD 's|<|\&lt;|g' >> $out_file
echo '</pre>'                                                                          >> $out_file
echo '<!--END_SENSITIVE_DATA-->'                                                       >> $out_file
echo '</body></html>'                                                                  >> $out_file

test -f $out_file || exit 1

rm -f $in_file

exit 0
###