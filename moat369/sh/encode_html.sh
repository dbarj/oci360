#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Jun/2018 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error

# 1 = Input file with BEGIN_SENSITIVE_DATA and END_SENSITIVE_DATA tags. Output file will be the same, replaced.
# 2 = Encoded HTML template.
# 3 = Key File used OpenSSL for encryption.
# 4 = Enable Encryption? ON or OFF
# 5 = Enable Comprssion? ON or OFF

if [ $# -ne 5 ]
then
  echo "Five arguments are needed..."
  exit 1
fi

in_file=$1
enc_file=$2
x_file=$3
flag_encr=$4
flag_comp=$5
out_tmp_file=$1.tmp

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=/usr/xpg4/bin/awk
  SEDCMD=/usr/xpg4/bin/sed
else
  AWKCMD=awk
  SEDCMD=sed
fi

[ "$flag_encr" == "ON" -o "$flag_encr" == "OFF" ] || exit 1
[ "$flag_comp" == "ON" -o "$flag_comp" == "OFF" ] || exit 1

# Nothing to do here.
[ "$flag_encr" == "ON" -o "$flag_comp" == "ON" ] || exit 0


test -f $in_file || exit 1
test -f $enc_file || exit 1

if [ "$flag_encr" == "ON" ]
then
  which openssl > /dev/null 2>&- || exit 1
  [ -f $x_file ] || exit 1
fi
if [ "$flag_comp" == "ON" ]
then
  which gzip > /dev/null 2>&- || exit 1
  which base64 > /dev/null 2>&- || exit 1
fi

in_start_line=`$SEDCMD -ne /\<!--BEGIN_SENSITIVE_DATA--\>/= $in_file`
in_stop_line=`$SEDCMD -ne /\<!--END_SENSITIVE_DATA--\>/= $in_file`
in_last_line=`cat $in_file | wc -l`
enc_vars_line=`$SEDCMD -ne /encoded_vars/= $enc_file`
enc_hash_line=`$SEDCMD -ne /encoded_data/= $enc_file`
enc_last_line=`cat $enc_file | wc -l`

test -n "${in_start_line}" || exit 1
test -n "${in_stop_line}"  || exit 1
test -n "${in_last_line}"  || exit 1
test -n "${enc_vars_line}" || exit 1
test -n "${enc_hash_line}" || exit 1
test -n "${enc_last_line}" || exit 1

$AWKCMD "NR >= 1 && NR < $in_start_line {print;}" $in_file > $out_tmp_file
$AWKCMD "NR >= 1 && NR < $enc_vars_line {print;}" $enc_file >> $out_tmp_file
[ "$flag_encr" == "ON" ] && echo "var enctext_encr = true" >> $out_tmp_file || echo "var enctext_encr = false" >> $out_tmp_file
[ "$flag_comp" == "ON" ] && echo "var enctext_comp = true" >> $out_tmp_file || echo "var enctext_comp = false" >> $out_tmp_file
$AWKCMD "NR > $enc_vars_line && NR < $enc_hash_line {print;}" $enc_file >> $out_tmp_file
###
if [ "$flag_encr" == "ON" -a "$flag_comp" == "ON" ]
then
  $AWKCMD "NR > $in_start_line && NR < $in_stop_line {print;}" $in_file | gzip -cf | base64 | openssl enc -aes256 -a -salt -pass file:$x_file | $SEDCMD "s/^/'/" | $SEDCMD "s/$/'/" | $SEDCMD -e 's/$/ +/' -e '$s/ +$//' >> $out_tmp_file
elif [ "$flag_encr" == "ON" -a "$flag_comp" == "OFF" ]
then
  $AWKCMD "NR > $in_start_line && NR < $in_stop_line {print;}" $in_file | openssl enc -aes256 -a -salt -pass file:$x_file | $SEDCMD "s/^/'/" | $SEDCMD "s/$/'/" | $SEDCMD -e 's/$/ +/' -e '$s/ +$//' >> $out_tmp_file
elif [ "$flag_encr" == "OFF" -a "$flag_comp" == "ON" ]
then
  $AWKCMD "NR > $in_start_line && NR < $in_stop_line {print;}" $in_file | gzip -cf | base64 | $SEDCMD "s/^/'/" | $SEDCMD "s/$/'/" | $SEDCMD -e 's/$/ +/' -e '$s/ +$//' >> $out_tmp_file
fi
###
$AWKCMD "NR > $enc_hash_line && NR <= $enc_last_line {print;}" $enc_file >> $out_tmp_file
$AWKCMD "NR > $in_stop_line && NR <= $in_last_line {print;}" $in_file >> $out_tmp_file
mv $out_tmp_file $in_file

exit 0
###