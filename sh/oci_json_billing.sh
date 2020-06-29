#!/bin/bash
#************************************************************************
#
#   oci_json_billing.sh - Export all Oracle Cloud Billing
#   information from OCI into JSON files.
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
# Version 1.10
#************************************************************************
set -eo pipefail

# Define paths for oci-cli and jq or put them on $PATH. Don't use relative PATHs in the variables below.
v_curl="curl"
v_jq="jq"

if [ -z "${BASH_VERSION}" -o "${BASH}" = "/bin/sh" ]
then
  >&2 echo "Script must be executed in BASH shell."
  exit 1
fi

# Timeout for CURL calls
v_curl_timeout=600 # Seconds

# Default period in days to collect info, if omitted on parameters
v_def_period=90

[[ "${TMPDIR}" == "" ]] && TMPDIR='/tmp/'
# Temporary Folder. Used to stage some repetitive jsons and save time. Empty to disable (not recommended).
v_tmpfldr="$(mktemp -d -u -p ${TMPDIR}/.oci 2>&- || mktemp -d -u)"

# Export DEBUG=1 to see the steps being executed.
[[ "${DEBUG}" == "" ]] && DEBUG=0

# If Shell is executed with "-x", all core functions will set this flag 
printf %s\\n "$-" | grep -q -F 'x' && v_dbgflag='-x' || v_dbgflag='+x'

# Export HIST_ZIP_FILE with the file name where will keep or read for historical info to avoid reprocessing.
[[ "${HIST_ZIP_FILE}" == "" ]] && HIST_ZIP_FILE=""

v_hist_folder="billing_history"

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
   local v_filename="${v_this_script%.*}.log"
   (( $DEBUG )) && echo "$(date '+%Y%m%d%H%M%S'): $1" >> ${v_filename}
   return 0
}

function funcCheckValueInRange ()
{
  [ "$#" -ne 2 -o -z "$1" -o -z "$2" ] && return 1
  local v_arg1 v_arg2 v_array v_opt
  v_arg1="$1" # Value
  v_arg2="$2" # Range
  v_array=$(tr "," "\n" <<< "${v_arg2}")
  for v_opt in $v_array
  do
    if [ "$v_opt" == "${v_arg1}" ]
    then
      echo "Y"
      return 0
    fi
  done
  echo "N"
}

function funcPrintRange ()
{
  [ "$#" -ne 1 -o -z "$1" ] && return 1
  local v_arg1 v_opt v_array
  v_arg1="$1" # Range
  v_array=$(tr "," "\n" <<< "${v_arg1}")
  for v_opt in $v_array
  do
    echo "- ${v_opt}"
  done
}

v_this_script="$(basename -- "$0")"

if [ -z "${CLIENT_ID}" -a  -z "${CLIENT_USER}" ]
then
  echoError "To run this tool, you must export: "
  echoError "- CLIENT_USER, CLIENT_PASS, CLIENT_DOMAIN"
  echoError "  OR"
  echoError "- CLIENT_ID, CLIENT_SECRET, CLIENT_DOMAIN"
  exit 1
fi

if [ -z "${CLIENT_USER}" ]
then
  v_conn_type='CLIENT'
else
  v_conn_type='USER'
fi

[ "${v_conn_type}" == 'CLIENT' -a -z "${CLIENT_ID}" ]     && exitError "You must export variable CLIENT_ID before calling this tool."
[ "${v_conn_type}" == 'CLIENT' -a -z "${CLIENT_SECRET}" ] && exitError "You must export variable CLIENT_SECRET before calling this tool."
[ "${v_conn_type}" == 'USER' -a -z "${CLIENT_USER}" ]     && exitError "You must export variable CLIENT_USER before calling this tool."
[ "${v_conn_type}" == 'USER' -a -z "${CLIENT_PASS}" ]     && exitError "You must export variable CLIENT_PASS before calling this tool."
[ -z "${CLIENT_DOMAIN}" ] && exitError "You must export variable CLIENT_DOMAIN before calling this tool."

v_func_list=$(sed -e '1,/^# BEGIN DYNFUNC/d' -e '/^# END DYNFUNC/,$d' -e 's/^# *//' $0)
v_opt_list=$(echo "${v_func_list}" | cut -d ',' -f 1 | sort | tr "\n" ",")
v_valid_opts="ALL"
v_valid_opts="${v_valid_opts},${v_opt_list}"

v_param1="$1"
v_param2="$2"
v_param3="$3"

v_check=$(funcCheckValueInRange "$v_param1" "$v_valid_opts") && v_ret=$? || v_ret=$?

if [ "$v_check" == "N" -o $v_ret -ne 0 ]
then
  echoError "Usage: ${v_this_script} <option> [begin_time] [end_time]"
  echoError ""
  echoError "<option> - Execution Scope."
  echoError "[begin_time] (Optional) - Defines start time when exporting billing info. (Default is $v_def_period days back) "
  echoError "[end_time]   (Optional) - Defines end time when exporting billing info. (Default is today)"
  echoError ""
  echoError "Valid <option> values are:"
  echoError "- ALL         - Execute json export for ALL possible options and compress output in a zip file."
  echoError "$(funcPrintRange "$v_opt_list")"
  exit 1
fi

if ! $(which ${v_curl} >&- 2>&-)
then
  echoError "Could not find curl binary. Please adapt the path in the script if not in \$PATH."
  exit 1
