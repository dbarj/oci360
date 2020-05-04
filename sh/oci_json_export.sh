#!/bin/bash
#************************************************************************
#
#   oci_json_export.sh - Export all Oracle Cloud Infrastructure
#   metadata information into JSON files.
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
# Version 1.24
#************************************************************************
set -e

# Define paths for oci-cli and jq or put them on $PATH. Don't use relative PATHs in the variables below.
v_oci="oci"
v_jq="jq"

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

# If DEBUG variable is undefined, change to 0.
[[ "${DEBUG}" == "" ]] && DEBUG=0
[ ! -z "${DEBUG##*[!0-9]*}" ] || DEBUG=0

if [ -z "${BASH_VERSION}" ]
then
  >&2 echo "Script must be executed in BASH shell."
  exit 1
fi

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM

function echoError ()
{
  (>&2 echo "$1")
}

function echoDebug ()
{
  local v_debug_lvl="$2"
  local v_filename="${v_this_script%.*}.log"
  [ -z "${v_debug_lvl}" ] && v_debug_lvl=1
  [ $DEBUG -ge ${v_debug_lvl} ] && echo "$(date '+%Y%m%d%H%M%S'): $1" >> ${v_filename}
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

v_check=$(funcCheckValueInRange "$v_param1" "$v_valid_opts") && v_ret=$? || v_ret=$?

if [ "$v_check" == "N" -o $v_ret -ne 0 ]
then
  echoError "Usage: ${v_this_script} <option>"
  echoError ""
  echoError "<option> - Execution Scope."
  echoError ""
  echoError "Valid <option> values are:"
  echoError "- ALL         - Execute json export for ALL possible options and compress output in a zip file."
  echoError "- ALL_REGIONS - Same as ALL, but run for all tenancy's subscribed regions."
  echoError "$(funcPrintRange "$v_opt_list")"
  echoError ""
  echoError "PS: it is possible to export the following variables to add/remove options when ALL/ALL_REGIONS are used."
  echoError "OCI_JSON_INCLUDE - Comma separated list of items to include."
  echoError "OCI_JSON_EXCLUDE - Comma separated list of items to exclude."
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
  if [ "${v_param1}" == "ALL" -o "${v_param1}" == "ALL_REGIONS" ]
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

if ! $(which timeout >&- 2>&-)
then
  function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
fi

################################################
############### CUSTOM FUNCTIONS ###############
################################################

function jsonCompartments ()
{
  set -e # Exit if error in any call.
  local v_fout v_tenancy_id
  v_fout=$(jsonSimple "iam compartment list --all --compartment-id-in-subtree true")
  ## Remove DELETED compartments to avoid query errors
  if [ -n "$v_fout" ]
  then
    v_fout=$(${v_jq} '{data:[.data[] | select(."lifecycle-state" != "DELETED")]}' <<< "${v_fout}")
    v_tenancy_id=$(${v_jq} -r '[.data[]."compartment-id"] | unique | .[] | select(startswith("ocid1.tenancy.oc1."))' <<< "${v_fout}")
    ## Add root:
    v_fout=$(${v_jq} '.data += [{
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

function jsonShapes ()
{
  set -e # Exit if error in any call.
  local v_fout
  v_fout=$(jsonAllCompartAddTag "compute shape list --all")
  ## Remove Duplicates
  [ -z "$v_fout" ] || v_fout=$(${v_jq} '.data | unique | {data : .}' <<< "${v_fout}")
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonBkpPolAssign ()
{
  set -e # Exit if error in any call.
  local v_out v_fout
  v_fout=$(jsonGenericMaster "bv volume-backup-policy-assignment get-volume-backup-policy-asset-assignment" "BV-Volumes" "id:asset-id" "jsonSimple")
  v_out=$(jsonGenericMaster "bv volume-backup-policy-assignment get-volume-backup-policy-asset-assignment" "BV-BVolumes" "id:asset-id" "jsonSimple")
  v_fout=$(jsonConcat "$v_fout" "$v_out")
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonPublicIPs ()
{
  set -e # Exit if error in any call.
  local v_out v_fout
  v_fout=$(jsonAllCompart "network public-ip list --scope REGION --all")
  v_out=$(jsonAllAD "network public-ip list --scope AVAILABILITY_DOMAIN --all")
  v_fout=$(jsonConcat "$v_fout" "$v_out")
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonImages ()
{
  set -e # Exit if error in any call.
  local v_fout l_instImages l_images l_diff v_image v_out l_baseImages
  ## Get Images.
  v_fout=$(jsonAllCompart "compute image list --all")
  ## Get also Images used By Instaces.
  l_instImages=$(Comp-Instances | ${v_jq} -r '.data[]."image-id"' | sort -u)
  l_images=$(${v_jq} -r '.data[]."id"' <<< "${v_fout}")
  l_diff=$(grep -F -x -v -f <(echo "$l_images") <(echo "$l_instImages")) || l_diff=""
  for v_image in $l_diff
  do
    v_out=$(jsonSimple "compute image get --image-id ${v_image}")
    v_fout=$(jsonConcat "$v_fout" "$v_out")
  done
  ## Get also Base Images of Images.
  l_baseImages=$(${v_jq} -r '.data[] | select(."base-image-id" != null) | ."base-image-id"' <<< "${v_fout}" | sort -u)
  l_images=$(${v_jq} -r '.data[]."id"' <<< "${v_fout}")
  l_diff=$(grep -F -x -v -f <(echo "$l_images") <(echo "$l_baseImages")) || l_diff=""
  for v_image in $l_diff
  do
    v_out=$(jsonSimple "compute image get --image-id ${v_image}")
    v_fout=$(jsonConcat "$v_fout" "$v_out")
  done
  ## Remove Duplicates
  [ -z "$v_fout" ] || v_fout=$(${v_jq} '.data | unique | {data : .}' <<< "${v_fout}")
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonVolsKeys ()
{
  set -e # Exit if error in any call.
  local l_vols v_vol v_out v_fout
  v_fout=""
  l_vols=$(BV-Volumes | ${v_jq} -r '.data[] | select(."kms-key-id" != null) | ."id"')
  for v_vol in $l_vols
  do
    v_out=$(jsonSimple "bv volume-kms-key get --volume-id ${v_vol}")
    v_fout=$(jsonConcat "$v_fout" "$v_out")
  done
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonBVolsKeys ()
{
  set -e # Exit if error in any call.
  local l_vols v_vol v_out v_fout
  v_fout=""
  l_vols=$(BV-BVolumes | ${v_jq} -r '.data[] | select(."kms-key-id" != null) | ."id"')
  for v_vol in $l_vols
  do
    v_out=$(jsonSimple "bv boot-volume-kms-key get --boot-volume-id ${v_vol}")
    v_fout=$(jsonConcat "$v_fout" "$v_out")
  done
  [ -z "$v_fout" ] || echo "${v_fout}"
}

################################################
############## GENERIC FUNCTIONS ###############
################################################

## jsonSimple           -> Simply run the parameter with oci-cli.
## jsonAllCompart       -> Run parameter for all container-ids.
## jsonAllCompartAddTag -> Same as before, but also add container-id tag in json output.
## jsonAllAD            -> Run parameter for all availability-domains and container-ids.
## jsonAllVCN           -> Run parameter for all vcn-ids and container-ids.
## jsonConcat           -> Concatenate 2 Jsons data vectors parameters into 1.

function jsonSimple ()
{
  # Call oci-cli with all provided args in $1.
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1 v_out
  v_arg1="$1"
  echoDebug "${v_oci} ${v_arg1}"
  v_out=$(timeout ${v_oci_timeout} ${v_oci} ${v_arg1})
  #v_out=$(${v_oci} ${v_arg1})
  [ -z "$v_out" ] || echo "${v_out}"
}

function jsonSimple ()
{
  # Call oci-cli with all provided args in $1.
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_arg1 v_next_page v_fout v_out v_ret
  v_arg1="$1"
  echoDebug "${v_oci} ${v_arg1}"
  v_fout=$(eval "timeout ${v_oci_timeout} ${v_oci} ${v_arg1}") && v_ret=$? || v_ret=$?
  if [ $v_ret -ne 0 ]
  then
    echoError "## Command Failed:"
    echoError "${v_oci} ${v_arg1}"
    echoError "########"
  elif [ -n "$v_fout" ]
  then
    v_next_page=$(${v_jq} -rc '."opc-next-page"' <<< "${v_fout}")
    [ "${v_next_page}" == "null" ] || v_fout=$(${v_jq} '.data | {data : .}' <<< "$v_fout") # Remove Next-Page Tag if it has one.
    while [ -n "${v_next_page}" -a "${v_next_page}" != "null" ]
    do
      echoDebug "${v_oci} ${v_arg1} --page ${v_next_page}"
      v_out=$(eval "${v_oci} ${v_arg1} --page ${v_next_page}")
      v_next_page=$(${v_jq} -rc '."opc-next-page"' <<< "${v_out}")
      [ -z "$v_out" -o "${v_next_page}" == "null" ] || v_out=$(${v_jq} '.data | {data : .}' <<< "$v_out") # Remove Next-Page Tag if it has one.
      v_fout=$(jsonConcat "$v_fout" "$v_out")
    done
    echo "${v_fout}"
  fi
}

function jsonRootCompart ()
{
  # Call oci-cli for root compartment only.
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  local v_tenancy_id
  v_tenancy_id=$(IAM-Comparts | ${v_jq} -r '.data[]."id" | select(startswith("ocid1.tenancy.oc1."))')
  jsonSimple "$1 --compartment-id ${v_tenancy_id}"
}

function jsonAllCompart ()
{
  # Call oci-cli for all existent compartments.
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  jsonGenericMaster "$1" "IAM-Comparts" "id:compartment-id" "jsonSimple"
}

function jsonAllCompartAddTag ()
{
  # Call oci-cli for all existent compartments. In the end, add compartment-id tag to json output.
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  jsonGenericMasterAdd "$1" "IAM-Comparts" "id:compartment-id:compartment-id" "jsonSimple"
}

function jsonAllAD ()
{
  # Call oci-cli for a combination of all existent Compartments x ADs..
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  jsonGenericMaster "$1" "IAM-ADs" "name:availability-domain" "jsonAllCompart"
}

function jsonAllVCN ()
{
  # Call oci-cli for all existent VCNs.
  set -e # Exit if error in any call.
  [ "$#" -eq 1 -a "$1" != "" ] || { echoError "${FUNCNAME[0]} needs 1 parameter"; return 1; }
  jsonGenericMaster "$1" "Net-VCNs" "id:vcn-id" "jsonAllCompart"
}

function jsonGenericMaster ()
{
  set -e # Exit if error in any call.
  [ "$#" -eq 4 ] || { echoError "${FUNCNAME[0]} needs 4 parameters"; return 1; }
  local v_arg1 v_arg2 v_arg3 v_arg4 v_out v_fout l_itens v_item v_arg_vect v_param_vect v_tags v_maps v_params v_i
  v_arg1="$1" # Main oci call
  v_arg2="$2" # Subfunction 1 - FuncName
  v_arg3="$3" # Subfunction 1 - Vector (Tag1 to get, Param1, Tag2 to get, Param2, ...)
  v_arg4="$4" # Subfunction 2 - FuncName

  v_param_vect=() # Vector to hold v_arg3 odd entries.
  v_arg_vect=(${v_arg3//:/ })

  for v_i in "${!v_arg_vect[@]}"
  do
    [ $((v_i%2)) -eq 0 ] && v_tags="${v_tags}.\"${v_arg_vect[v_i]}\","
    [ $((v_i%2)) -ne 0 ] && v_param_vect+=(${v_arg_vect[v_i]})
  done
  v_tags=$(sed 's/,$//' <<< "$v_tags")
  v_maps=$(sed 's/^.//; s/,./,/g' <<< "$v_tags")
  # l_itens=$(${v_arg2} | ${v_jq} -r '.data[] | '$v_tags' ')
  echoDebug "${v_arg2} | ${v_jq} -r '{data} | .data |= map({$v_maps}) | .data | unique | .[] | $v_tags '" 2
  l_itens=$(${v_arg2} | ${v_jq} -r '{data} | .data |= map({'$v_maps'}) | .data | unique | .[] | '$v_tags' ')
  v_i=0

  for v_item in $l_itens
  do
    # Dont add item if value is null.
    if [ "$v_item" != "null" ]
    then
      v_params="${v_params}--${v_param_vect[v_i]} $v_item "
    else
      echoDebug "Removing null \"${v_param_vect[v_i]}\"." 2
    fi
    v_i=$((v_i+1))
    if [ $v_i -eq ${#v_param_vect[@]} ]
    then
      v_params=$(sed 's/ $//' <<< "$v_params")
      v_out=$(${v_arg4} "${v_arg1} ${v_params}")
      v_fout=$(jsonConcat "$v_fout" "$v_out")
      v_i=0
      v_params=""
    fi
  done
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonGenericMasterAdd ()
{
  set -e # Exit if error in any call.
  [ "$#" -eq 4 ] || { echoError "${FUNCNAME[0]} needs 4 parameters"; return 1; }
  local v_arg1 v_arg2 v_arg3 v_arg4 v_out v_fout l_itens v_item v_arg_vect v_param_vect v_tags v_maps v_params v_i v_chk v_newit_vect v_newits 
  v_arg1="$1" # Main oci call
  v_arg2="$2" # Subfunction 1 - FuncName
  v_arg3="$3" # Subfunction 1 - Vector (Tag1 to get, Param1, New Tag Name 1, Tag2 to get, Param2, New Tag Name 2, ...)
  v_arg4="$4" # Subfunction 2 - FuncName

  v_param_vect=() # Vector to hold v_arg3 every 1/3 entry.
  v_newit_vect=() # Vector to hold v_arg3 every 3/3 entry.
  v_arg_vect=(${v_arg3//:/ })

  for v_i in "${!v_arg_vect[@]}"
  do
    [ $((v_i%3)) -eq 0 ] && v_tags="${v_tags}.\"${v_arg_vect[v_i]}\","
    [ $((v_i%3)) -eq 1 ] && v_param_vect+=(${v_arg_vect[v_i]})
    [ $((v_i%3)) -eq 2 ] && v_newit_vect+=(${v_arg_vect[v_i]})
  done

  v_tags=$(sed 's/,$//' <<< "$v_tags")
  v_maps=$(sed 's/^.//; s/,./,/g' <<< "$v_tags")
  # l_itens=$(${v_arg2} | ${v_jq} -r '.data[] | '$v_tags' ')
  echoDebug "${v_arg2} | ${v_jq} -r '{data} | .data |= map({$v_maps}) | .data | unique | .[] | $v_tags '" 2
  l_itens=$(${v_arg2} | ${v_jq} -r '{data} | .data |= map({'$v_maps'}) | .data | unique | .[] | '$v_tags' ')
  v_i=0

  for v_item in $l_itens
  do
    # Dont add item if value is null.
    if [ "$v_item" != "null" ]
    then
      v_params="${v_params}--${v_param_vect[v_i]} $v_item "
      v_newits="${v_newits}\"${v_newit_vect[v_i]}\":\"$v_item\","
    else
      echoDebug "Removing null \"${v_param_vect[v_i]}\"." 2
    fi
    v_i=$((v_i+1))
    if [ $v_i -eq ${#v_param_vect[@]} ]
    then
      v_params=$(sed 's/ $//' <<< "$v_params")
      v_newits=$(sed 's/,$//' <<< "$v_newits")
      v_out=$(${v_arg4} "${v_arg1} ${v_params}")
      v_chk=$(${v_jq} '.data // empty' <<< "$v_out" | jq -r 'if type=="array" then "yes" else "no" end')
      [ "$v_chk" == "no" ] && v_out=$(${v_jq} '.data += {'${v_newits}'}' <<< "$v_out")
      [ "$v_chk" == "yes" ] && v_out=$(${v_jq} '.data[] += {'${v_newits}'}' <<< "$v_out")
      [ -z "$v_chk" ] || v_fout=$(jsonConcat "$v_fout" "$v_out")
      v_i=0
      v_params=""
      v_newits=""
    fi
  done
  [ -z "$v_fout" ] || echo "${v_fout}"
}

function jsonConcat ()
{
  set -e # Exit if error in any call.
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
  v_chk_json=$(${v_jq} -r '.data | if type=="array" then "yes" else "no" end' <<< "$v_arg1")
  [ "${v_chk_json}" == "no" ] && v_arg1=$(${v_jq} '.data | {"data":[.]}' <<< "$v_arg1")
  v_chk_json=$(${v_jq} -r '.data | if type=="array" then "yes" else "no" end' <<< "$v_arg2")
  [ "${v_chk_json}" == "no" ] && v_arg2=$(${v_jq} '.data | {"data":[.]}' <<< "$v_arg2")
  ${v_jq} 'reduce inputs as $i (.; .data += $i.data)' <(echo "$v_arg1") <(echo "$v_arg2")
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
# Budget-Data,oci_budget_data.json,jsonAllCompart,"budgets budget list --all"
# BV-BVBackups,oci_bv_boot-volume-backup.json,jsonAllCompart,"bv boot-volume-backup list --all"
# BV-BVKey,oci_bv_boot-volume-kms-key.json,jsonBVolsKeys
# BV-BVolumes,oci_bv_boot-volume.json,jsonAllAD,"bv boot-volume list --all"
# BV-Backups,oci_bv_backup.json,jsonAllCompart,"bv backup list --all"
# BV-BkpPolicy,oci_bv_volume-backup-policy.json,jsonSimple,"bv volume-backup-policy list --all"
# BV-BkpPolicyAssign,oci_bv_volume-backup-policy-assignment.json,jsonBkpPolAssign
# BV-VolGroup,oci_bv_volume-group.json,jsonAllCompart,"bv volume-group list --all"
# BV-VolGroupBkp,oci_bv_volume-group-backup.json,jsonAllCompart,"bv volume-group-backup list --all"
# BV-VolumeKey,oci_bv_volume-kms-key.json,jsonVolsKeys
# BV-Volumes,oci_bv_volume.json,jsonAllCompart,"bv volume list --all"
# Comp-BVAttachs,oci_compute_boot-volume-attachment.json,jsonAllAD,"compute boot-volume-attachment list --all"
# Comp-ConsHist,oci_compute_console-history.json,jsonAllCompart,"compute console-history list --all"
# Comp-DedicatedVM,oci_compute_dedicated-vm-host.json,jsonAllCompart,"compute dedicated-vm-host list --all"
# Comp-DedicatedInst,oci_compute_dedicated-vm-host-instance.json,jsonAllCompart,"compute dedicated-vm-host list --all"
# Comp-Devices,oci_compute_device.json,"jsonGenericMasterAdd","compute device list-instance --all" "Comp-Instances" "id:instance-id:instance-id" "jsonSimple"
# Comp-Images,oci_compute_image.json,jsonImages
# Comp-InstConsConns,oci_compute_instance-console-connection.json,jsonAllCompart,"compute instance-console-connection list --all"
# Comp-Instances,oci_compute_instance.json,jsonAllCompart,"compute instance list --all"
# Comp-PicAgrees,oci_compute_pic_agreements.json,jsonGenericMaster,"compute pic agreements get" "Comp-PicVersions" "listing-id:listing-id:listing-resource-version:resource-version" "jsonSimple"
# Comp-PicListing,oci_compute_pic_listing.json,jsonSimple,"compute pic listing list --all"
# Comp-PicSubs,oci_compute_pic_subscription.json,jsonAllCompart,"compute pic subscription list --all"
# Comp-PicVersions,oci_compute_pic_version.json,jsonGenericMaster,"compute pic version list --all" "Comp-PicListing" "listing-id:listing-id" "jsonSimple"
# Comp-Shapes,oci_compute_shape.json,jsonShapes
# Comp-VnicAttachs,oci_compute_vnic-attachment.json,jsonAllCompart,"compute vnic-attachment list --all"
# Comp-VolAttachs,oci_compute_volume-attachment.json,jsonAllCompart,"compute volume-attachment list --all"
# CompMgt-InstConfList,oci_compute-management_instance-configuration_list.json,jsonAllCompart,"compute-management instance-configuration list --all"
# CompMgt-InstConf,oci_compute-management_instance-configuration.json,jsonGenericMaster,"compute-management instance-configuration get" "CompMgt-InstConfList" "id:instance-configuration-id" "jsonSimple"
# CompMgt-InstPoolList,oci_compute-management_instance-pool_list.json,jsonAllCompart,"compute-management instance-pool list --all"
# CompMgt-InstPool,oci_compute-management_instance-pool.json,jsonGenericMaster,"compute-management instance-pool get" "CompMgt-InstPoolList" "id:instance-pool-id" "jsonSimple"
# CompMgt-InstPoolInsts,oci_compute-management_instance-pool_list-instances.json,jsonGenericMaster,"compute-management instance-pool list-instances" "CompMgt-InstPoolList" "id:instance-pool-id:compartment-id:compartment-id" "jsonSimple"
# DB-AutDB,oci_db_autonomous-database.json,jsonAllCompart,"db autonomous-database list --all"
# DB-AutDBBkp,oci_db_autonomous-database-backup.json,jsonAllCompart,"db autonomous-database-backup list --all"
# DB-AutDW,oci_db_autonomous-data-warehouse.json,jsonAllCompart,"db autonomous-data-warehouse list --all"
# DB-AutDWBkp,oci_db_autonomous-data-warehouse-backup.json,jsonAllCompart,"db autonomous-data-warehouse-backup list --all"
# DB-Backup,oci_db_backup.json,jsonAllCompart,"db backup list --all"
# DB-DGAssoc,oci_db_data-guard-association.json,jsonGenericMaster,"db data-guard-association list --all" "DB-Database" "id:database-id" "jsonSimple"
# DB-Database,oci_db_database.json,jsonGenericMaster,"db database list" "DB-System" "id:db-system-id:compartment-id:compartment-id" "jsonSimple"
# DB-ExtBkpJob,oci_db_external-backup-job.json,jsonGenericMaster,"db external-backup-job get" "DB-Backup" "id:backup-id" "jsonSimple"
# DB-Nodes,oci_db_node.json,jsonGenericMaster,"db node list --all" "DB-System" "id:db-system-id:compartment-id:compartment-id" "jsonSimple"
# DB-Patch-ByDB,oci_db_patch_by-database.json,jsonGenericMaster,"db patch list by-database --all" "DB-Database" "id:database-id" "jsonSimple"
# DB-Patch-ByDS,oci_db_patch_by-db-system.json,jsonGenericMaster,"db patch list by-db-system --all" "DB-System" "id:db-system-id" "jsonSimple"
# DB-PatchHist-ByDB,oci_db_patch-history_by-database.json,jsonGenericMaster,"db patch-history list by-database" "DB-Database" "id:database-id" "jsonSimple"
# DB-PatchHist-ByDS,oci_db_patch-history_by-db-system.json,jsonGenericMaster,"db patch-history list by-db-system" "DB-System" "id:db-system-id" "jsonSimple"
# DB-System,oci_db_system.json,jsonAllCompart,"db system list --all"
# DB-SystemShape,oci_db_system-shape.json,jsonGenericMasterAdd,"db system-shape list --all" "IAM-ADs" "name:availability-domain:availability-domain" "jsonAllCompartAddTag"
# DB-Version,oci_db_version.json,jsonAllCompartAddTag,"db version list --all"
# DB-ExaInfra,oci_db_exadata-infrastructure.json,jsonAllCompart,"db exadata-infrastructure list --all"
# DNS-Zones,oci_dns_zone.json,jsonAllCompart,"dns zone list --all"
# Email-Senders,oci_email_sender.json,jsonAllCompart,"email sender list --all"
# Email-Supps,oci_email_suppression.json,jsonGenericMaster,"email suppression list --all" "IAM-Comparts" "compartment-id:compartment-id" "jsonSimple"
# FS-ExpSets,oci_fs_export-set.json,jsonAllAD,"fs export-set list --all"
# FS-Exports,oci_fs_export.json,jsonAllCompartAddTag,"fs export list --all"
# FS-ExpDetails,oci_fs_export_details.json,jsonGenericMaster,"fs export get" "FS-Exports" "id:export-id" "jsonSimple"
# FS-FileSystems,oci_fs_file-system.json,jsonAllAD,"fs file-system list --all"
# FS-MountTargets,oci_fs_mount-target.json,jsonAllAD,"fs mount-target list --all"
# FS-Snapshots,oci_fs_snapshot.json,jsonGenericMaster,"fs snapshot list --all" "FS-FileSystems" "id:file-system-id" "jsonSimple"
# IAM-ADs,oci_iam_availability-domain.json,jsonSimple,"iam availability-domain list"
# IAM-AuthTokens,oci_iam_auth-token.json,jsonGenericMaster,"iam auth-token list" "IAM-Users" "id:user-id" "jsonSimple"
# IAM-AuthPolicies,oci_iam_auth-policies.json,jsonRootCompart,"iam authentication-policy get"
# IAM-Comparts,oci_iam_compartment.json,jsonCompartments
# IAM-CustSecretKeys,oci_iam_customer-secret-key.json,jsonGenericMaster,"iam customer-secret-key list" "IAM-Users" "id:user-id" "jsonSimple"
# IAM-DynGroups,oci_iam_dynamic-group.json,jsonSimple,"iam dynamic-group list --all"
# IAM-FaultDomains,oci_iam_fault-domain.json,jsonAllAD,"iam fault-domain list"
# IAM-Groups,oci_iam_group.json,jsonSimple,"iam group list --all"
# IAM-MFA,oci_iam_mfa-totp-device.json,jsonGenericMasterAdd,"iam mfa-totp-device list --all" "IAM-Users" "id:user-id:user-id" "jsonSimple"
# IAM-NetworkSources,oci_iam_network-sources.json,jsonAllCompart,"iam network-sources list --all"
# IAM-Policies,oci_iam_policy.json,jsonAllCompart,"iam policy list --all"
# IAM-RegionSub,oci_iam_region-subscription.json,jsonSimple,"iam region-subscription list"
# IAM-Regions,oci_iam_region.json,jsonSimple,"iam region list"
# IAM-SMTPCred,oci_iam_smtp-credential.json,jsonGenericMaster,"iam smtp-credential list" "IAM-Users" "id:user-id" "jsonSimple"
# IAM-Tag,oci_iam_tag.json,jsonGenericMaster,"iam tag list --all" "IAM-TagNS" "id:tag-namespace-id" "jsonSimple"
# IAM-TagDefault,oci_iam_tag-default.json,jsonAllCompart,"iam tag-default list --all"
# IAM-TagNS,oci_iam_tag-namespace.json,jsonAllCompart,"iam tag-namespace list --all"
# IAM-Users,oci_iam_user.json,jsonSimple,"iam user list --all"
# IAM-UserGroups,oci_iam_user_groups.json,jsonGenericMasterAdd,"iam user list-groups --all" "IAM-Users" "id:user-id:user-id" "jsonSimple"
# IAM-WorkReqs,oci_iam_work-request.json,jsonAllCompart,"iam work-request list --all"
# Kms-KeyVersions,oci_kms_management_key-version.json,jsonGenericMaster,"kms management key-version list --all" "Kms-Keys" "id:key-id:endpoint:endpoint" "jsonSimple"
# Kms-Keys,oci_kms_management_key.json,jsonGenericMasterAdd,"kms management key list --all" "Kms-Vaults" "management-endpoint:endpoint:endpoint" "jsonAllCompart"
# Kms-Vaults,oci_kms_management_vault.json,jsonAllCompart,"kms management vault list --all"
# LB-Backend,oci_lb_backend.json,jsonGenericMasterAdd,"lb backend list" "LB-BackendSet" "load-balancer-id:load-balancer-id:load-balancer-id:name:backend-set-name:backend-set-name" "jsonSimple"
# LB-BackendHealth,oci_lb_backend-health.json,jsonGenericMasterAdd,"lb backend-health get" "LB-Backend" "load-balancer-id:load-balancer-id:load-balancer-id:backend-set-name:backend-set-name:backend-set-name:name:backend-name:backend-name" "jsonSimple"
# LB-BackendSet,oci_lb_backend-set.json,jsonGenericMasterAdd,"lb backend-set list" "LB-LoadBalancers" "id:load-balancer-id:load-balancer-id" "jsonSimple"
# LB-BackendSetHealth,oci_lb_backend-set-health.json,jsonGenericMasterAdd,"lb backend-set-health get" "LB-BackendSet" "load-balancer-id:load-balancer-id:load-balancer-id:name:backend-set-name:backend-set-name" "jsonSimple"
# LB-Certificates,oci_lb_certificate.json,jsonGenericMasterAdd,"lb certificate list" "LB-LoadBalancers" "id:load-balancer-id:load-balancer-id" "jsonSimple"
# LB-HealthChecker,oci_lb_health-checker.json,jsonGenericMasterAdd,"lb health-checker get" "LB-BackendSet" "load-balancer-id:load-balancer-id:load-balancer-id:name:backend-set-name:backend-set-name" "jsonSimple"
# LB-Hostnames,oci_lb_hostname.json,jsonGenericMasterAdd,"lb hostname list" "LB-LoadBalancers" "id:load-balancer-id:load-balancer-id" "jsonSimple"
# LB-LoadBalancerHealth,oci_lb_load-balancer-health.json,jsonGenericMasterAdd,"lb load-balancer-health get" "LB-LoadBalancers" "id:load-balancer-id:load-balancer-id" "jsonSimple"
# LB-LoadBalancers,oci_lb_load-balancer.json,jsonAllCompart,"lb load-balancer list --all"
# LB-PathRoutes,oci_lb_path-route-set.json,jsonGenericMasterAdd,"lb path-route-set list" "LB-LoadBalancers" "id:load-balancer-id:load-balancer-id" "jsonSimple"
# LB-Policies,oci_lb_policy.json,jsonAllCompartAddTag,"lb policy list --all"
# LB-Protocols,oci_lb_protocol.json,jsonAllCompartAddTag,"lb protocol list --all"
# LB-Shapes,oci_lb_shape.json,jsonAllCompartAddTag,"lb shape list --all"
# LB-WorkReqs,oci_lb_work-request.json,jsonGenericMasterAdd,"lb work-request list" "LB-LoadBalancers" "id:load-balancer-id:load-balancer-id" "jsonSimple"
# Limits-Services,oci_limits_service.json,jsonRootCompart,"limits service list --all"
# Limits-Quotas,oci_limits_quota.json,jsonAllCompartAddTag,"limits quota list --all"
# Limits-Values,oci_limits_value.json,jsonGenericMasterAdd,"limits value list --all" "Limits-Services" "name:service-name:service-name" "jsonRootCompart"
# Limits-ResAvail,oci_limits_res-avail.json,jsonGenericMasterAdd,"limits resource-availability get" "Limits-Values" "name:limit-name:limit-name:service-name:service-name:service-name:availability-domain:availability-domain:availability-domain" "jsonRootCompart"
# Net-Cpe,oci_network_cpe.json,jsonAllCompart,"network cpe list --all"
# Net-CrossConn,oci_network_cross-connect.json,jsonAllCompart,"network cross-connect list --all"
# Net-CrossConnGrp,oci_network_cross-connect-group.json,jsonAllCompart,"network cross-connect-group list --all"
# Net-CrossConnLoc,oci_network_cross-connect-location.json,jsonAllCompart,"network cross-connect-location list --all"
# Net-CrossConnPort,oci_network_cross-connect-port-speed-shape.json,jsonAllCompart,"network cross-connect-port-speed-shape list --all"
# Net-CrossConnStatus,oci_network_cross-connect-status.json,jsonGenericMaster,"network cross-connect-status get" "Net-CrossConn" "id:cross-connect-id" "jsonSimple"
# Net-DhcpOptions,oci_network_dhcp-options.json,jsonAllVCN,"network dhcp-options list --all"
# Net-DrgAttachs,oci_network_drg-attachment.json,jsonAllCompart,"network drg-attachment list --all"
# Net-Drgs,oci_network_drg.json,jsonAllCompart,"network drg list --all"
# Net-FCProviderServices,oci_network_fast-connect-provider-service.json,jsonSimple,"network fast-connect-provider-service list --compartment-id xxx --all"
# Net-InternetGateway,oci_network_internet-gateway.json,jsonAllVCN,"network internet-gateway list --all"
# Net-IpSecConns,oci_network_ip-sec-connection.json,jsonAllCompart,"network ip-sec-connection list --all"
# Net-LocalPeering,oci_network_local-peering-gateway.json,jsonAllVCN,"network local-peering-gateway list --all"
# Net-NatGateway,oci_network_nat-gateway.json,jsonAllCompart,"network nat-gateway list --all"
# Net-PrivateIPs,oci_network_private-ip.json,jsonGenericMaster,"network private-ip list --all" "Net-Subnets" "id:subnet-id" "jsonSimple"
# Net-PublicIPs,oci_network_public-ip.json,jsonPublicIPs
# Net-RemotePeering,oci_network_remote-peering-connection.json,jsonAllCompart,"network remote-peering-connection list --all"
# Net-RouteTables,oci_network_route-table.json,jsonAllVCN,"network route-table list --all"
# Net-SecLists,oci_network_security-list.json,jsonAllVCN,"network security-list list --all"
# Net-ServiceGW,oci_network_service-gateway.json,jsonAllCompart,"network service-gateway list --all"
# Net-Services,oci_network_service.json,jsonSimple,"network service list --all"
# Net-Subnets,oci_network_subnet.json,jsonAllVCN,"network subnet list --all"
# Net-VCNs,oci_network_vcn.json,jsonAllCompart,"network vcn list --all"
# Net-NSGs,oci_network_nsg.json,jsonAllCompart,"network nsg list --all"
# Net-NSGRules,oci_network_nsg_rules.json,jsonGenericMasterAdd,"network nsg rules list --all" "Net-NSGs" "id:nsg-id:nsg-id" "jsonSimple"
# Net-NSGVnics,oci_network_nsg_vnics.json,jsonGenericMasterAdd,"network nsg vnics list --all" "Net-NSGs" "id:nsg-id:nsg-id" "jsonSimple"
# Net-VirtCirc,oci_network_virtual-circuit.json,jsonAllCompart,"network virtual-circuit list --all"
# Net-VirtCircPubPref,oci_network_virtual-circuit-public-prefix.json,jsonGenericMaster,"network virtual-circuit-public-prefix list" "Net-VirtCirc" "id:virtual-circuit-id" "jsonSimple"
# Net-Vnics,oci_network_vnic.json,jsonGenericMaster,"network vnic get" "Net-PrivateIPs" "vnic-id:vnic-id" "jsonSimple"
# OS-Buckets,oci_os_bucket.json,jsonAllCompart,"os bucket list --all"
# OS-BucketsDetails,oci_os_bucket_details.json,jsonGenericMaster,"os bucket get" "OS-Buckets" "name:bucket-name" "jsonSimple"
# OS-Multipart,oci_os_multipart.json,jsonGenericMasterAdd,"os multipart list --all" "OS-Buckets" "name:bucket-name:bucket-name" "jsonSimple"
# OS-Nameserver,oci_os_ns.json,jsonSimple,"os ns get"
# OS-NameserverMeta,oci_os_ns-metadata.json,jsonSimple,"os ns get-metadata"
# OS-ObjLCPolicy,oci_os_object-lifecycle-policy.json,jsonGenericMaster,"os object-lifecycle-policy get" "OS-Buckets" "name:bucket-name" "jsonSimple"
# OS-Objects,oci_os_object.json,jsonGenericMasterAdd,"os object list --all" "OS-Buckets" "name:bucket-name:bucket-name" "jsonSimple"
# OS-PreauthReqs,oci_os_preauth-request.json,jsonGenericMasterAdd,"os preauth-request list --all" "OS-Buckets" "name:bucket-name:bucket-name" "jsonSimple"
# OS-RepSources,oci_os_replication_sources.json,jsonGenericMasterAdd,"os replication list-replication-sources --all" "OS-Buckets" "name:bucket-name:bucket-name" "jsonSimple"
# OS-RepPolicies,oci_os_replication_policies.json,jsonGenericMasterAdd,"os replication list-replication-policies --all" "OS-Buckets" "name:bucket-name:bucket-name" "jsonSimple"
# OS-WorkReqs,oci_os_work-request.json,jsonAllCompart,"os work-request list"
# Search-ResTypes,oci_search_resource-type.json,jsonSimple,"search resource-type list --all"
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
            (${c_subfunc} ${c_param})
            c_ret=\$?
            set -e
            return \${c_ret}
          }"
  else
    eval "function ${c_name} ()
          {
            stopIfProcessed ${c_fname} || return 0
            set +e
            (${c_subfunc} ${c_param} > \${v_tmpfldr}/.${c_fname})
            c_ret=\$?
            set -e
            cat \${v_tmpfldr}/.${c_fname}
            return \${c_ret}
          }"
  fi
done 3< <(echo "$v_func_list")

function stopIfProcessed ()
{
  # If function was executed before, print the output and return error. The dynamic eval function will stop if error is returned.
  local v_arg1="$1"
  [ -n "${v_tmpfldr}" ] || return 0
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
  [ -z "${v_region}" ] && echo "Processing \"${v_arg2}\"." || echo "Processing \"${v_arg2}\" in ${v_region}."
  set +e
  (${v_arg1} > "${v_arg2}" 2> "${v_arg2}.err")
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

function main ()
{
  # If ALL or ALL_REGIONS, loop over all defined options.
  local c_line c_name c_file
  if [ "${v_param1}" != "ALL" -a "${v_param1}" != "ALL_REGIONS" ]
  then
    ${v_param1} && v_ret=$? || v_ret=$?
  else
    [ -n "$v_outfile" ] || v_outfile="${v_this_script%.*}_$(date '+%Y%m%d%H%M%S').zip"
    while read -u 3 -r c_line || [ -n "$c_line" ]
    do
       c_name=$(cut -d ',' -f 1 <<< "$c_line")
       c_file=$(cut -d ',' -f 2 <<< "$c_line")
       [ -n "${OCI_JSON_INCLUDE}" ] && [[ ",${OCI_JSON_INCLUDE}," != *",${c_name},"* ]] && continue
       [ -n "${OCI_JSON_EXCLUDE}" ] && [[ ",${OCI_JSON_EXCLUDE}," = *",${c_name},"* ]] && continue
       runAndZip $c_name $c_file
    done 3< <(echo "$v_func_list")
    v_ret=0
  fi
}

# Start code execution. If ALL_REGIONS, call main for each region.
echoDebug "BEGIN"
cleanTmpFiles
if [ "${v_param1}" == "ALL_REGIONS" ]
then
  l_regions=$(IAM-RegionSub | ${v_jq} -r '.data[]."region-name"')
  v_oci_orig="$v_oci"
  v_tmpfldr_base="${v_tmpfldr}"
  v_outfile_pref="${v_this_script%.*}_$(date '+%Y%m%d%H%M%S')"
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
      [ -n "${v_tmpfldr_base}" ] && { v_tmpfldr="${v_tmpfldr_base}/${v_region}"; cleanTmpFiles; rmdir "${v_tmpfldr}"; }
  done
  v_tmpfldr="${v_tmpfldr_base}"
else
  main
fi
cleanTmpFiles
echoDebug "END"

[ -n "${v_tmpfldr}" ] && rmdir "${v_tmpfldr}" 2>&- || true

exit ${v_ret}
###