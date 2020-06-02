#!/bin/bash
#************************************************************************
#
#   oci_bucket_upload.sh - Upload the given file to OCI Bucket in GZIP
#   format.
#
#   Copyright 2018  Rodrigo Jorge <http://www.dbarj.com.br/>
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
# Created on: Aug/2018 by Rodrigo Jorge
# Version 1.01
#************************************************************************
set -eo pipefail

# Define paths for oci-cli and jq or put them on $PATH. Don't use relative PATHs in the variables below.
v_oci="oci"

if [ -z "${BASH_VERSION}" -o "${BASH}" = "/bin/sh" ]
then
  >&2 echo "Script must be executed in BASH shell."
  exit 1
fi

# Add any desired oci argument exporting OCI_CLI_ARGS. Keep default to avoid oci_cli_rc usage.
[ -n "${OCI_CLI_ARGS}" ] && v_oci_args="${OCI_CLI_ARGS}"
[ -z "${OCI_CLI_ARGS}" ] && v_oci_args="--cli-rc-file /dev/null"

# Don't change it.
v_min_ocicli="2.9.11"

# Timeout for OCI-CLI calls
v_oci_timeout=600 # Seconds

[[ "${TMPDIR}" == "" ]] && TMPDIR='/tmp/'
# Temporary Folder. Used to stage some repetitive jsons and save time. Empty to disable.
v_tmpfldr="$(mktemp -d -u -p ${TMPDIR}/.oci 2>&- || mktemp -d -u)"

# If DEBUG variable is undefined, change to 1.
[[ "${DEBUG}" == "" ]] && DEBUG=0
[ ! -z "${DEBUG##*[!0-9]*}" ] || DEBUG=0

# DEBUG - Will create a oci_json_export.log file with DEBUG info.
#  1 = Executed commands.
#  2 = + Commands Queue + Stop
#  9 = + Parallel Wait
# 10 = + Folder Lock/Unlock

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM

function echoError ()
{
  (>&2 echo "$1")
}

function exitError ()
{
   echoError "$1"
   exit 1
}

function echoDebug ()
{
  local v_msg="$1"
  local v_debug_lvl="$2"
  local v_filename="${v_this_script%.*}.log"
  [ -z "${v_debug_lvl}" ] && v_debug_lvl=1
  if [ $DEBUG -ge ${v_debug_lvl} ]
  then
    v_msg="$(date '+%Y%m%d%H%M%S'): $v_msg"
    [ -n "${v_exec_id}" ] && v_msg="$v_msg (${v_exec_id})"
    echo "$v_msg" >> "${v_filename}"
    [ -f "../${v_filename}" ] && echo "$v_msg" >> "../${v_filename}"
  fi
  return 0
}

v_this_script="$(basename -- "$0")"

v_bucket="$1"
v_file="$2"

if [ -z "$v_bucket" -o -z "$v_file" -o "$#" -ne 2 ]
then
  echoError "Usage: ${v_this_script} <bucket> <file>"
  echoError ""
  echoError "<bucket> - Target Bucket Name."
  echoError "<file>   - File to upload to bucket. If ZIP, file will be unzipped and single files will be uploaded."
  echoError ""
  echoError "PS: it is possible to export the following variables to change code behaviour:"
  echoError ""
  echoError "OCI_UP_INCLUDE   - Pattern of items to include."
  echoError "OCI_UP_EXCLUDE   - Pattern of items to exclude."
  echoError "OCI_UP_GZIP      - 1 or 0 (default), whether to GZIP files before uploading."
  echoError "OCI_CLEAN_BUCKET - 1 or 0 (default), whether to clean target bucket before uploading."
  echoError "OCI_CLI_ARGS     - All parameters provided will be appended to oci-cli call."
  echoError "                   Eg: export OCI_CLI_ARGS='--profile ACME'"
  exit 1
fi

[ ! -r "$v_file" ] && exitError "File \"$v_file\" not found readable."

[ "${OCI_UP_GZIP}" != "0" -a "${OCI_UP_GZIP}" != "1" ] && OCI_UP_GZIP=1

[ "${OCI_CLEAN_BUCKET}" != "0" -a "${OCI_CLEAN_BUCKET}" != "1" ] && OCI_CLEAN_BUCKET=0