fi

if ! $(which ${v_jq} >&- 2>&-)
then
  echoError "Could not find jq binary. Please adapt the path in the script if not in \$PATH."
  echoError "Download page: https://github.com/stedolan/jq/releases"
  exit 1
fi

if ! $(which zip >&- 2>&-)
then
  if [ "${v_param1}" == "ALL" -o -n "$HIST_ZIP_FILE" ]
  then
    echoError "Could not find zip binary. Please include it in \$PATH."
    echoError "Zip binary is required to put all output json files together."
    exit 1
  fi
fi

v_zip="zip -9"

v_start_time="${v_param2}"
v_end_time="${v_param3}"

if [ -z "${v_start_time}" ]
then
  case "$(uname -s)" in
      Linux*)     v_start_time=$(date -u -d "-${v_def_period} day" +%Y-%m-%d);;
      Darwin*)    v_start_time=$(date -u -v-${v_def_period}d +%Y-%m-%d);;
      *)          v_start_time=$(date -u +%Y-%m-%d)
  esac
fi

if [ -z "${v_end_time}" ]
then
  v_end_time=$(date -u +%Y-%m-%d)
fi

function check_input_format()
{
  local INPUT_DATE="$1"
  local INPUT_FORMAT="%Y-%m-%d"
  local OUTPUT_FORMAT="%Y-%m-%d"
  local UNAME=$(uname)

  if [[ "$UNAME" == "Darwin" ]] # Mac OS X
  then 
    date -j -f "$INPUT_FORMAT" "$INPUT_DATE" +"$OUTPUT_FORMAT" >/dev/null 2>&- || exitError "Date ${INPUT_DATE} in wrong format. Specify YYYY-MM-DD."
  elif [[ "$UNAME" == "Linux" ]] # Linux
  then
    date -d "$INPUT_DATE" +"$OUTPUT_FORMAT" >/dev/null 2>&- || exitError "Date ${INPUT_DATE} in wrong format. Specify YYYY-MM-DD."
  else # Unsupported system
    date -d "$INPUT_DATE" +"$OUTPUT_FORMAT" >/dev/null 2>&- || exitError "Unsupported system"
  fi
  [ ${#INPUT_DATE} -eq 10 ] || exitError "Date ${INPUT_DATE} in wrong format. Specify YYYY-MM-DD."
}

check_input_format "${v_start_time}"
check_input_format "${v_end_time}"

v_idcs_url="https://${CLIENT_DOMAIN}.identity.oraclecloud.com/"

function idcsAuth ()
{
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_scope v_login_output v_has_access_token
  v_scope="$1"
  local v_login_output=$(curl -X POST -u "${CLIENT_ID}:${CLIENT_SECRET}" -d "grant_type=client_credentials&scope=${v_scope}" "${v_idcs_url}/oauth2/v1/token" 2>&-)
  [ -z "${v_login_output}" ] && exitError "Could not find "${v_idcs_url}". Check your connection and if CLIENT_DOMAIN is correct."
  v_has_access_token=$(${v_jq} -rc 'has("access_token")' <<< "${v_login_output}") && v_ret=$? || v_ret=$?
  [ "${v_has_access_token}" != "true" -o ${v_ret} -ne 0 ] && exitError "${v_login_output}"
  # Echo Token
  ${v_jq} -c '.' <<< "${v_login_output}"
}

if ! $(which timeout >&- 2>&-)
then
  function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
fi

function refreshTokens ()
{
  touch ${v_access_token_1_file} ${v_access_token_2_file}
  chmod 600 ${v_access_token_1_file} ${v_access_token_2_file}
  idcsAuth "urn:opc:resource:consumer:cp:itas:myservices::read" > ${v_access_token_1_file}
  idcsAuth "urn:opc:resource:consumer:cp:itas:metering::read"   > ${v_access_token_2_file}
}

function getTokenValue ()
{
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1
  v_arg1="$1"
  ${v_jq} -r '."access_token"' < "${v_arg1}"
}

function getTokenExpire ()
{
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1
  v_arg1="$1"
  # Will return Epoch time 10 minutes before the real expiration.
  echo $(( $(date -r "${v_arg1}" -u '+%s') + $(${v_jq} -r '."expires_in"' < "${v_arg1}") - 600 ))
}

if [ "${v_conn_type}" == 'CLIENT' ]
then
  v_access_token_1_file="access_token_1_file.json"
  v_access_token_2_file="access_token_2_file.json"
  refreshTokens
else
  # Just test if can get the JSON.
  v_test_url="https://itra.oraclecloud.com/itas/${CLIENT_DOMAIN}/myservices/api/v1/serviceEntitlements"
  v_login_output=$(curl -X GET -u "${CLIENT_USER}:${CLIENT_PASS}" -H "X-ID-TENANT-NAME:${CLIENT_DOMAIN}" "${v_test_url}" 2>&-) || true
  [ -z "${v_login_output}" ] && exitError "Could not find "${v_idcs_url}". Check connection and if CLIENT_DOMAIN is correct."
fi

## Test if temp folder is writable
if [ -n "${v_tmpfldr}" ]
then
  mkdir -p "${v_tmpfldr}" 2>&- || true
else
  echoError "Temporary folder is DISABLED. Execution will take much longer."
  echoError "Press CTRL+C in next 10 seconds if you want to exit and fix this."
  sleep 10
fi
if [ -n "${v_tmpfldr}" -a ! -w "${v_tmpfldr}" ]
then
  echoError "Temporary folder \"${v_tmpfldr}\" is NOT WRITABLE. Execution will take much longer."
  echoError "Press CTRL+C in next 10 seconds if you want to exit and fix this."
  sleep 10
  v_tmpfldr=""
fi

if [ -z "${HIST_ZIP_FILE}" ]
then
  echoError "You haven't exported HIST_ZIP_FILE variable, meaning you won't keep a execution hist that can be reused on next script calls."
  echoError "With zip history, next executions will be much faster. It's extremelly recommended to enable it."
  echoError "Press CTRL+C in next 10 seconds if you want to exit and fix this."
  sleep 10
elif [ -d "${HIST_ZIP_FILE}.lock.d" -a -z "${HIST_IGNORE_LOCK}" ]
then
  exitError "Lock folder \"${HIST_ZIP_FILE}.lock.d\" exists. Remove it before starting this script."
fi

################################################
############### CONVERT FUNCTIONS ##############
################################################

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

function ConvYMDtoNextMonthFirstDay ()
{
  local v_in_date
  v_in_date="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%Y-%m-01' -d "${v_in_date} +1 month -$(($(date +%d)-1)) days");;
      Darwin*)    echo $(date -j -u -v '+1m' -f '%Y-%m-%d' "${v_in_date}" +'%Y-%m-01');;
      *)          echo
  esac  
}

