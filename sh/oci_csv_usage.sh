#!/bin/bash
#************************************************************************
#
#   oci_csv_usage.sh - Export all Oracle Cloud usage report
#   information into CSV files.
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
# Created on: May/2020 by Rodrigo Jorge
# Version 1.04
#************************************************************************
set -eo pipefail

# Define paths for oci-cli and jq or put them on $PATH. Don't use relative PATHs in the variables below.
v_oci="oci"
v_jq="jq"

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

# Default period in days to collect info, if omitted on parameters
v_def_period=30

# Export DEBUG=1 to see the steps being executed.
[[ "${DEBUG}" == "" ]] && DEBUG=1
[ ! -z "${DEBUG##*[!0-9]*}" ] || DEBUG=1

# If Shell is executed with "-x", all core functions will set this flag 
printf %s\\n "$-" | grep -q -F 'x' && v_dbgflag='-x' || v_dbgflag='+x'

# Export HIST_ZIP_FILE with the file name where will keep or read for historical info to avoid reprocessing.
[[ "${HIST_ZIP_FILE}" == "" ]] && HIST_ZIP_FILE=""

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
  local v_debug_lvl="$2"
  local v_filename="${v_this_script%.*}.log"
  [ -z "${v_debug_lvl}" ] && v_debug_lvl=1
  [ $DEBUG -ge ${v_debug_lvl} ] && echo "$(date '+%Y%m%d%H%M%S'): $1" >> ${v_filename}
  [ $DEBUG -ge ${v_debug_lvl} ] && [ -f "../${v_filename}" ] && echo "$(date '+%Y%m%d%H%M%S'): $1" >> ../${v_filename}
  return 0
}

v_this_script="$(basename -- "$0")"

v_param1="$1"
v_param2="$2"
v_param3="$3"

if [ "$v_param1" != "-r" -a "$v_param1" != "-d" ]
then
  echoError "Usage: ${v_this_script} <option> [begin_time] [end_time]"
  echoError ""
  echoError "Valid <option> values are:"
  echoError "-r    - RUN. You need to provide this parameter to execute this script."
  echoError "-d    - Dry run. Will show you only the commands to get the CSVs that would be executed."
  echoError ""
  echoError "[begin_time] (Optional) - Defines start time when exporting Usage Info. (Default is $v_def_period days back) "
  echoError "[end_time]   (Optional) - Defines end time when exporting Usage Info. (Default is today)"
  echoError ""
  echoError "PS: it is possible to export the following variables to change oci-cli behaviour:"
  echoError "- OCI_CLI_ARGS - All parameters provided will be appended to oci-cli call."
  echoError "                 Eg: export OCI_CLI_ARGS='--profile ACME'"
  exit 1
fi

[ "$v_param1" == "-r" ] && v_execute=true || v_execute=false

if ! $(which ${v_oci} >&- 2>&-)
then
  echoError "Could not find oci-cli binary. Please adapt the path in the script if not in \$PATH."
  echoError "Download page: https://github.com/oracle/oci-cli"
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
  if ${v_execute}
  then
    echoError "Could not find zip binary. Please include it in \$PATH."
    echoError "Zip binary is required to put all output csv files together."
    exit 1
  fi
fi

v_zip="zip -9"

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

if ! $(which timeout >&- 2>&-)
then
  function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
fi

if [ -z "${HIST_ZIP_FILE}" ] && ${v_execute}
then
  echoError "You haven't exported HIST_ZIP_FILE variable, meaning you won't keep a execution history track that can be reused on next script calls."
  echoError "With zip history, next executions will be differential and much faster. It's extremelly recommended to enable it."
  echoError "Eg: export HIST_ZIP_FILE='./report_hist.zip'"
  echoError "Press CTRL+C in next 10 seconds if you want to exit and fix this."
  sleep 10
fi

################################################
############### CONVERT FUNCTIONS ##############
################################################

function ConvYMDToEpoch ()
{
  set -eo pipefail # Exit if error in any call.
  local v_in_date
  v_in_date="$1"
  v_in_time="$2"
  [ -z "${v_in_time}" ] && v_in_time="00:00:00"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%s' -d "${v_in_date} ${v_in_time}");;
      Darwin*)    echo $(date -j -u -f '%Y-%m-%d %T' "${v_in_date} ${v_in_time}" +"%s");;
      *)          echo
  esac  
}

function ConvEpochToYMDhms ()
{
  set -eo pipefail # Exit if error in any call.
  local v_in_epoch
  v_in_epoch="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%Y-%m-%dT%T' -d @${v_in_epoch});;
      Darwin*)    echo $(date -j -u -f '%s' "${v_in_epoch}" +"%Y-%m-%dT%T");;
      *)          echo
  esac  
}

################################################
################ CORE FUNCTIONS ################
################################################

