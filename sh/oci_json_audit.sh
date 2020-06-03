#!/bin/bash
#************************************************************************
#
#   oci_json_audit.sh - Export all Oracle Cloud Audit metadata
#   information into JSON files.
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
# Created on: Aug/2019 by Rodrigo Jorge
# Version 1.09
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
v_min_ocicli="2.4.34"

# Timeout for OCI-CLI calls
v_oci_timeout=1800 # Seconds

# Default period in days to collect info, if omitted on parameters
v_def_period=3

[[ "${TMPDIR}" == "" ]] && TMPDIR='/tmp/'
# Temporary Folder. Used to stage some repetitive jsons and save time. Empty to disable (not recommended).
v_tmpfldr="$(mktemp -d -u -p ${TMPDIR}/.oci 2>&- || mktemp -d -u)"

# Export DEBUG=1 to see the steps being executed.
[[ "${DEBUG}" == "" ]] && DEBUG=1
[ ! -z "${DEBUG##*[!0-9]*}" ] || DEBUG=1

# If Shell is executed with "-x", all core functions will set this flag 
printf %s\\n "$-" | grep -q -F 'x' && v_dbgflag='-x' || v_dbgflag='+x'

# Export HIST_ZIP_FILE with the file name where will keep or read for historical info to avoid reprocessing.
[[ "${HIST_ZIP_FILE}" == "" ]] && HIST_ZIP_FILE=""

v_hist_folder="audit_history"

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

v_func_list=$(sed -e '1,/^# BEGIN DYNFUNC/d' -e '/^# END DYNFUNC/,$d' -e 's/^# *//' $0)
v_opt_list=$(echo "${v_func_list}" | cut -d ',' -f 1 | sort | tr "\n" ",")
v_valid_opts="ALL,ALL_REGIONS"
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
  echoError "[begin_time] (Optional) - Defines start time when exporting Audit Info. (Default is $v_def_period days back) "
  echoError "[end_time]   (Optional) - Defines end time when exporting Audit Info. (Default is today)"
  echoError ""
  echoError "Valid <option> values are:"
  echoError "- ALL         - Execute json export for ALL possible options and compress output in a zip file."
  echoError "- ALL_REGIONS - Same as ALL, but run for all tenancy's subscribed regions."
  echoError "$(funcPrintRange "$v_opt_list")"
  echoError ""
  echoError "------------------------------------"
  echoError ""
  echoError "PS: it is possible to export the following variables to change oci-cli behaviour:"
  echoError "- OCI_CLI_ARGS - All parameters provided will be appended to oci-cli call."
  echoError "                 Eg: export OCI_CLI_ARGS='--profile ACME'"

  exit 1
fi

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
  if [ "${v_param1}" == "ALL" -o -n "$HIST_ZIP_FILE" ]
  then
    echoError "Could not find zip binary. Please include it in \$PATH."
    echoError "Zip binary is required to put all output json files together."
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
  echoError "You haven't exported HIST_ZIP_FILE variable, meaning you won't keep a execution history track that can be reused on next script calls."
  echoError "With zip history, next executions will be differential and much faster. It's extremelly recommended to enable it."
  echoError "Eg: export HIST_ZIP_FILE='./audit_hist.zip'"
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

function jsonCompartments ()
{
  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  local v_fout v_tenancy_id
  # I don't know why I need to put this OR here, but the set -e seems not to work when subfunction fails
  v_fout=$(jsonSimple "iam compartment list --all --compartment-id-in-subtree true" ".")
  ## Remove DELETED compartments to avoid query errors
  if [ -n "$v_fout" ]
  then
    v_fout=$(${v_jq} -c '{data:[.data[] | select(."lifecycle-state" != "DELETED")]}' <<< "${v_fout}")
    v_tenancy_id=$(${v_jq} -r '[.data[]."compartment-id"] | unique | .[] | select(startswith("ocid1.tenancy.oc1."))' <<< "${v_fout}")
    ## Add root:
    v_fout=$(${v_jq} -c '.data += [{
                                 "compartment-id": "'${v_tenancy_id}'",
                                 "defined-tags": {},
                                 "description": null,
                                 "freeform-tags": {},
                                 "id": "'${v_tenancy_id}'",
                                 "inactive-status": null,
                                 "is-accessible": null,
                                 "lifecycle-state": "ACTIVE",
                                 "name": "ROOT",
                                 "time-created": null
                                }]' <<< "$v_fout")
    echo "${v_fout}"
  fi
}