function ConvEpochToYMDhms ()
{
  local v_in_epoch
  v_in_epoch="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%Y-%m-%dT%T' -d @${v_in_epoch});;
      Darwin*)    echo $(date -j -u -f '%s' "${v_in_epoch}" +"%Y-%m-%dT%T");;
      *)          echo
  esac  
}

function ConvEpochToWeekDay ()
{
  local v_in_epoch
  v_in_epoch="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%u' -d @${v_in_epoch});;
      Darwin*)    echo $(date -j -u -f '%s' "${v_in_epoch}" +"%u");;
      *)          echo
  esac  
}

################################################
############### CUSTOM FUNCTIONS ###############
################################################

## curlSimple -> Simply run the parameter with curl.

function runCurl ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -ge 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }

  local v_arg1 v_arg2 v_out v_ret
  local b_out b_err b_ret
  v_arg1="$1"
  v_arg2="$2"
  v_out=$(getFromHist "${v_arg1}") && v_ret=$? || v_ret=$?
  if [ $v_ret -ne 0 ]
  then
    if [ -n "${v_tmpfldr}" ]
    then
      b_out=$(set +x; callCurl "${v_arg1}" "${v_arg2}" 2> ${v_tmpfldr}/oci.err) && b_ret=$? || b_ret=$?
      b_err=$(<${v_tmpfldr}/oci.err)
      rm -f ${v_tmpfldr}/oci.err
    else
      # This crasy string will store the stdout in "b_out", stderr in "b_err" and ret in "b_ret"
      # https://stackoverflow.com/questions/13806626/capture-both-stdout-and-stderr-in-bash
      set +x
      eval "$({ b_err=$({ b_out=$( callCurl "${v_arg1}" "${v_arg2}"); b_ret=$?; } 2>&1; declare -p b_out b_ret >&2); declare -p b_err; } 2>&1)"
      set ${v_dbgflag}
    fi
    if [ -n "${b_err}" -o $b_ret -ne 0 ]
    then
      [ $b_ret -ne 0 ] && { echoError "## Command Failed (ret: ${b_ret}):"; echoDebug "Command Failed (ret: ${b_ret})"; }
      [ $b_ret -eq 0 ] && echoError "## Command Succeeded w/ stderr:"
      echoError "${v_oci} ${v_arg1}"
      echoError "########"
      echoError "${b_err}"
    fi
    if [ $b_ret -eq 0 ]
    then
      v_out="${b_out}"
      # [ -z "${b_err}" ] && putOnHist "${v_arg1}" "${v_out}" || true
      putOnHist "${v_arg1}" "${v_out}" || true
    else
      return $b_ret
    fi
  else
    echoDebug "Got \"${v_arg1}\" from Zip Hist."      
  fi
  ${v_jq} -e . >/dev/null 2>&1 <<< "${v_out}" && v_ret=$? || v_ret=$?
  echo "${v_out}"
  return ${v_ret}
}

