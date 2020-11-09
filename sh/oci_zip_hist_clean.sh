#!/bin/bash
#************************************************************************
#
#   oci_zip_hist_clean.sh - Clean history zip files used to store
#   OCI json/csv historical archives.
#
#   Copyright 2019  Rodrigo Jorge <http://www.dbarj.com.br/>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#************************************************************************
# Available at: https://github.com/dbarj/oci-scripts
# Created on: May/2019 by Rodrigo Jorge
# Version 1.02
#************************************************************************
set -eo pipefail

if [ -z "${BASH_VERSION}" -o "${BASH}" = "/bin/sh" ]
then
  >&2 echo "Script must be executed in BASH shell."
  exit 1
fi

function echoError ()
{
   (>&2 echo "$1")
}

function exitError ()
{
   echoError "$1"
   exit 1
}

[[ "${HIST_CLEAN}" == "" ]]   && HIST_CLEAN=1
[[ "${HIST_REORDER}" == "" ]] && HIST_REORDER=0

[ "${HIST_CLEAN}" == "0" -a "${HIST_REORDER}" == "0" ] && { echo "Nothing to do."; exit 0; }

v_this_script="$(basename -- "$0")"

if [ "$#" -ne 3 -o "$1" == "" -o "$2" == "" -o "$3" == "" ]
then
  echoError "Usage: ${v_this_script} <zip_file> <list_file> <retention>"
  echoError ""
  echoError "<zip_file>  - Zip file containing historical files (JSON or CSV)."
  echoError "<list_file> - Text file inside ZIP file that has all the files entries."
  echoError "<retention> - Retention time in days to keep files."
  exit 1
fi

v_zip="$1"
v_list="$2"
v_retention="$3"

if [ ! -f "${v_zip}" ]
then
  exitError "Invalid zip file."
fi

re='^[0-9]+$'
if ! [[ $v_retention =~ $re ]]
then
   exitError "<retention> is not a number."
fi

[ $v_retention -gt 0 ] || { echo "Nothing to do."; exit 0; }

function cleanTmpFiles ()
{
  ##########
  # Clean folder where current execution temporary files are placed.
  ##########

  [ -n "${v_tmpfldr}" ] && rm -rf "${v_tmpfldr}" 2>&- || true
  return 0
}

trap "trap - SIGTERM && cleanTmpFiles && kill -- -$$" SIGINT SIGTERM ERR

v_tmpfldr="$(mktemp -d -u -p /tmp/.oci 2>&- || mktemp -d -u)"

## Test if temp folder is writable
if [ -n "${v_tmpfldr}" ]
then
  mkdir -p "${v_tmpfldr}" 2>&- || true
else
  exitError "Temporary folder could not be created."
fi
if [ -n "${v_tmpfldr}" -a ! -w "${v_tmpfldr}" ]
then
  exitError "Temporary folder \"${v_tmpfldr}\" is NOT WRITABLE."
fi

v_zip_fdr="$(cd "$(dirname "${v_zip}")"; pwd)"
v_zip_file="$(basename "${v_zip}")"

v_zip_new="${v_zip_file}.new"
v_list_new="${v_list}.new"

v_now_epoch=$(date -u '+%s')

unzip -q -d "${v_tmpfldr}" "${v_zip}"

cd "${v_tmpfldr}"

if [ ! -f "${v_list}" ]
then
  rm -rf "${v_tmpfldr}"
  exitError "Invalid List file."
fi

function ConvYMDToEpoch ()
{
  local v_in_date
  v_in_date="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%s' -d ${v_in_date});;
      Darwin*)    echo $(date -j -u -f '%Y-%m-%d %T' "${v_in_date} 00:00:00" +"%s");;
      *)          echo
  esac  
}

function removeFromZip ()
{
  [ -f "$1" ] && rm -f "$1"
  sed -i "/|$1\$/d" "${v_list_new}"
  return 0
}

