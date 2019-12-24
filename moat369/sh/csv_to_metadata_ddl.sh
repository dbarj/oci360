#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error

if [ $# -ne 7 ]
then
  echo "Seven arguments are needed..."
  exit 1
fi

v_sep=$1
v_sourcecsv=$2
v_ignore_header=$3
v_field_type=$4
v_field_owner=$5
v_field_name=$6
v_targetzip=$7

v_meta_func="&&fc_gen_object_ddl."
v_ren_func="&&fc_ren_output_file."
v_to_html_func="&&fc_convert_txt_to_html."
v_enc_html_func="&&fc_encode_html."
###
v_var_output="out_filename"
v_stm_id="META_OBJCTS"

test -f $v_sourcecsv || exit 1

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=/usr/xpg4/bin/awk
else
  AWKCMD=awk
fi

v_firstline=true

while read -r line || [ -n "$line" ]
do
  v_type=$($AWKCMD '{n=split($0, array, "'$v_sep'")} END{print array['$v_field_type'] }' <<< "$line")
  v_owner=$($AWKCMD '{n=split($0, array, "'$v_sep'")} END{print array['$v_field_owner'] }' <<< "$line")
  v_name=$($AWKCMD '{n=split($0, array, "'$v_sep'")} END{print array['$v_field_name'] }' <<< "$line")
#  read v_type v_owner v_name <<< $(echo $line | $AWKCMD -F"${v_sep}" '{print $'$v_field_type', $'$v_field_owner', $'$v_field_name'}')

  if $v_firstline && $v_ignore_header
  then
    v_firstline=false
  else
    echo "@$v_meta_func \"${v_type// /_}\" \"${v_name}\" \"${v_owner}\" \"${v_var_output}\""
    echo "HOS zip -j ${v_targetzip} &&${v_var_output}. >> &&moat369_log3."
    echo "@$v_ren_func ${v_var_output}"
    echo "@$v_to_html_func ${v_var_output}"
    echo "@$v_enc_html_func &&${v_var_output}."
    echo "insert into plan_table (STATEMENT_ID, OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE, REMARKS)"
    echo "values ('${v_stm_id}','${v_owner}','${v_name}','${v_type}','&&${v_var_output}.');"
    echo "HOS zip -mj &&moat369_zip_filename. &&${v_var_output}. >> &&moat369_log3."
    echo "UNDEF ${v_var_output}"
  fi
done < ${v_sourcecsv}

exit 0
####