function callCurl ()
{
  ##########
  # This function will siply call the CURL final command "arg1" and with optional token file in "arg2"
  ##########

  set +x # Debug can never be enabled here, or stderr will be a mess. It must be disabled even before calling this func to avoid this set +x to be printed.
  set -eo pipefail # Exit if error in any call.
  local v_arg1 v_arg2 v_token
  [ "$#" -ge 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  v_arg1="$1"
  v_arg2="$2"

  if [ "${v_conn_type}" == 'CLIENT' ]
  then
    if [ $(date -u '+%s') -ge $(getTokenExpire "${v_arg2}") ]
    then
      echoDebug "Refreshing Tokens"
      (refreshTokens)
    fi
    v_token=$(getTokenValue "${v_arg2}")
    echoDebug "${v_curl} -s -X GET -H \"Authorization: Bearer \${CLIENT_TOKEN}\" \"${v_arg1}\""      
    timeout ${v_curl_timeout} ${v_curl} -s -X GET -H "Authorization: Bearer ${v_token}" "${v_arg1}"
  else
    echoDebug "${v_curl} -s -X GET -H \"X-ID-TENANT-NAME:${CLIENT_DOMAIN}\" -u \"${CLIENT_USER}:\${CLIENT_PASS}\" \"${v_arg1}\""
    timeout ${v_curl_timeout} ${v_curl} -s -X GET -H "X-ID-TENANT-NAME:${CLIENT_DOMAIN}" -u "${CLIENT_USER}:${CLIENT_PASS}" "${v_arg1}"
  fi
}

function loopCurl ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -ge 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1 v_arg2 v_out v_fout v_hasMore v_hasItems v_offset v_limit v_arg1_mod
  v_arg1="$1"
  v_arg2="$2"
  v_arg1_mod="$v_arg1"
  while true
  do
    v_out=$(runCurl "${v_arg1_mod}" "${v_arg2}")
    v_hasMore=$(${v_jq} -rc '."hasMore" // empty' <<< "${v_out}")
    v_offset=$(${v_jq} -rc '."offset" // empty' <<< "${v_out}")
    v_limit=$(${v_jq} -rc '."limit" // empty' <<< "${v_out}")
    [ -n "${v_offset}" -a -n "${v_limit}" ] && v_arg1_mod="${v_arg1}?offset=$((${v_offset}+${v_limit}))&limit=${v_limit}"
    v_hasItems=$(${v_jq} -rc 'has("items")' <<< "${v_out}")
    [ "${v_hasItems}" == "true" ] && v_out=$(${v_jq} -c '.items | {items : .}' <<< "$v_out") # Remove all tags but "items".
    v_fout=$(jsonConcatItems "$v_fout" "$v_out")
    [ "${v_hasMore}" == "true" ] || break
  done
  v_hasItems=$(${v_jq} -rc 'has("items")' <<< "${v_fout}")
  [ "${v_hasItems}" == "true" ]  && v_fout=$(${v_jq} -c '.items | {data : .}' <<< "$v_fout") # Remove "items" to add "data".
  [ "${v_hasItems}" == "false" ] && v_fout=$(${v_jq} -c '{data : .}' <<< "$v_fout") # Simply add "data".
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function curlSimple ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1
  v_arg1="$1"
  loopCurl "${v_arg1}" "${v_access_token_1_file}" | ${v_jq} '.'
}

function curlAccount ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1 v_account_id
  v_arg1="$1"
  v_account_id=$(serviceEntitlements | ${v_jq} -r '.data[]."cloudAccount"."id"' | sort -u)
  v_arg1=$(sed "s/{accountId}/${v_account_id}/" <<< "${v_arg1}")
  loopCurl "${v_arg1}" "${v_access_token_2_file}" | ${v_jq} '.'
}

function curlAccountEnt ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1_mod v_out v_fout v_account_id l_items v_item v_arg1 v_chk
  v_arg1="$1"
  v_account_id=$(serviceEntitlements | ${v_jq} -r '.data[]."cloudAccount"."id"' | sort -u)
  v_arg1=$(sed "s/{accountId}/${v_account_id}/" <<< "${v_arg1}")
  l_items=$(serviceEntitlements | ${v_jq} -r '.data[]."purchaseEntitlement"."id"' | sort -u)
  IFS=$'\n'
  for v_item in $l_items
  do
    IFS=' '
    v_arg1_mod=$(sed "s/{entitlementId}/${v_item}/" <<< "${v_arg1}")
    v_out=$(loopCurl "${v_arg1_mod}" "${v_access_token_2_file}" 2>&-)
    v_chk=$(${v_jq} -c '.data // empty' <<< "$v_out" | jq -r 'if type=="array" then "yes" else "no" end')
    [ "$v_chk" == "no" ] && v_out=$(${v_jq} -c '.data += {EntitlementID:"'${v_item}'"}' <<< "$v_out")
    [ "$v_chk" == "yes" ] && v_out=$(${v_jq} -c '.data[] += {EntitlementID:"'${v_item}'"}' <<< "$v_out")
    [ -n "$v_out" ] && v_fout=$(jsonConcatData "$v_fout" "$v_out")
  done  
  [ -z "$v_fout" ] || ${v_jq} '.' <<< "${v_fout}"
}

function curlAccountTagHourly ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_jump
  v_jump=$((3600*24*7)) # Jump 7 days
  curlAccountTag "$1" "$v_jump"
  return 0
}

function curlAccountTagDaily ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_jump
  #v_jump=$((3600*24*30)) # Jump 30 days
  v_jump=$((3600*24*7)) # Jump 7 days
  curlAccountTag "$1" "$v_jump"
  return 0
}