function tenancyID ()
{
  set -eo pipefail # Exit if error in any call.
  local v_fout v_tenancy_id
  v_fout=$(jsonSimple "iam compartment list --all --compartment-id-in-subtree true" '.')
  if [ -n "$v_fout" ]
  then
    v_tenancy_id=$(${v_jq} -r '[.data[]."compartment-id"] | unique | .[] | select(startswith("ocid1.tenancy.oc1."))' <<< "${v_fout}")
    echo "${v_tenancy_id}"
  fi
}

function csvUsageReport ()
{
  ##########
  # This function will get your usage info on the desired range.
  ##########

  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 0 ] || { echoError "${FUNCNAME[0]} needs 0 parameter"; return 1; }
  local v_out v_fout v_oci_audqry v_search v_ret
  local v_start_epoch v_end_epoch
  local v_tenancy_id v_oci_usagereport
  local c_name c_date c_date_YMD c_time_hms c_time_epoch

  v_start_epoch=$(ConvYMDToEpoch ${v_start_time})
  v_end_epoch=$(ConvYMDToEpoch ${v_end_time} 23:59:59)

  echo "- Start Date: ${v_start_time} 00:00:00."
  echo "- Final Date: ${v_end_time} 23:59:59."

  v_tenancy_id=$(tenancyID)
  echo "- Tenancy OCID is ${v_tenancy_id}."
  v_oci_usagereport="os object list --namespace bling --bucket-name ${v_tenancy_id} --all"

  echo "- Generating file list..."
  set +e
  l_itens=$(jsonSimple "${v_oci_usagereport}" '.' | ${v_jq} -r '.data[] | [."name",."time-created"] | @csv')
  v_ret=$?
  set -e
  if [ $v_ret -ne 0 ]
  then
    echoError "Check if you have given the required IAM policy, as described here:"
    echoError "https://docs.cloud.oracle.com/en-us/iaas/Content/Billing/Tasks/accessingusagereports.htm"
    return $v_ret
  fi

  for v_item in $l_itens
  do
    c_name=$(cut -d ',' -f 1 <<< "$v_item" | sed 's/^.//; s/.$//')
    c_fdate=$(cut -d ',' -f 2 <<< "$v_item" | sed 's/^.//; s/.$//')
    c_fdate_YMD=${c_fdate:0:10}
    c_fdate_hms=${c_fdate:11:8}
    c_fdate_epoch=$(ConvYMDToEpoch ${c_fdate_YMD} ${c_fdate_hms})
    if [ $c_fdate_epoch -lt $v_start_epoch -o $c_fdate_epoch -gt $v_end_epoch ]
    then
      echoDebug "${c_name} date is ${c_fdate} - Outside requested scope." 2
      continue
    fi
    c_file=$(sed 's/\//_/g' <<< "${c_name}")
    if ${v_execute}
    then
      echo "- Getting ${c_name} created on ${c_fdate}."
      v_search="${c_file}_${c_fdate}"
      # Will first try to get the output from the historical zip. If can't find it, will call the get function.
      getFileFromZip "${v_search}" "${c_file}" && v_ret=$? || v_ret=$?
      if [ $v_ret -ne 0 ]
      then
        # Run
        v_oci_usagereport="os object get --namespace bling --bucket-name ${v_tenancy_id} --name $c_name --file ${c_file}"
        v_out=$(jsonSimple "${v_oci_usagereport}" ".")
        (putFileOnZip "${v_search}" "${c_file}") || true
      else
        echoDebug "Got \"${c_file}\" from Zip Hist."
      fi
      ${v_zip} -qm "$v_outfile" "${c_file}"
    else
      echo "${v_oci} os object get --namespace bling --bucket-name ${v_tenancy_id} --name $c_name --file ${c_file}"
    fi
  done

  [ -z "${c_file}" ] && echo "- Could not find any file that satisfy provided data range. Run 'export DEBUG=2' prior to shell execution to get more details on ${v_this_script%.*}.log."
  [ -n "${c_file}" -a "${v_execute}" == "true" ] && echo "- All files were successfully compressed inside ${v_outfile}."

  return 0
}