function progressbar ()
{
 local str="#"
 local maxhashes=24
 local perc=$1
 local numhashes=$(( ( $perc * $maxhashes ) / 100 ))
 local numspaces=$(( $maxhashes - $numhashes ))
 local phash=$(printf "%-${numhashes}s" "$str")
 [ $numhashes -eq 0 ] && phash="" || true
 local pspace=$(printf "%-${numspaces}s" " ")
 [ $numspaces -eq 0 ] && pspace="" || true
 echo -ne "${phash// /$str}${pspace}   (${perc}%)\r"
 [ $perc -eq 100 ] && echo -ne "${phash//$str/ }         \r" || true
}

function printpercentage ()
{
 local perc=$(( ( $curline * 100 ) / $totline ))
 [ $perc -ne $perc_b4 ] && progressbar $perc || true
 perc_b4=$perc
 ((curline++))
}

curline=1
totline=$(cat "${v_list}" | wc -l )
perc_b4=-1

if [ "${HIST_CLEAN}" == "1" ]
then
  cp "${v_list}" "${v_list_new}"
  echo "Cleaning Zip."
  while read -u 3 -r c_line || [ -n "$c_line" ]
  do
    #echo "$c_line"
    c_cmd=$(cut -d '|' -f 1 <<< "$c_line")
    c_file=$(cut -d '|' -f 2 <<< "$c_line")
    if [ ! -f "${c_file}" ]
    then
      removeFromZip "${c_file}"
      continue
    fi
    c_dates=$(grep -o -E '[0-9]{4}-[0-9]{2}-[0-9]{2}' <<< "${c_cmd}") || true
    if [ $(wc -l <<< "${c_dates}") -eq 2 ]
    then
      c_date1=$(head -n 1 <<< "${c_dates}")
      c_date2=$(tail -n 1 <<< "${c_dates}")
      c_date1_epoch=$(ConvYMDToEpoch "${c_date1}")
      c_date2_epoch=$(ConvYMDToEpoch "${c_date2}")
      if [ $((v_now_epoch-c_date1_epoch)) -ge $((3600*24*${v_retention})) -a $((v_now_epoch-c_date2_epoch)) -ge $((3600*24*${v_retention})) ]
      then
        # echo "${c_date1} ${c_date2} - Removing ${c_file}"
        removeFromZip "${c_file}"
      fi
    elif [ $(wc -l <<< "${c_dates}") -eq 1 ]
    then
      c_date_epoch=$(ConvYMDToEpoch "${c_dates}")
      if [ $((v_now_epoch-c_date_epoch)) -ge $((3600*24*${v_retention})) ]
      then
        # echo "${c_dates} - Removing ${c_file}"
        removeFromZip "${c_file}"
      fi
    elif [ $(wc -l <<< "${c_dates}") -eq 0 ]
    then
      v_file_epoch=$(date -r "${c_file}" -u '+%s')
      if [ $((v_now_epoch-v_file_epoch)) -ge $((3600*24*${v_retention})) ]
      then
        # echo "$v_file_epoch - Removing ${c_file}"
        removeFromZip "${c_file}"
      fi
    fi
    printpercentage
  done 3< "${v_list}"
  
  [ -f "${v_list_new}" ] && mv "${v_list_new}" "${v_list}"
fi

if [ "${HIST_REORDER}" == "1" ]
then
  echo "Reordering Zip."
  mkdir outfdr
  v_seq=1

  curline=1
  totline=$(cat "${v_list}" | wc -l )
  perc_b4=-1

  while read -u 3 -r c_line || [ -n "$c_line" ]
  do
    c_cmd=$(cut -d '|' -f 1 <<< "$c_line")
    c_file=$(cut -d '|' -f 2 <<< "$c_line")
    [ ! -f "${c_file}" ] && continue
    c_ext="${c_file#*.}"
    [ -n "${c_ext}" ] && c_out="${v_seq}.${c_ext}" || c_out="${v_seq}"
    mv "${c_file}" outfdr/${c_out}
    echo "${c_cmd}|${c_out}" >> outfdr/"${v_list}"
    ((v_seq++))
    printpercentage
  done 3< "${v_list}"

  cd outfdr
  zip -qmT -9 "${v_zip_fdr}/${v_zip_new}" *
  cd ..
  rmdir outfdr
else
  zip -qmT -9 "${v_zip_fdr}/${v_zip_new}" *
fi

cleanTmpFiles

cd "${v_zip_fdr}"
mv "${v_zip_new}" "${v_zip_file}"

exit 0
###