function curlAccountTag ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 2 -a "$1" != "" -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_out v_fout v_account_id l_items v_item v_item_clean v_chk v_arg1_mod
  local v_start_epoch v_end_epoch v_jump v_next_epoch_start v_next_date_start v_next_epoch_end v_next_date_end v_start_weekday
  local v_temp_concatenate v_file_counter

  v_arg1="$1"
  v_jump="$2"
  v_account_id=$(serviceEntitlements | ${v_jq} -r '.data[]."cloudAccount"."id"' | sort -u)
  v_arg1=$(sed "s/{accountId}/${v_account_id}/" <<< "${v_arg1}")
  l_items=$(usageTags | ${v_jq} -r '.data[]."tag"')

  v_start_epoch=$(ConvYMDToEpoch ${v_start_time})
  v_end_epoch=$(ConvYMDToEpoch ${v_end_time})

  v_start_weekday=$(ConvEpochToWeekDay ${v_start_epoch})

  # If there is a temp folder, keep results to concatenate in 1 shoot
  if [ -n "${v_tmpfldr}" ]
  then
    v_temp_concatenate="${v_tmpfldr}/tempConc"
    rm -rf "${v_temp_concatenate}"
    mkdir "${v_temp_concatenate}"
  fi

  v_file_counter=1
  IFS=$'\n'
  for v_item in $l_items
  do
    IFS=' '
    v_item_clean=$(echo "$v_item" | sed 's/:/%3A/g' | sed 's/=/%3D/g' | sed 's|/|%2F|g' | sed 's| |%20|g')
    v_next_epoch_start=${v_start_epoch}
    v_next_date_start=$(ConvEpochToYMDhms ${v_next_epoch_start})
    ## Align to Sunday.
    if [ ${v_start_weekday} -eq 7 ]
    then
      v_next_epoch_end=$((${v_next_epoch_start}+${v_jump}))
    else
      v_next_epoch_end=$((${v_next_epoch_start}+3600*24*(7-${v_start_weekday})))
    fi
    [ $v_next_epoch_end -ge ${v_end_epoch} ] && v_next_epoch_end=${v_end_epoch}
    v_next_date_end=$(ConvEpochToYMDhms ${v_next_epoch_end})
    while true
    do
      # Change Arg1 with tag/date info.
      v_arg1_mod=$(sed "s|{tagName}|${v_item_clean}|" <<< "${v_arg1}")
      v_arg1_mod=$(sed "s/{start_time}/${v_next_date_start}/" <<< "${v_arg1_mod}")
      v_arg1_mod=$(sed "s/{end_time}/${v_next_date_end}/" <<< "${v_arg1_mod}")
      # Run
      v_out=$(loopCurl "${v_arg1_mod}" "${v_access_token_2_file}" 2>&-)
      v_chk=$(${v_jq} -rc '.data | if type=="array" then "yes" else "no" end' <<< "$v_out")
      [ "${v_chk}" == "no" ] && v_out=$(${v_jq} -c '.data | {"data":[.]}' <<< "$v_out")
      v_out=$(${v_jq} -c '.data[] += {tag:"'"${v_item}"'"}' <<< "$v_out")
      # If there is a temp folder, keep results to concatenate in 1 shoot
      if [ -n "${v_tmpfldr}" ]
      then
        echo "$v_out" >> "${v_temp_concatenate}/${v_file_counter}.json"
        ((v_file_counter++))
      else
        [ -n "$v_out" ] && v_fout=$(jsonConcatData "$v_fout" "$v_out")
      fi
      # Prepare for next loop
      v_next_epoch_start=${v_next_epoch_end} # Next second = Next day
      [ ${v_next_epoch_start} -ge ${v_end_epoch} ] && break
      v_next_date_start=$(ConvEpochToYMDhms ${v_next_epoch_start})
      v_next_epoch_end=$((${v_next_epoch_start}+${v_jump}))
      [ $v_next_epoch_end -ge ${v_end_epoch} ] && v_next_epoch_end=${v_end_epoch}
      v_next_date_end=$(ConvEpochToYMDhms ${v_next_epoch_end})
    done
  done

  if [ -n "${v_tmpfldr}" ]
  then
    # To avoid: Argument list too long
    find "${v_temp_concatenate}" -name "*.json" -type f -exec cat {} + > "${v_temp_concatenate}"/all_json.concat
    v_fout=$(${v_jq} -c 'reduce inputs as $i (.; .data += $i.data)' "${v_temp_concatenate}"/all_json.concat)
    rm -rf "${v_temp_concatenate}"
  fi

  [ -z "$v_fout" ] || ${v_jq} '.' <<< "${v_fout}"
}

function curlAccountServ ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1 v_arg1_mod v_out v_fout v_account_id l_items v_item v_chk
  v_arg1="$1"
  v_account_id=$(serviceEntitlements | ${v_jq} -r '.data[]."cloudAccount"."id"' | sort -u)
  v_arg1=$(sed "s/{accountId}/${v_account_id}/" <<< "${v_arg1}")
  l_items=$(serviceEntitlements | ${v_jq} -r '.data[]."serviceDefinition"."name"' | sort -u)
  IFS=$'\n'
  for v_item in $l_items
  do
    IFS=' '
    v_arg1_mod=$(sed "s/{serviceName}/${v_item}/" <<< "${v_arg1}")
    v_out=$(loopCurl "${v_arg1_mod}" "${v_access_token_2_file}" 2>&-)
    v_chk=$(${v_jq} -c '.data // empty' <<< "$v_out" | jq -r 'if type=="array" then "yes" else "no" end')
    [ "$v_chk" == "no" ] && v_out=$(${v_jq} -c '.data += {serviceDefinition:"'${v_item}'"}' <<< "$v_out")
    [ "$v_chk" == "yes" ] && v_out=$(${v_jq} -c '.data[] += {serviceDefinition:"'${v_item}'"}' <<< "$v_out")
    [ -n "$v_out" ] && v_fout=$(jsonConcatData "$v_fout" "$v_out")
  done  
  [ -z "$v_fout" ] || ${v_jq} '.' <<< "${v_fout}"
}