function jsonAudEvents ()
{
  ##########
  # This function will get your audit info desired range and split it in chunks of 1 day.
  # Then it will redirect the call to jsonAllCompart.
  ##########

  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 0 ] || { echoError "${FUNCNAME[0]} needs 0 parameter"; return 1; }
  local v_out v_fout v_jq_filter v_oci_audqry v_search v_ret
  local v_start_epoch v_end_epoch v_jump v_next_epoch_start v_next_date_start v_next_epoch_end v_next_date_end
  local v_temp_conc_fdr v_temp_conc_file v_file_counter

  v_jump=$((3600*24*1)) # Jump 1 day

  v_start_epoch=$(ConvYMDToEpoch ${v_start_time})
  v_end_epoch=$(ConvYMDToEpoch ${v_end_time})

  # If there is a temp folder, keep results to concatenate in 1 shoot
  if [ -n "${v_tmpfldr}" ]
  then
    v_temp_conc_fdr="${v_tmpfldr}/tempConc"
    v_temp_conc_file="${v_temp_conc_fdr}/final.json" # To avoid: Segmentation Fault
    rm -rf "${v_temp_conc_fdr}"
    mkdir "${v_temp_conc_fdr}"
  fi

  v_file_counter=1

  v_next_epoch_start=${v_start_epoch}
  v_next_date_start=$(ConvEpochToYMDhms ${v_next_epoch_start})
  v_next_epoch_end=$((${v_next_epoch_start}+${v_jump}))
  [ $v_next_epoch_end -ge ${v_end_epoch} ] && v_next_epoch_end=${v_end_epoch}
  v_next_date_end=$(ConvEpochToYMDhms ${v_next_epoch_end})

  v_jq_filter='{data:[.data[] | select(.data.request.action != "GET")]}'
  # v_jq_filter='."opc-next-page" as $np | {data:[.data[] | select(."request-action" != "GET")] , "opc-next-page": $np}'

  v_oci_audqry="audit event list --all"
  #v_oci_audqry="audit event list --all --stream-output"
  #v_oci_audqry="audit event list"

  while true
  do
    v_search="${v_oci_audqry} ${v_next_date_start}Z ${v_next_date_end}Z ALL_COMP"
    [ -n "${v_region}" ] && v_search="${v_region} ${v_search}"
    # Will first try to get the output from the historical zip. If can't find it, will call the json generator for all compartments.
    v_out=$(getFromHist "${v_search}") && v_ret=$? || v_ret=$?
    if [ $v_ret -ne 0 ]
    then
      # Run
      set +e
      v_out=$(jsonAllCompart "${v_oci_audqry} --start-time "${v_next_date_start}Z" --end-time "${v_next_date_end}Z"" "${v_jq_filter}")
      v_ret=$?
      set -e
      [ $v_ret -ne 0 -a $v_ret -ne 20 ] && return $v_ret # Will only continue if return code is 0 or 20 (20=some compartment had an error)
      if [ $v_ret -eq 0 ]
      then
        create_lock_or_wait
        (putOnHist "${v_search}" "${v_out}") || true
        remove_lock
      fi
    else
      echoDebug "Got \"${v_search}\" from Zip Hist."
    fi
    # If there is a temp folder, keep results to concatenate in 1 shoot
    if [ -n "${v_tmpfldr}" ]
    then
      cat > "${v_temp_conc_fdr}/${v_file_counter}.json" <<< "$v_out"
      ((v_file_counter++))
    else
      [ ${#v_out} -ne 0 ] && v_fout=$(jsonConcatData "$v_fout" "$v_out")
    fi
    # Prepare for next loop
    v_next_epoch_start=${v_next_epoch_end} # Next second = Next day
    [ ${v_next_epoch_start} -ge ${v_end_epoch} ] && break
    v_next_date_start=$(ConvEpochToYMDhms ${v_next_epoch_start})
    v_next_epoch_end=$((${v_next_epoch_start}+${v_jump}))
    [ $v_next_epoch_end -ge ${v_end_epoch} ] && v_next_epoch_end=${v_end_epoch}
    v_next_date_end=$(ConvEpochToYMDhms ${v_next_epoch_end})
  done

  if [ -n "${v_tmpfldr}" ]
  then
    # To avoid: Argument list too long
    find "${v_temp_conc_fdr}" -name "*.json" -type f -exec cat {} + > "${v_temp_conc_fdr}"/all_json.concat
    ${v_jq} -c 'reduce inputs as $i (.; .data += $i.data)' "${v_temp_conc_fdr}"/all_json.concat > "${v_temp_conc_file}"
    ${v_jq} '.' "${v_temp_conc_file}"
    rm -rf "${v_temp_conc_fdr}"
  else
    [ ${#v_fout} -ne 0 ] && ${v_jq} '.' <<< "${v_fout}"
  fi

  return 0
}

function jsonAllCompart ()
{
  ##########
  # This function will get the oci command and pass to jsonSimple.
  # However, it will loop over all available containers and concatenate the output.
  # Return code: 0 = OK for all. | 20 = Some compartment with error. | Any other = error.
  ##########

  set -eo pipefail # Exit if error in any call.
  set ${v_dbgflag} # Enable Debug
  [ "$#" -eq 2 -a "$1" != ""  -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_out v_fout l_itens v_item v_ret v_ret_final
  v_arg1="$1" # Main oci call
  v_arg2="$2" # JQ Filter clause

  v_ret_final=0 
  l_itens=$(IAM-Comparts | ${v_jq} -r '.data[].id')

  for v_item in $l_itens
  do
    set +e
    v_out=$(jsonSimple "${v_arg1} --compartment-id $v_item" "${v_arg2}")
    v_ret=$?
    set -e
    [ $v_ret -ne 0 ] && v_ret_final=20 # Try next compartment if one fails and set return code to 20.
    v_fout=$(jsonConcatData "$v_fout" "$v_out")
  done
  [ -z "$v_fout" ] || echo "${v_fout}"
  return ${v_ret_final}
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
  [ -n "${v_region}" ] && v_search="${v_region} ${v_arg1}" || v_search="${v_arg1}"
  v_out=$(getFromHist "${v_search}") && v_ret=$? || v_ret=$?
  if [ $v_ret -ne 0 ]
  then
    echoDebug "${v_oci} ${v_arg1}"
    if [ -n "${v_tmpfldr}" ]
    then
      b_out=$(set +x; callOCI "${v_arg1}" "${v_arg2}" 2> ${v_tmpfldr}/oci.err) && b_ret=$? || b_ret=$?
      b_err=$(<${v_tmpfldr}/oci.err)
      rm -f ${v_tmpfldr}/oci.err
    else
      # This crasy string will store the stdout in "b_out", stderr in "b_err" and ret in "b_ret"
      # https://stackoverflow.com/questions/13806626/capture-both-stdout-and-stderr-in-bash
      set +x
      eval "$({ b_err=$({ b_out=$( callOCI "${v_arg1}" "${v_arg2}"); b_ret=$?; } 2>&1; declare -p b_out b_ret >&2); declare -p b_err; } 2>&1)"
      set ${v_dbgflag}
    fi
    [ "${b_out}" == '{"data":[]}' ] && b_out='' # In case it is empty data, clean it for space savings.
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
      # [ -z "${b_err}" ] && putOnHist "${v_search}" "${v_out}" || true
      create_lock_or_wait
      putOnHist "${v_search}" "${v_out}" || true
      remove_lock
    else
      return $b_ret
    fi
  else
    echoDebug "Got \"${v_search}\" from Zip Hist."      
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

################################################
################# OPTION LIST ##################
################################################

# Structure:
# 1st - Json Function Name.
# 2nd - Json Target File Name. Used when ALL parameter is passed to the shell.
# 3rd - Function to call. Can be one off the generics above or a custom one.
# 4th - OCI command line to be executed.

# DON'T REMOVE/CHANGE THOSE COMMENTS. THEY ARE USED TO GENERATE DYNAMIC FUNCTIONS

# BEGIN DYNFUNC
# IAM-RegionSub,oci_iam_region-subscription.json,jsonSimple,"iam region-subscription list" "."
# IAM-Comparts,oci_iam_compartment.json,jsonCompartments
# Audit-Events,oci_audit_event.json,jsonAudEvents
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
            (${c_subfunc} ${c_param} > \${v_tmpfldr}/.${c_fname})
            c_ret=\$?
            cat \${v_tmpfldr}/.${c_fname}
            return \${c_ret}
          }"
  fi
done 3< <(echo "$v_func_list")

function stopIfProcessed ()
{
  ##########
  # In case there is already a file generated for a given dynamic function for the current run, will reuse it instead of running the whole flow again.
  ##########

  # Don't put set -e here.
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
  ##########
  # In case "ALL" as passed as argument, this function will execute all existing dynamic functions and zip them together.
  ##########

  [ "$#" -eq 2 -a "$1" != "" -a "$2" != "" ] || { echoError "${FUNCNAME[0]} needs 2 parameters"; return 1; }
  local v_arg1 v_arg2 v_ret
  v_arg1="$1"
  v_arg2="$2"
  [ -z "${v_region}" ] && echo "Processing \"${v_arg2}\"." || echo "Processing \"${v_arg2}\" in ${v_region}."
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
  ##########
  # Clean folder where current execution temporary files are placed.
  ##########

  [ -n "${v_tmpfldr}" ] && rm -f "${v_tmpfldr}"/.*.json   2>&- || true
  return 0
}

function uncompressHist ()
{
  ##########
  # Uncompress files from previous execution into v_hist_folder path to be used by getFromHist function.
  ##########

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
  ##########
  # Clean folder where current history files will be placed.
  ##########

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
  if ! ( grep -q -F "start-time" <<< "${v_arg1}" && grep -q -F "end-time" <<< "${v_arg1}" )
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
    # [ ! -r "${v_hist_folder}/${v_file}" ] && return 1
    echo "${v_arg2}" > "${v_hist_folder}/${v_file}"
  fi
  ${v_zip} -qj ${HIST_ZIP_FILE} "${v_hist_folder}/${v_list}"
  ${v_zip} -qj ${HIST_ZIP_FILE} "${v_hist_folder}/${v_file}"
  return 0
}

function create_lock_or_wait ()
{
  [ -z "${HIST_ZIP_FILE}" -o -z "${v_region}" ] && return 0
  local wait_time=1
  local v_ret
  #echoDebug "${v_region} - ZIP Locking."
  while true
  do
    mkdir "${HIST_ZIP_FILE}.lock.d" 2>&- && v_ret=$? || v_ret=$?
    [ $v_ret -eq 0 ] && break
    sleep $wait_time
    #echoDebug "${v_region} - ZIP Waiting."
  done
  #echoDebug "${v_region} - ZIP Locked."
  return 0
}

function remove_lock ()
{
  [ -z "${HIST_ZIP_FILE}" -o -z "${v_region}" ] && return 0
  #echoDebug "${v_region} - ZIP Unlocking."
  rmdir "${HIST_ZIP_FILE}.lock.d"
  #echoDebug "${v_region} - ZIP Unlocked."
  return 0
}

function main ()
{
  ##########
  # This the main function. Will execute one given parameter option or loop over all possibilities and zip the output.
  ##########

  # If ALL or ALL_REGIONS, loop over all defined options.
  local c_line c_name c_file
  if [ "${v_param1}" != "ALL" -a "${v_param1}" != "ALL_REGIONS" ]
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
    [ "${v_param1}" == "ALL_REGIONS" -a -f "${v_this_script%.*}.log" ] && ${v_zip} -qm "$v_outfile" "${v_this_script%.*}.log"
    v_ret=0
  fi
}

# Start code execution.
[ "${v_param1}" == "ALL_REGIONS" -o "${v_param1}" == "ALL" ] && DEBUG=1

echoDebug "BEGIN"
cleanTmpFiles
uncompressHist
if [ "${v_param1}" == "ALL_REGIONS" ]
then
  l_regions=$(IAM-RegionSub | ${v_jq} -r '.data[]."region-name"')
  v_oci_orig="$v_oci"
  v_tmpfldr_base="${v_tmpfldr}"
  v_outfile_pref="${v_this_script%.*}_$(date '+%Y%m%d%H%M%S')"
  v_hist_folder_orig="${v_hist_folder}"
  v_hist_folder="../${v_hist_folder_orig}"
  for v_region in $l_regions
  do
    echo "Starting region ${v_region}."
    v_oci="${v_oci_orig} --region ${v_region}"
    v_outfile="${v_outfile_pref}_${v_region}.zip"
    [ -n "${v_tmpfldr_base}" ] && { v_tmpfldr="${v_tmpfldr_base}/${v_region}"; mkdir "${v_tmpfldr}"; }
    mkdir ${v_region} 2>&- || true
    cd ${v_region}
    main &
    v_pids+=(${v_region}::$!)
    cd ..
  done
  for v_reg_ind in "${v_pids[@]}"
  do
      v_region="${v_reg_ind%%::*}"
      wait ${v_reg_ind##*::}
      mv ${v_region}/* ./
      rmdir ${v_region}
      [ -n "${v_tmpfldr_base}" ] && { v_tmpfldr="${v_tmpfldr_base}/${v_region}"; cleanTmpFiles; rmdir "${v_tmpfldr}" || true; }
  done
  v_hist_folder="${v_hist_folder_orig}"
  v_tmpfldr="${v_tmpfldr_base}"
else
  main
fi
cleanHist
cleanTmpFiles
echoDebug "END"

[ -f "${v_this_script%.*}.log" -a "${v_param1}" == "ALL_REGIONS" ] && { mv "${v_this_script%.*}.log" "${v_this_script%.*}.full.log"; ${v_zip} -qm "$v_outfile" "${v_this_script%.*}.full.log"; }
[ -f "${v_this_script%.*}.log" -a -f "$v_outfile" ] && ${v_zip} -qm "$v_outfile" "${v_this_script%.*}.log"

[ -n "${v_tmpfldr}" ] && rmdir ${v_tmpfldr} 2>&- || true

exit ${v_ret}
###