function jsonSimple ()
{
  ##########
  # This function will get the oci command args and pass to runOCI.
  # However, if the output contains pages, it will loop over all available pages and concatenate the output.
  ##########

  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 2 -a "$1" != ""  -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_out v_fout v_next_page v_arg1_mod
  v_arg1="$1"
  v_arg2="$2"
  v_arg1_mod="$v_arg1"
  while true
  do
    v_out=$(runOCI "${v_arg1_mod}" "${v_arg2}")
    v_next_page=$(${v_jq} -rc '."opc-next-page" // empty' <<< "${v_out}")
    [ -n "${v_next_page}" ] && v_out=$(${v_jq} -c '.data | {data : .}' <<< "$v_out") # Remove Next-Page Tag if it has one.
    [ -n "${v_next_page}" ] && v_arg1_mod="${v_arg1} --page ${v_next_page}"
    v_fout=$(jsonConcatData "$v_fout" "$v_out")
    [ -z "${v_next_page}" ] && break
  done
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function runOCI ()
{
  ##########
  # This function will check if the given OCI cli to execute was already executed before and if the output is stored in HIST_ZIP_FILE.
  # If not executed, will run callOCI and later save the output.
  ##########

  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 2 -a "$1" != "" -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_out v_ret v_search
  local b_out b_err b_ret
  v_arg1="$1"
  v_arg2="$2"
  echoDebug "${v_oci} ${v_arg1}"
  # This crasy string will store the stdout in "b_out", stderr in "b_err" and ret in "b_ret"
  # https://stackoverflow.com/questions/13806626/capture-both-stdout-and-stderr-in-bash
  set +x
  eval "$({ b_err=$({ b_out=$( callOCI "${v_arg1}" "${v_arg2}"); b_ret=$?; } 2>&1; declare -p b_out b_ret >&2); declare -p b_err; } 2>&1)"
  set ${v_dbgflag}
  [ "${b_out}" == '{"data":[]}' ] && b_out='' # In case it is empty data, clean it for space savings.
  [ "${b_err}" == 'Downloading object' ] && b_err='' # In case it is empty data, clean it for space savings.
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
  else
    return $b_ret
  fi
  ${v_jq} -e . >/dev/null 2>&1 <<< "${v_out}" && v_ret=$? || v_ret=$?
  echo "${v_out}"
  return ${v_ret}
}

function callOCI ()
{
  ##########
  # This function will siply call the OCI cli final command "arg1" and apply any JQ filter to it "arg2"
  ##########

  set +x # Debug can never be enabled here, or stderr will be a mess. It must be disabled even before calling this func to avoid this set +x to be printed.
  set -eo pipefail # Exit if error in any call.
  local v_arg1 v_arg2
  [ "$#" -eq 2 -a "$1" != "" -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  v_arg1="$1"
  v_arg2="$2"
  eval "timeout ${v_oci_timeout} ${v_oci} ${v_arg1}" | ${v_jq} -c "${v_arg2}"
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


function uncompressHist ()
{
  ##########
  # Uncompress list file from previous execution.
  ##########

  set ${v_dbgflag} # Enable Debug
  local v_list="history_list.txt"
  if [ -n "${HIST_ZIP_FILE}" -a -r "${HIST_ZIP_FILE}" ]
  then
    unzip -qo "${HIST_ZIP_FILE}" "${v_list}"
  fi
  return 0
}

function cleanHist ()
{
  ##########
  # Clean list file.
  ##########

  set ${v_dbgflag} # Enable Debug
  local v_list="history_list.txt"
  if [ -n "${HIST_ZIP_FILE}" -a -f "${v_list}" ]
  then
    rm -f "${v_list}"
  fi
  return 0
}

function getFileFromZip ()
{
  ##########
  # This function will get the output of the command from the zip hist file that was executed before.
  ##########

  set -eo pipefail
  set ${v_dbgflag} # Enable Debug
  [ -z "${HIST_ZIP_FILE}" ] && return 1
  [ "$#" -ne 2 ] && { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_key v_file v_sep v_line v_list v_file v_file_epoch v_now_epoch
  v_key="$1"
  v_file="$2"
  v_sep="|"
  v_list="history_list.txt"
  [ ! -r "${v_list}" ] && return 1
  v_line=$(grep -F "${v_key}${v_sep}" "${v_list}")
  [ -z "${v_line}" -o $(wc -l <<< "${v_line}") -ne 1 ] && return 1
  unzip -qo "${HIST_ZIP_FILE}" "${v_file}" 
  [ ! -r "${v_file}" ] && return 1
  return 0
}

function putFileOnZip ()
{
  ##########
  # This function will save the output of the command in a zip hist file to be later used again.
  ##########

  set -eo pipefail
  set ${v_dbgflag} # Enable Debug
  [ -z "${HIST_ZIP_FILE}" ] && return 1
  [ "$#" -ne 2 ] && { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_key v_file v_sep v_line v_list
  v_key="$1"
  v_file="$2"
  v_sep="|"
  v_list="history_list.txt"
  [ -r "${v_list}" ] && v_line=$(grep -F "${v_key}${v_sep}" "${v_list}") || true
  if [ -z "${v_line}" ]
  then
    echo "${v_key}${v_sep}${v_file}" >> "${v_list}"
  else
    [ $(wc -l <<< "${v_line}") -gt 1 ] && return 1
  fi
  echoDebug "Adding ${v_file} to ${HIST_ZIP_FILE}." 2
  ${v_zip} -qj ${HIST_ZIP_FILE} "${v_list}"
  ${v_zip} -qj ${HIST_ZIP_FILE} "${v_file}"
  return 0
}

function main ()
{
  ##########
  # This the main function. Will execute one given parameter option or loop over all possibilities and zip the output.
  ##########

  v_outfile="${v_this_script%.*}_$(date '+%Y%m%d%H%M%S').zip"
  csvUsageReport
  v_ret=$?
}

# Start code execution.

echoDebug "BEGIN"
uncompressHist
main
cleanHist
echoDebug "END"

[ -f "${v_this_script%.*}.log" -a -f "$v_outfile" ] && ${v_zip} -qm "$v_outfile" "${v_this_script%.*}.log"

exit ${v_ret}
###