function curlAccountServ2 ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1_mod v_out v_fout v_account_id l_items v_item v_arg1
  v_arg1="$1"
  v_account_id=$(serviceEntitlements | ${v_jq} -r '.data[]."cloudAccount"."id"' | sort -u)
  v_arg1=$(sed "s/{accountId}/${v_account_id}/" <<< "${v_arg1}")
  l_items=$(serviceEntitlements | ${v_jq} -r '.data[]."serviceDefinition"."name"' | sort -u)
  IFS=$'\n'
  for v_item in $l_items
  do
    IFS=' '
    v_arg1_mod=$(sed "s/{serviceName}/${v_item}/" <<< "${v_arg1}")
    v_out=$(loopCurl "${v_arg1_mod}" "${v_access_token_2_file}" 2>&-)
    [ -n "$v_out" ] && v_fout=$(jsonConcatData "$v_fout" "$v_out")
  done  
  [ -z "$v_fout" ] || ${v_jq} '.' <<< "${v_fout}"
}

function jsonConcatItems ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 2 ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_chk_json
  v_arg1="$1" # Json 1
  v_arg2="$2" # Json 2
  ## Concatenate if both not null.
  [ -z "${v_arg1}" -a -n "${v_arg2}" ] && echo "${v_arg2}" && return 0
  [ -n "${v_arg1}" -a -z "${v_arg2}" ] && echo "${v_arg1}" && return 0
  [ -z "${v_arg1}" -a -z "${v_arg2}" ] && return 0
  ## Check if has ".items"
  v_chk_json=$(${v_jq} -c 'has("items")' <<< "${v_arg1}")
  [ "${v_chk_json}" == "false" ] && return 1
  v_chk_json=$(${v_jq} -c 'has("items")' <<< "${v_arg2}")
  [ "${v_chk_json}" == "false" ] && return 1
  v_chk_json=$(${v_jq} -rc '.items | if type=="array" then "yes" else "no" end' <<< "$v_arg1")
  [ "${v_chk_json}" == "no" ] && v_arg1=$(${v_jq} -c '.items | {"items":[.]}' <<< "$v_arg1")
  v_chk_json=$(${v_jq} -rc '.items | if type=="array" then "yes" else "no" end' <<< "$v_arg2")
  [ "${v_chk_json}" == "no" ] && v_arg2=$(${v_jq} -c '.items | {"items":[.]}' <<< "$v_arg2")
  ${v_jq} -c 'reduce inputs as $i (.; .items += $i.items)' <(echo "$v_arg1") <(echo "$v_arg2")
  return 0
}

function jsonConcatData ()
{
  ##########
  # This function will concatenate 2 json arguments in {.data[*]} format in a single one.
  ##########

  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 2 ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_chk_json
  v_arg1="$1" # Json 1
  v_arg2="$2" # Json 2
  ## Concatenate if both not null.
  [ -z "${v_arg1}" -a -n "${v_arg2}" ] && echo "${v_arg2}" && return 0
  [ -n "${v_arg1}" -a -z "${v_arg2}" ] && echo "${v_arg1}" && return 0
  [ -z "${v_arg1}" -a -z "${v_arg2}" ] && return 0
  ## Check if has ".data"
  v_chk_json=$(${v_jq} -c 'has("data")' <<< "${v_arg1}")
  [ "${v_chk_json}" == "false" ] && return 1
  v_chk_json=$(${v_jq} -c 'has("data")' <<< "${v_arg2}")
  [ "${v_chk_json}" == "false" ] && return 1
  v_chk_json=$(${v_jq} -rc '.data | if type=="array" then "yes" else "no" end' <<< "$v_arg1")
  [ "${v_chk_json}" == "no" ] && v_arg1=$(${v_jq} -c '.data | {"data":[.]}' <<< "$v_arg1")
  v_chk_json=$(${v_jq} -rc '.data | if type=="array" then "yes" else "no" end' <<< "$v_arg2")
  [ "${v_chk_json}" == "no" ] && v_arg2=$(${v_jq} -c '.data | {"data":[.]}' <<< "$v_arg2")
  ${v_jq} -c 'reduce inputs as $i (.; .data += $i.data)' <(echo "$v_arg1") <(echo "$v_arg2")
  return 0
}

################################################
################# OPTION LIST ##################
################################################

# Structure:
# 1st - Json Function Name.
# 2nd - Json Target File Name. Used when ALL parameter is passed to the shell.
# 3rd - Function to call. Can be one off the generics above or a custom one.
# 4th - CURL command line to be executed.

## https://docs.oracle.com/en/cloud/get-started/subscriptions-cloud/meter/rest-endpoints.html

# DON'T REMOVE/CHANGE THOSE COMMENTS. THEY ARE USED TO GENERATE DYNAMIC FUNCTIONS