if ! $(which ${v_oci} >&- 2>&-)
then
  echoError "Could not find oci-cli binary. Please adapt the path in the script if not in \$PATH."
  echoError "Download page: https://github.com/oracle/oci-cli"
  exit 1
fi

if ! $(which unzip >&- 2>&-)
then
  echoError "Could not find unzip binary. Please include it in \$PATH."
  echoError "Zip binary is required to put all output json files together."
  exit 1
fi

v_cur_ocicli=$(${v_oci} -v)

if [ "${v_min_ocicli}" != "`echo -e "${v_min_ocicli}\n${v_cur_ocicli}" | sort -V | head -n1`" ]
then
  echoError "Minimal oci version required is ${v_min_ocicli}. Found: ${v_cur_ocicli}"
  exit 1
fi

[ -z "${v_oci_args}" ] || v_oci="${v_oci} ${v_oci_args}"

v_test=$(${v_oci} iam region-subscription list 2>&1) && v_ret=$? || v_ret=$?
if [ $v_ret -ne 0 ]
then
  echoError "oci-cli not able to run \"${v_oci} iam region-subscription list\". Please check error:"
  echoError "$v_test"
  exit 1
fi

## Test if temp folder is writable
if [ -n "${v_tmpfldr}" ]
then
  mkdir -p "${v_tmpfldr}" 2>&- || true
else
  echoError "Temporary folder is DISABLED."
  exit 1
fi
if [ -n "${v_tmpfldr}" -a ! -w "${v_tmpfldr}" ]
then
  echoError "Temporary folder \"${v_tmpfldr}\" is NOT WRITABLE."
  exit 1
fi

echoDebug "Temporary folder is: ${v_tmpfldr}" 2

if ! $(which timeout >&- 2>&-)
then
  function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
fi

################################################
############### CUSTOM FUNCTIONS ###############
################################################

# Start code execution.
echoDebug "BEGIN"

echo "Checking if bucket is accessible."
v_test=$(${v_oci} os bucket get --bucket-name "${v_bucket}" 2>&1) && v_ret=$? || v_ret=$?
if [ $v_ret -ne 0 ]
then
  echoError "oci-cli not able to run \"${v_oci} os bucket get --bucket-name oci360_bucket\". Please check error:"
  echoError "$v_test"
  exit 1
fi

[ -n "$OCI_UP_INCLUDE" ] && v_oci_include="--include $OCI_UP_INCLUDE"
[ -n "$OCI_UP_EXCLUDE" ] && v_oci_exclude="--exclude $OCI_UP_EXCLUDE"

if [ $OCI_CLEAN_BUCKET -eq 1 ]
then
  echo "Removing everything from the Bucket."
  ${v_oci} os object bulk-delete --bucket-name "${v_bucket}" --force ${v_oci_include} ${v_oci_exclude}
fi

if [[ "$v_file" = *".zip" ]]
then
  echo "Uploading ZIP files.."
  l_items=$(unzip -Z -1 "$v_file")
  for v_item in ${l_items}
  do
    if [[ "$v_item" != *".gz" ]] && [ $OCI_UP_GZIP -eq 1 ]
    then
      echo "Unzipping and gziping \"$v_item\"."
      unzip -p "$v_file" "$v_item" | gzip > "${v_tmpfldr}/${v_item}.gz"
    else
      echo "Unzipping \"$v_item\"."
      unzip -d "${v_tmpfldr}" "$v_file" "$v_item"
    fi
  done
else
  if [[ "$v_file" != *".gz" ]] && [ $OCI_UP_GZIP -eq 1 ]
  then
    gzip -c "$v_file" > "${v_tmpfldr}/${v_file}.gz"
  else
    echo "Gziping \"$v_file\"."
    cp "$v_file" "${v_tmpfldr}"
  fi
fi
 
${v_oci} os object bulk-upload --bucket-name "${v_bucket}" --src-dir "${v_tmpfldr}" --overwrite ${v_oci_include} ${v_oci_exclude}

[ -n "${v_tmpfldr}" ] && rm -f "${v_tmpfldr}"/*
[ -n "${v_tmpfldr}" ] && rmdir "${v_tmpfldr}"

echoDebug "END"


exit ${v_ret}
###