# BEGIN DYNFUNC
# serviceEntitlements,oci_cloud_serviceEntitlements.json,curlSimple,"https://itra.oraclecloud.com/itas/${CLIENT_DOMAIN}/myservices/api/v1/serviceEntitlements"
# serviceResources,oci_cloud_serviceResources.json,curlAccountServ2,"https://itra.oraclecloud.com/metering/api/v1/resources/{serviceName}"
# usageTags,oci_cloud_usageTags.json,curlAccount,"https://itra.oraclecloud.com/metering/api/v1/usage/{accountId}/tags?tagType=ALL"
# usageCost,oci_cloud_usageCost.json,curlAccount,"https://itra.oraclecloud.com/metering/api/v1/usagecost/{accountId}?startTime=${v_start_time}T00:00:00.000Z&endTime=${v_end_time}T00:00:00.000Z&usageType=HOURLY&timeZone=UTC&dcAggEnabled=Y"
# usage,oci_cloud_usage.json,curlAccount,"https://itra.oraclecloud.com/metering/api/v1/usage/{accountId}?startTime=${v_start_time}T00:00:00.000Z&endTime=${v_end_time}T00:00:00.000Z&usageType=HOURLY&timeZone=UTC"
# usageCostTaggedDaily,oci_cloud_usageCostTaggedDaily.json,curlAccountTagDaily,"https://itra.oraclecloud.com/metering/api/v1/usagecost/{accountId}/tagged?startTime={start_time}.000Z&endTime={end_time}.000Z&usageType=DAILY&timeZone=UTC&tags={tagName}"
# usageCostTaggedHourly,oci_cloud_usageCostTaggedHourly.json,curlAccountTagHourly,"https://itra.oraclecloud.com/metering/api/v1/usagecost/{accountId}/tagged?startTime={start_time}.000Z&endTime={end_time}.000Z&usageType=HOURLY&timeZone=UTC&tags={tagName}"
# accountDetails,oci_cloud_accountDetails.json,curlAccount,"https://itra.oraclecloud.com/metering/api/v1/cloudbucks/{accountId}"
# checkQuota,oci_cloud_checkQuota.json,curlAccountServ,"https://itra.oraclecloud.com/metering/api/v1/checkQuota/{accountId}?serviceName={serviceName}"
# promotions,oci_cloud_promotions.json,curlAccount,"https://itra.oraclecloud.com/metering/api/v1/promotions/{accountId}"
# cloudLimits,oci_cloud_cloudLimits.json,curlAccountEnt,"https://itra.oraclecloud.com/metering/api/v1/cloudbucklimits/{accountId}/{entitlementId}"
# END DYNFUNC

# The while loop below will create a function for each line above.
# Using File Descriptor 3 to not interfere on "eval"
while read -u 3 -r c_line || [ -n "$c_line" ]
do
  c_name=$(cut -d ',' -f 1 <<< "$c_line")
  c_fname=$(cut -d ',' -f 2 <<< "$c_line")
  c_subfunc=$(cut -d ',' -f 3 <<< "$c_line")
  c_param=$(cut -d ',' -f 4 <<< "$c_line")
  if [ -z "${v_tmpfldr}" ]
  then
    eval "function ${c_name} ()
          {
            set +e
            local c_ret
            (${c_subfunc} ${c_param})
            c_ret=\$?
            return \${c_ret}
          }"
  else
    eval "function ${c_name} ()
          {
            set +e
            local c_ret
            stopIfProcessed ${c_fname} || return 0
            (${c_subfunc} ${c_param} > ${v_tmpfldr}/.${c_fname})
            c_ret=\$?
            cat ${v_tmpfldr}/.${c_fname}
            return \${c_ret}
          }"
  fi
done 3< <(echo "$v_func_list")

function stopIfProcessed ()
{
  set ${v_dbgflag} # Enable Debug
  # If function was executed before, print the output and return error. The dynamic eval function will stop if error is returned.
  local v_arg1="$1"
  [ -z "${v_tmpfldr}" ] && return 0
  if [ -f "${v_tmpfldr}/.${v_arg1}" ]
  then
    cat "${v_tmpfldr}/.${v_arg1}"
    return 1
  else
    return 0
  fi
}

function runAndZip ()
{
  [ "$#" -eq 2 -a "$1" != "" -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_ret
  v_arg1="$1"
  v_arg2="$2"
  echo "Processing \"${v_arg2}\"."
  set +e
  (${v_arg1} > "${v_arg2}" 2> "${v_arg2}.err") # Executing in subshell as inner function may run with set -e and fail, aborting whole code.
  v_ret=$?
  set -e
  if [ $v_ret -eq 0 ]
  then
    if [ -s "${v_arg2}.err" ]
    then
      mv "${v_arg2}.err" "${v_arg2}.log"
      ${v_zip} -qm "$v_outfile" "${v_arg2}.log"
    fi
  else
    if [ -f "${v_arg2}.err" ]
    then
      echo "Skipped. Check \"${v_arg2}.err\" for more details."
      ${v_zip} -qm "$v_outfile" "${v_arg2}.err"
    fi
  fi
  [ ! -f "${v_arg2}.err" ] || rm -f "${v_arg2}.err"
  if [ -s "${v_arg2}" ]
  then
    ${v_zip} -qm "$v_outfile" "${v_arg2}"
  else
    rm -f "${v_arg2}"
  fi
}

function cleanTmpFiles ()
{
  [ -n "${v_tmpfldr}" ] && rm -f "${v_tmpfldr}"/.*.json 2>&- || true
  return 0
}

function uncompressHist ()
{
  set ${v_dbgflag} # Enable Debug
  if [ -n "${HIST_ZIP_FILE}" ]
  then
    rm -rf ${v_hist_folder}
    mkdir  ${v_hist_folder}
    if [ -r "${HIST_ZIP_FILE}" ]
    then
      unzip -q -d ${v_hist_folder} "${HIST_ZIP_FILE}"
    fi
  fi
  return 0
}

function cleanHist ()
{
  set ${v_dbgflag} # Enable Debug
  if [ -n "${HIST_ZIP_FILE}" ]
  then
    # [ "$(ls -A ${v_hist_folder})" ] && zip -mj ${HIST_ZIP_FILE} ${v_hist_folder}/* >/dev/null
    # rmdir ${v_hist_folder}
    rm -rf ${v_hist_folder}
  fi
  return 0
}

function getFromHist ()
{
  ##########
  # This function will get the output of the command from the zip hist file that was executed before.
  ##########

  set -eo pipefail
  set ${v_dbgflag} # Enable Debug
  [ -z "${HIST_ZIP_FILE}" ] && return 1
  [ "$#" -ne 1 ] && { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1 v_line v_sep v_list v_file v_file_epoch v_now_epoch
  v_arg1="$1"
  v_list="history_list.txt"
  v_sep="|"
  # grep -q "startTime=" <<< "${v_arg1}" || return 1
  # grep -q "endTime=" <<< "${v_arg1}" || return 1
  [ ! -r "${v_hist_folder}/${v_list}" ] && return 1
  v_line=$(grep -F "${v_arg1}${v_sep}" "${v_hist_folder}/${v_list}")
  [ $(wc -l <<< "${v_line}") -gt 1 ] && return 1
  v_file=$(cut -d"${v_sep}" -f2 <<< "${v_line}")
  [ -z "${v_file}" ] && return 1
  [ ! -r "${v_hist_folder}/${v_file}" ] && return 1
  if ! ( grep -q "startTime=" <<< "${v_arg1}" && grep -q "endTime=" <<< "${v_arg1}" )
  then    
    v_file_epoch=$(date -r "${v_hist_folder}/${v_file}" -u '+%s')
    v_now_epoch=$(date -u '+%s')
    [ $((v_now_epoch-v_file_epoch)) -ge $((3600*24*3)) ] && return 1 # 3 days
  fi
  cat "${v_hist_folder}/${v_file}"
  return 0
}

function putOnHist ()
{
  ##########
  # This function will save the output of the command in a zip hist file to be later used again.
  ##########

  set -eo pipefail
  set ${v_dbgflag} # Enable Debug
  [ -z "${HIST_ZIP_FILE}" ] && return 1
  [ ! -d "${v_hist_folder}" ] && return 1
  [ "$#" -ne 2 ] && { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_line v_sep v_list v_file v_last
  v_arg1="$1"
  v_arg2="$2"
  v_list="history_list.txt"
  v_sep="|"
  [ -r "${v_hist_folder}/${v_list}" ] && v_line=$(grep -F "${v_arg1}${v_sep}" "${v_hist_folder}/${v_list}") || true
  if [ -z "${v_line}" ]
  then
    if [ -r "${v_hist_folder}/${v_list}" ]
    then
      v_last=$(cut -d"${v_sep}" -f2 < "${v_hist_folder}/${v_list}" | sed 's/\.json$//' | sort -nr | head -n 1)
    else
      v_last=0
    fi
    v_file="$((v_last+1)).json"
    [ -r "${v_hist_folder}/${v_file}" ] && return 1
    echo "${v_arg1}${v_sep}${v_file}" >> "${v_hist_folder}/${v_list}"
    echo "${v_arg2}" > "${v_hist_folder}/${v_file}"
  else
    [ $(wc -l <<< "${v_line}") -gt 1 ] && return 1
    v_file=$(cut -d"${v_sep}" -f2 <<< "${v_line}")
    [ ! -r "${v_hist_folder}/${v_file}" ] && return 1
    echo "${v_arg2}" > "${v_hist_folder}/${v_file}"
  fi
  ${v_zip} -qj ${HIST_ZIP_FILE} "${v_hist_folder}/${v_list}"
  ${v_zip} -qj ${HIST_ZIP_FILE} "${v_hist_folder}/${v_file}"
  return 0
}

function main ()
{
  ##########
  # This the main function. Will execute one given parameter option or loop over all possibilities and zip the output.
  ##########

  # If ALL, loop over all defined options.
  local c_line c_name c_file
  cleanTmpFiles
  uncompressHist
  if [ "${v_param1}" != "ALL" ]
  then
    set +e
    (${v_param1}) # Executing in subshell as inner function may run with set -e and fail, aborting whole code.
    v_ret=$?
    set -e
  else
    [ -n "$v_outfile" ] || v_outfile="${v_this_script%.*}_$(date '+%Y%m%d%H%M%S').zip"
    while read -u 3 -r c_line || [ -n "$c_line" ]
    do
       c_name=$(cut -d ',' -f 1 <<< "$c_line")
       c_file=$(cut -d ',' -f 2 <<< "$c_line")
       runAndZip $c_name $c_file
    done 3< <(echo "$v_func_list")
    v_ret=0
  fi
  cleanHist
  cleanTmpFiles
}

# Start code execution.
[ "${v_param1}" == "ALL" ] && DEBUG=1

echoDebug "BEGIN"
main
echoDebug "END"

[ "${v_param1}" == "ALL" ] && ${v_zip} -qm "$v_outfile" "${v_this_script%.*}.log"

if [ "${v_conn_type}" == 'CLIENT' ]
then
  rm -f $v_access_token_1_file
  rm -f $v_access_token_2_file
fi

[ -n "${v_tmpfldr}" ] && rmdir ${v_tmpfldr} 2>&- || true

exit ${v_ret}
###