#!/bin/sh
#
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# ----------------------------------------------------------------------------
#
# This is a crontab script that will run the full OCI360 stack every X min.
# For more information how to deploy this, check:
#
# https://github.com/dbarj/oci360/wiki/Install-OCI360
#
# ----------------------------------------------------------------------------
# v1.17
# ----------------------------------------------------------------------------

source ~/.bash_profile
set -eo pipefail

## Default values. If you want to change them, modify in the .cfg file.

v_retention_period=30 # Number of days to keep past oci360 executions.
v_billing_period=90   # Number of days to get billing data.
v_audit_period=7      # Number of days to get audit data.
v_monit_period=30     # Number of days to get monitoring data.
v_usage_period=30     # Number of days to get reporting data.

# Funcions

echoTime ()
{
  echo "$(date '+%Y%m%d_%H%M%S'): $1"
}

exitError ()
{
  echoTime "$1"
  kill -9 $(ps -s $$ -o pid= | grep -v $$) 2>&-
  exit 1
}

trap_err ()
{
  conf_step_error
  exitError "Error on line $1."
}

# If script aborts, will call this function to write on cfg file the last executed step.
conf_step_error ()
{
  if [ -f ${v_config_file} -a -n "${OCI360_CRON_STEP}" ]
  then
    sed -i '/OCI360_LAST_EXEC_STEP=/d' ${v_config_file}
    echo "OCI360_LAST_EXEC_STEP=${OCI360_CRON_STEP}" >> ${v_config_file}
  fi
}

# Increment current step by 1.
incr_oci360_step ()
{
  [ -z "$OCI360_CRON_STEP" ] && OCI360_CRON_STEP=1 || OCI360_CRON_STEP=$(($OCI360_CRON_STEP+1))
}

# If unhandled error, code will stop and save current step.
trap 'trap_err $LINENO' ERR
trap 'exitError "Code interrupted."' SIGINT SIGTERM

# Directories

v_thisdir="$(dirname "$(readlink -f "$0")")"
v_basedir="$(readlink -f "$v_thisdir/../")"   # Folder of OCI360 Tool
v_confdir=$v_basedir/scripts                  # Folder of this script

export TMPDIR=$v_basedir/tmp/
export OCI_CLI_ARGS="--cli-rc-file /dev/null"

v_dir_www=/var/www/oci360       # Apache output folder.
v_dir_oci360=$v_basedir/app     # OCI360 github tool folder.
v_dir_ociexp=$v_basedir/exp     # Output folder for exported json files.
v_dir_ociout=$v_basedir/out     # Output folder of OCI360 execution.
v_dir_ocilog=$v_basedir/log     # Log folder of OCI360 execution.

v_timeout=$((24*3600)) # Timeout to run JSON exporter. 3600 = 1 hour

# Convert to original directory if symbolic link.
v_dir_www=$(readlink -f "${v_dir_www}")

# If you want to have multiple tenancies being executed for the same server, you can optionally pass the tenancy name as a parameter for this script.
# In this case, you must also create a profile for the tenancy on .oci/config and all the corresponding sub-folders.

if [ -n "$1" ]
then
  v_param1="$1"
  v_param1_lower=$(tr '[:upper:]' '[:lower:]' <<< "$v_param1")
  v_param1_upper=$(tr '[:lower:]' '[:upper:]' <<< "$v_param1")
  export OCI_CLI_ARGS="${OCI_CLI_ARGS} --profile ${v_param1_upper}"
  v_dir_ociexp=${v_dir_ociexp}/${v_param1_lower}
  v_dir_ociout=${v_dir_ociout}/${v_param1_lower}
  v_dir_ocilog=${v_dir_ocilog}/${v_param1_lower}
  v_dir_www=${v_dir_www}/${v_param1_lower}
  v_schema_name=${v_param1_upper}
  v_config_file=${v_param1_lower}.cfg
  export TMPDIR=${TMPDIR}/${v_param1_lower}
else
  v_schema_name="OCI360"
  v_config_file="oci360.cfg"
fi

v_config_file="${v_confdir}/${v_config_file}"

[ ! -d "${v_dir_ociexp}" ]   && { exitError "Folder \"${v_dir_ociexp}\" was not created."; }
[ ! -d "${v_dir_ociout}" ]   && { exitError "Folder \"${v_dir_ociout}\" was not created."; }
[ ! -d "${v_dir_ocilog}" ]   && { exitError "Folder \"${v_dir_ocilog}\" was not created."; }
[ ! -d "${v_dir_www}" ]      && { exitError "Folder \"${v_dir_www}\" was not created."; }

set +x

v_script_runtime=$(/bin/date '+%Y%m%d%H%M%S')
v_script_log="${v_dir_ocilog}/run.${v_script_runtime}.log"
v_script_trc="${v_dir_ocilog}/run.${v_script_runtime}.trc"
echo "From this point, all the output will also be redirected to \"${v_script_log}\"."

# Redirect script STDOUT and STDERR to file.
exec 2>"${v_script_trc}"
exec > >(tee -a "${v_script_log}")

set -x

pid_check ()
{
  PIDFILE="${v_dir_ocilog}"/${v_schema_name}.pid
  [ -n "${v_pid_file}" ] && PIDFILE="${v_pid_file}"
  if [ -f $PIDFILE ]
  then
    PID=$(cat $PIDFILE)
    ps -p $PID > /dev/null 2>&1 && v_ret=$? || v_ret=$?
    if [ $v_ret -eq 0 ]
    then
      exitError "Process already running"
    else
      ## Process not found assume not running
      echo $1 > $PIDFILE && v_ret=$? || v_ret=$?
      if [ $v_ret -ne 0 ]
      then
        exitError "Could not create PID file"
      fi
    fi
  else
    echo $1 > $PIDFILE && v_ret=$? || v_ret=$?
    if [ $v_ret -ne 0 ]
    then
      exitError "Could not create PID file"
    fi
  fi
}

pid_check $$

# Create TMPDIR
[ ! -d ${TMPDIR} ] && mkdir -p ${TMPDIR}

# Clean past temp files.
rm -rf ${TMPDIR}/.oci/

# Load db.cfg if exists. db.cfg is a generic file that will apply to any OCI360 profile.
[ -f ${v_confdir}/db.cfg ] && source ${v_confdir}/db.cfg

# Load optional config file, if file is available.
[ -f ${v_config_file} ] && source ${v_config_file}

# Skip script export steps
[ "${OCI360_SKIP_EXP}" != "1" ] && OCI360_SKIP_EXP=0
[ "${OCI360_SKIP_BILL}" != "1" ] && OCI360_SKIP_BILL=0
[ "${OCI360_SKIP_AUDIT}" != "1" ] && OCI360_SKIP_AUDIT=0
[ "${OCI360_SKIP_MONIT}" != "1" ] && OCI360_SKIP_MONIT=0
[ "${OCI360_SKIP_USAGE}" != "1" ] && OCI360_SKIP_USAGE=0

# Skip script merge steps
[ "${OCI360_SKIP_MERGER_EXP}" != "1" ] && OCI360_SKIP_MERGER_EXP=0
[ "${OCI360_SKIP_MERGER_BILL}" != "1" ] && OCI360_SKIP_MERGER_BILL=0
[ "${OCI360_SKIP_MERGER_AUDIT}" != "1" ] && OCI360_SKIP_MERGER_AUDIT=0
[ "${OCI360_SKIP_MERGER_MONIT}" != "1" ] && OCI360_SKIP_MERGER_MONIT=0
[ "${OCI360_SKIP_MERGER_USAGE}" != "1" ] && OCI360_SKIP_MERGER_USAGE=0

# Skip other steps
[ "${OCI360_SKIP_CLEAN_START}" != "0" ] && OCI360_SKIP_CLEAN_START=1
[ "${OCI360_SKIP_PLACE_ZIPS}" != "1" ] && OCI360_SKIP_PLACE_ZIPS=0
[ "${OCI360_SKIP_SQLPLUS}" != "1" ] && OCI360_SKIP_SQLPLUS=0
[ "${OCI360_SKIP_PREP_APACHE}" != "1" ] && OCI360_SKIP_PREP_APACHE=0
[ "${OCI360_SKIP_OBFUSCATE}" != "1" ] && OCI360_SKIP_OBFUSCATE=0
[ "${OCI360_SKIP_MV_APACHE}" != "1" ] && OCI360_SKIP_MV_APACHE=0
[ "${OCI360_SKIP_MV_PROC}" != "1" ] && OCI360_SKIP_MV_PROC=0

# If there is no Last Exec Step Variable, set it to 0.
[ -z "$OCI360_LAST_EXEC_STEP" ] && OCI360_LAST_EXEC_STEP=0

[ $OCI360_LAST_EXEC_STEP -gt 0 ] && echoTime "Code aborted on last call and will resume now from step $OCI360_LAST_EXEC_STEP"

###
### Checks
###

[ -z "${v_conn}" ] && { exitError "Connection variable v_conn is undefined on \"${v_config_file}\"."; }

# Variables
v_dir_exp="${v_dir_ociexp}/exp_tenancy"
v_dir_bill="${v_dir_ociexp}/exp_billing"
v_dir_audit="${v_dir_ociexp}/exp_audit"
v_dir_monit="${v_dir_ociexp}/exp_monit"
v_dir_usage="${v_dir_ociexp}/exp_usage"

##################
### Extraction ###
##################

echo_process_pid ()
{
  echoTime "Process \"${1}\" is running with PID ${2}."
}

echo_skip_section ()
{
  echoTime "Skip '${1}' execution."
}

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_CLEAN_START=1

if [ ${OCI360_SKIP_CLEAN_START} -eq 0 ]
then
  echoTime 'OCI360_SKIP_CLEAN_START is 0. Cleaning all staged files before starting.'
  rm -f "${v_dir_ociexp}/*.zip"
  rm -rf "${v_dir_exp}" "${v_dir_bill}" "${v_dir_audit}" "${v_dir_monit}" "${v_dir_usage}"
fi

# Tenancy Collector

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_EXP=1

if [ ${OCI360_SKIP_EXP} -eq 0 ]
then
  [ ! -d "${v_dir_exp}" ] && mkdir "${v_dir_exp}"
  cd "${v_dir_exp}"

  echoTime "Calling oci_json_export.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_export.sh ALL_REGIONS > ${v_dir_ocilog}/oci_json_export.log 2>&1 &
  v_pid_exp=$!
  echo_process_pid "oci_json_export.sh" ${v_pid_exp}
else
  echo_skip_section "oci_json_export.sh"
fi

# Billing Collector

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_BILL=1

if ! [ -f ${v_config_file} -a ${v_billing_period} -gt 0 ]
then
  OCI360_SKIP_BILL=1
  OCI360_SKIP_MERGE_BILL=1
fi

if [ ${OCI360_SKIP_BILL} -eq 0 ]
then
  [ ! -d "${v_dir_bill}" ] && mkdir "${v_dir_bill}"
  cd "${v_dir_bill}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/billing_hist.zip"
  [ -d "${HIST_ZIP_FILE}.lock.d" ] && rmdir "${HIST_ZIP_FILE}.lock.d"

  echoTime "Calling oci_json_billing.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_billing.sh ALL $(date -d "-${v_billing_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_json_billing.log 2>&1 &
  v_pid_bill=$!
  echo_process_pid "oci_json_billing.sh" ${v_pid_bill}
else
  echo_skip_section "oci_json_billing.sh"
fi

# Audit Collector

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_AUDIT=1

if ! [ ${v_audit_period} -gt 0 ]
then
  OCI360_SKIP_AUDIT=1
  OCI360_SKIP_MERGE_AUDIT=1
fi

if [ ${OCI360_SKIP_AUDIT} -eq 0 ]
then
  [ ! -d "${v_dir_audit}" ] && mkdir "${v_dir_audit}"
  cd "${v_dir_audit}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/audit_hist.zip"
  [ -d "${HIST_ZIP_FILE}.lock.d" ] && rmdir "${HIST_ZIP_FILE}.lock.d"

  echoTime "Calling oci_json_audit.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_audit.sh ALL_REGIONS $(date -d "-${v_audit_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_json_audit.log 2>&1 &
  v_pid_audit=$!
  echo_process_pid "oci_json_audit.sh" ${v_pid_audit}
else
  echo_skip_section "oci_json_audit.sh"
fi

# Monitoring Collector

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MONIT=1

if ! [ ${v_monit_period} -gt 0 ]
then
  OCI360_SKIP_MONIT=1
  OCI360_SKIP_MERGE_MONIT=1
fi

if [ ${OCI360_SKIP_MONIT} -eq 0 ]
then
  [ ! -d "${v_dir_monit}" ] && mkdir "${v_dir_monit}"
  cd "${v_dir_monit}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/monit_hist.zip"
  [ -d "${HIST_ZIP_FILE}.lock.d" ] && rmdir "${HIST_ZIP_FILE}.lock.d"

  echoTime "Calling oci_json_monitoring.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_monitoring.sh ALL_REGIONS $(date -d "-${v_monit_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_json_monitoring.log 2>&1 &
  v_pid_monit=$!
  echo_process_pid "oci_json_monitoring.sh" ${v_pid_monit}
else
  echo_skip_section "oci_json_monitoring.sh"
fi

# Usage Collector

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_USAGE=1

if ! [ ${v_usage_period} -gt 0 ]
then
  OCI360_SKIP_USAGE=1
  OCI360_SKIP_MERGE_USAGE=1
fi

if [ ${OCI360_SKIP_USAGE} -eq 0 ]
then
  [ ! -d "${v_dir_usage}" ] && mkdir "${v_dir_usage}"
  cd "${v_dir_usage}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/usage_hist.zip"

  echoTime "Calling oci_csv_usage.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_csv_usage.sh -r $(date -d "-${v_usage_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_csv_usage.log 2>&1 &
  v_pid_usage=$!
  echo_process_pid "oci_csv_usage.sh" ${v_pid_usage}
else
  echo_skip_section "oci_csv_usage.sh"
fi

##############
### Merger ###
##############

move_and_remove_folder ()
{
  # $1 -> Subfolder.
  # $2 -> File to move to parent folder.
  if ls "${1}"/${2} 1> /dev/null 2>&1
  then
    mv "${1}"/${2} .
    rmdir "${1}" || true
  fi
}

copy_json_from_zip1_to_zip2 ()
{
  # $1 -> Zip 1 (relative PATH).
  # $2 -> Zip 2 (full PATH).
  v_fdr=$(basename "${1}" .zip)
  mkdir "${v_fdr}"
  unzip -d "${v_fdr}" "${1}"
  cd "${v_fdr}"
  zip -m "${2}" *.json
  cd - > /dev/null
  rm -rf "${v_fdr}"
}

wait_pid_if_notnull ()
{
  # $1 -> Process.
  # $2 -> PID
  if [ -n "${2}" ]
  then
    echoTime "Waiting process \"${1}\" with PID ${2}. Hold on."
    wait ${2} && v_ret=$? || v_ret=$?
  else
    v_ret=0
  fi
}

echo_unable_find ()
{
  echoTime "Unable to find \"${1}\" files on \"$(pwd)\"."
}

echo_print_trace_log ()
{
  echoTime "Checking ${1}..."
  if [ -n "${2}" ]
  then
    echoTime "Trace File: tail -f ${2}"
  fi
  if [ -n "${3}" ]
  then
    echoTime "Log File: tail -f ${3}"
  fi
}

cd "${v_dir_ociexp}"

# Tenancy Merger

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MERGER_EXP=1

if [ ${OCI360_SKIP_EXP} -eq 0 ]
then
  echo_print_trace_log "oci_json_export.sh" "${v_dir_exp}/oci_json_export.log" "${v_dir_ocilog}/oci_json_export.log"
  tail -f ${v_dir_ocilog}/oci_json_export.log &
fi

wait_pid_if_notnull "oci_json_export.sh" $v_pid_exp

if [ $v_ret -ne 0 ]
then
  echoTime "oci_json_export.sh failed. Return: ${v_ret}. Code will stop here."
  cp -av "${v_dir_ocilog}/oci_json_export.log" "${v_dir_ocilog}/oci_json_export.${v_script_runtime}.log" || true
  exitError "Check logfile for more info: ${v_dir_ocilog}/oci_json_export.${v_script_runtime}.log"
fi

move_and_remove_folder "${v_dir_exp}" "oci_json_export_*_*.zip"

if [ ${OCI360_SKIP_MERGER_EXP} -eq 0 ]
then
  echoTime "Merging oci_json_export.sh outputs."
  if ls oci_json_export_*_*.zip 1> /dev/null 2>&1
  then
    v_prefix_file=$(ls -t1 oci_json_export_*_*.zip | head -n 1 | sed 's/_[^_]*$//')
    v_exp_file="${v_prefix_file}.zip"
    bash ${v_dir_oci360}/sh/oci_json_merger.sh "${v_prefix_file}_*.zip" "${v_exp_file}"
  else
    echo_unable_find "oci_json_export_*_*.zip"
    exitError "Restart the script removing OCI360_LAST_EXEC_STEP from ${v_config_file}."
  fi
else
  echo_skip_section "Export Merge"
fi

if [ -z "${v_exp_file}" ]
then
  if ls oci_json_export_*.zip 1> /dev/null 2>&1
  then
    v_exp_file=$(ls -t1 oci_json_export_*.zip | head -n 1)
  else
    echo_unable_find "oci_json_export_*.zip"
    exitError "Restart the script removing OCI360_LAST_EXEC_STEP from ${v_config_file}."
  fi
fi

# Billing Merger

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MERGER_BILL=1

if [ ${OCI360_SKIP_BILL} -eq 0 ]
then
  echo_print_trace_log "oci_json_billing.sh" "${v_dir_bill}/oci_json_billing.log" "${v_dir_ocilog}/oci_json_billing.log"
fi

wait_pid_if_notnull "oci_json_billing.sh" $v_pid_bill

if [ ${OCI360_SKIP_BILL} -eq 0 ]
then
  if [ $v_ret -eq 0 ]
  then
    echoTime "oci_json_billing.sh completed."
  else
    echoTime "oci_json_billing.sh failed. Return: $v_ret."
    OCI360_SKIP_MERGER_BILL=1
  fi
fi

move_and_remove_folder "${v_dir_bill}" "oci_json_billing_*.zip"

if [ ${OCI360_SKIP_MERGER_BILL} -eq 0 ]
then
  echoTime "Merging oci_json_billing.sh outputs."
  if ls oci_json_billing_*.zip 1> /dev/null 2>&1
  then
    v_file=$(ls -t1 oci_json_billing_*.zip | head -n 1)
    copy_json_from_zip1_to_zip2 "${v_file}" "${v_dir_ociexp}/${v_exp_file}"
  else
    echo_unable_find "oci_json_billing_*.zip"
  fi
else
  echo_skip_section "Billing Merge"
fi

# Audit Merger

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MERGER_AUDIT=1

if [ ${OCI360_SKIP_AUDIT} -eq 0 ]
then
  echo_print_trace_log "oci_json_audit.sh" "${v_dir_audit}/oci_json_audit.log" "${v_dir_ocilog}/oci_json_audit.log"
fi

wait_pid_if_notnull "oci_json_audit.sh" $v_pid_audit

if [ ${OCI360_SKIP_AUDIT} -eq 0 ]
then
  if [ $v_ret -eq 0 ]
  then
    echoTime "oci_json_audit.sh completed."
  else
    echoTime "oci_json_audit.sh failed. Return: $v_ret."
    OCI360_SKIP_MERGER_AUDIT=1
  fi
fi

move_and_remove_folder "${v_dir_audit}" "oci_json_audit_*_*.zip"

if [ ${OCI360_SKIP_MERGER_AUDIT} -eq 0 ]
then
  echoTime "Merging oci_json_audit.sh outputs."

  if ls oci_json_audit_*_*.zip 1> /dev/null 2>&1
  then
    export MERGE_UNIQUE=0
    v_prefix_file=$(ls -t1 oci_json_audit_*_*.zip | head -n 1 | sed 's/_[^_]*$//')
    ${v_dir_oci360}/sh/oci_json_merger.sh "${v_prefix_file}_*.zip" "${v_prefix_file}.zip"
    unset MERGE_UNIQUE
  else
    echo_unable_find "oci_json_audit_*_*.zip"
  fi

  if ls oci_json_audit_*.zip 1> /dev/null 2>&1
  then
    v_file=$(ls -t1 oci_json_audit_*.zip | head -n 1)
    copy_json_from_zip1_to_zip2 "${v_file}" "${v_dir_ociexp}/${v_exp_file}"
  else
    echo_unable_find "oci_json_audit_*.zip"
  fi
else
  echo_skip_section "Audit Merge"
fi

# Monitoring Merger

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MERGER_MONIT=1

if [ ${OCI360_SKIP_MONIT} -eq 0 ]
then
  echo_print_trace_log "oci_json_monitoring.sh" "${v_dir_monit}/oci_json_monitoring.log" "${v_dir_ocilog}/oci_json_monitoring.log"
fi

wait_pid_if_notnull "oci_json_monitoring.sh" $v_pid_monit

if [ ${OCI360_SKIP_MONIT} -eq 0 ]
then
  if [ $v_ret -eq 0 ]
  then
    echoTime "oci_json_monitoring.sh completed."
  else
    echoTime "oci_json_monitoring.sh failed. Return: $v_ret."
    OCI360_SKIP_MERGER_MONIT=1
  fi
fi

move_and_remove_folder "${v_dir_monit}" "oci_json_monitoring_*_*.zip"

if [ ${OCI360_SKIP_MERGER_MONIT} -eq 0 ]
then
  echoTime "Merging oci_json_monitoring.sh outputs."

  if ls oci_json_monitoring_*_*.zip 1> /dev/null 2>&1
  then
    export MERGE_UNIQUE=0
    v_prefix_file=$(ls -t1 oci_json_monitoring_*_*.zip | head -n 1 | sed 's/_[^_]*$//')
    ${v_dir_oci360}/sh/oci_json_merger.sh "${v_prefix_file}_*.zip" "${v_prefix_file}.zip"
    unset MERGE_UNIQUE
  else
    echo_unable_find "oci_json_monitoring_*_*.zip"
  fi

  if ls oci_json_monitoring_*.zip 1> /dev/null 2>&1
  then
    v_file=$(ls -t1 oci_json_monitoring_*.zip | head -n 1)
    copy_json_from_zip1_to_zip2 "${v_file}" "${v_dir_ociexp}/${v_exp_file}"
  else
    echo_unable_find "oci_json_monitoring_*.zip"
  fi
else
  echo_skip_section "Monitoring Merge"
fi

# Usage Prepare

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MERGER_USAGE=1

if [ ${OCI360_SKIP_USAGE} -eq 0 ]
then
  echo_print_trace_log "oci_csv_usage.sh" "${v_dir_usage}/oci_csv_usage.log" "${v_dir_ocilog}/oci_csv_usage.log"
fi

wait_pid_if_notnull "oci_csv_usage.sh" $v_pid_usage

if [ ${OCI360_SKIP_USAGE} -eq 0 ]
then
  if [ $v_ret -eq 0 ]
  then
    echoTime "oci_csv_usage.sh completed."
  else
    echoTime "oci_csv_usage.sh failed. Return: $v_ret."
    OCI360_SKIP_MERGER_USAGE=1
  fi
fi

move_and_remove_folder "${v_dir_usage}" "oci_csv_usage_*.zip"

if [ ${OCI360_SKIP_MERGER_USAGE} -eq 0 ]
then
  if ls oci_csv_usage_*.zip 1> /dev/null 2>&1
  then
    v_csv_file=$(ls -t1 oci_csv_usage_*.zip | head -n 1)
  else
    echo_unable_find "oci_csv_usage_*.zip"
  fi
else
  echo_skip_section "Usage Prepare"
fi

###################
### Move Output ###
###################

# Move output to OCI Bucket or to output folder

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_PLACE_ZIPS=1

if [ $OCI360_SKIP_PLACE_ZIPS -eq 0 ]
then
  rm -f ${v_dir_ociout}/oci_csv_usage_*.zip
  rm -f ${v_dir_ociout}/oci_json_export_*.zip

  if [ -n "${v_oci_bucket}" ]
  then
    [ -n "${OCI_CLI_ARGS_BUCKET}" ] && OCI_CLI_ARGS_BKP="${OCI_CLI_ARGS}" && export OCI_CLI_ARGS="${OCI_CLI_ARGS_BUCKET}"
    export OCI_UP_GZIP=1
    export OCI_CLEAN_BUCKET=1
    echoTime "Log File: tail -f ${v_dir_ocilog}/oci_bucket_upload.log"
    bash ${v_dir_oci360}/sh/oci_bucket_upload.sh "${v_oci_bucket}" "${v_dir_ociexp}/${v_exp_file}" > ${v_dir_ocilog}/oci_bucket_upload.log 2>&1
    unset OCI_CLEAN_BUCKET
    [ -n "${v_csv_file}" ] && bash ${v_dir_oci360}/sh/oci_bucket_upload.sh "${v_oci_bucket}" "${v_dir_ociexp}/${v_csv_file}" >> ${v_dir_ocilog}/oci_bucket_upload.log 2>&1
    [ -n "${OCI_CLI_ARGS_BUCKET}" ] && export OCI_CLI_ARGS="${OCI_CLI_ARGS_BKP}"
  else
    [ -n "${v_csv_file}" ] && cp -av ${v_dir_ociexp}/${v_csv_file} ${v_dir_ociout}
    cp -av ${v_dir_ociexp}/${v_exp_file} ${v_dir_ociout}
  fi
else
  echo_skip_section "Zip Prepare"
fi

####################################
### Reporter (OCI360 SQL script) ###
####################################

cd ${v_dir_oci360}

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_SQLPLUS=1

if [ ${OCI360_SKIP_SQLPLUS} -eq 0 ]
then

  echoTime "Calling oci360.sql. SQLPlus will be executed with the following options:"

  cat << EOF
--
DEF moat369_pre_sw_output_fdr = '${v_dir_ociout}'
DEF oci360_pre_obj_schema = '${v_schema_name}'
DEF oci360_clean_on_exit = 'OFF'
${v_oci360_opts}
@oci360.sql
--
EOF

  sqlplus ${v_conn} > ${v_dir_ocilog}/oci360.out << EOF &
DEF moat369_pre_sw_output_fdr = '${v_dir_ociout}'
DEF oci360_pre_obj_schema = '${v_schema_name}'
DEF oci360_clean_on_exit = 'OFF'
${v_oci360_opts}
@oci360.sql
EOF

  v_pid_sqlp="$!"
  echo_process_pid "SQLPlus" ${v_pid_sqlp}
  echo_print_trace_log "SQLPlus" "" "${v_dir_ocilog}/oci360.out"
  wait_pid_if_notnull "SQLPlus" ${v_pid_sqlp}

  if [ $v_ret -ne 0 ]
  then
    echoTime "OCI360 Database execution failed. Return: ${v_ret}. Code will stop here."
    cp -av "${v_dir_ocilog}/oci360.out" "${v_dir_ocilog}/oci360.${v_script_runtime}.out" || true
    conf_step_error
    exitError "Check logfile for more info: ${v_dir_ocilog}/oci360.${v_script_runtime}.out"
  fi
else
  echo_skip_section "SQLPlus oci360.sql"
fi

#############################
### Move result to Apache ###
#############################

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_PREP_APACHE=1

if [ ${OCI360_SKIP_PREP_APACHE} -eq 0 ]
then
  echoTime "Prepare result for Apache."

  v_oci_file=$(ls -1t ${v_dir_ociout}/oci360_*.zip | head -n 1)
  v_dir_name=$(basename $v_oci_file .zip)
  v_dir_path=${v_dir_ociout}/${v_dir_name}

  mkdir ${v_dir_path}
  unzip -q -d ${v_dir_path} ${v_oci_file}
  chmod -R a+r ${v_dir_path}
  find ${v_dir_path} -type d | xargs chmod a+x
  mv ${v_dir_path}/00001_*.html ${v_dir_path}/index.html
else
  echo_skip_section "Prepare Apache"
fi

if [ -z "${v_oci_file}" ]
then
  cd "${v_dir_ociout}"
  if ls oci360_*.zip 1> /dev/null 2>&1
  then
    v_oci_file=$(ls -1t ${v_dir_ociout}/oci360_*.zip | head -n 1)
    v_dir_name=$(basename $v_oci_file .zip)
    v_dir_path=${v_dir_ociout}/${v_dir_name}
  else
    echo_unable_find "oci360_*.zip"
    exitError "Restart the script removing OCI360_LAST_EXEC_STEP from ${v_config_file}."
  fi
  cd - > /dev/null
fi

#########################################
### Run obfuscation tool (if present) ###
#########################################

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_OBFUSCATE=1

if ! [ -f ${v_confdir}/oci360_obfuscate.sh -a "${v_obfuscate}" == "yes" ]
then
  OCI360_SKIP_OBFUSCATE=1
fi

if [ ${OCI360_SKIP_OBFUSCATE} -eq 0 ]
then
  cd "${v_dir_path}"
  echoTime "Running obfuscation."
  source ${v_confdir}/oci360_obfuscate.sh || true
  cd - > /dev/null
else
  echo_skip_section "Obfuscation"
fi

#############################
### Move result to Apache ###
#############################

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MV_APACHE=1

if [ ${OCI360_SKIP_MV_APACHE} -eq 0 ]
then
  echoTime "Moving results to Apache."

  mv ${v_dir_path} ${v_dir_www}
  cd ${v_dir_www}
  rm -f latest
  ln -sf ${v_dir_name} latest
  /usr/sbin/restorecon -R ${v_dir_www} || true
  cd - > /dev/null
else
  echo_skip_section "Move Apache"
fi

#############################
### Cleanup for next Exec ###
#############################

# Create processed folders
[ ! -d "${v_dir_ociout}/processed" ] && mkdir "${v_dir_ociout}/processed"
[ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"

# Clean based on retention period
find ${v_dir_ocilog}/ -maxdepth 1 -type f -mtime +${v_retention_period} -name *.log -exec rm -f {} \;
find ${v_dir_ocilog}/ -maxdepth 1 -type f -mtime +${v_retention_period} -name *.trc -exec rm -f {} \;
find ${v_dir_ociout}/processed/ -maxdepth 1 -type f -mtime +${v_retention_period} -exec rm -f {} \;
find ${v_dir_ociexp}/processed/ -maxdepth 1 -type f -mtime +${v_retention_period} -exec rm -f {} \;
find ${v_dir_www} -maxdepth 1 -type d -mtime +${v_retention_period} -exec rm -rf {} \;
[ -d "/opt/oracle/admin/XE/adump/" ] && find /opt/oracle/admin/XE/adump/ -type f -mtime +${v_retention_period} -name *.aud -exec rm -f {} \;

# Always clean csv_usage as they occupy a huge space and can be easily recreated:
find ${v_dir_ociexp}/processed/ -maxdepth 1 -type f -name oci_csv_usage_*.zip -exec rm -f {} \;

###############################
### Move processed ZIP file ###
###############################

move_exp_to_processed ()
{
  if ls ${1} 1> /dev/null 2>&1
  then
    mv ${1} ${v_dir_ociexp}/processed/
  fi
}

incr_oci360_step
[ $OCI360_LAST_EXEC_STEP -gt $OCI360_CRON_STEP ] && OCI360_SKIP_MV_PROC=1

if [ ${OCI360_SKIP_MV_PROC} -eq 0 ]
then
  echoTime "Moving processed files."

  move_exp_to_processed "${v_dir_ociexp}/oci_json_export_*.zip"
  move_exp_to_processed "${v_dir_ociexp}/oci_json_billing_*.zip"
  move_exp_to_processed "${v_dir_ociexp}/oci_json_audit_*.zip"
  move_exp_to_processed "${v_dir_ociexp}/oci_json_monitoring_*.zip"
  move_exp_to_processed "${v_dir_ociexp}/oci_csv_usage_*.zip"
  
  mv ${v_oci_file} ${v_dir_ociout}/processed/
else
  echo_skip_section "Move Processed Files"
fi

########################
### Clean HIST Files ###
########################

clean_hist_zip ()
{
  if [ -f "${1}" ]
  then
    bash ${v_dir_oci360}/sh/oci_zip_hist_clean.sh "${1}" history_list.txt ${2} || true
  fi
}

echoTime "Cleaning hist files."
clean_hist_zip "${v_dir_ociexp}/processed/billing_hist.zip" ${v_billing_period}
clean_hist_zip "${v_dir_ociexp}/processed/monit_hist.zip" ${v_monit_period}
clean_hist_zip "${v_dir_ociexp}/processed/audit_hist.zip" ${v_audit_period}
clean_hist_zip "${v_dir_ociexp}/processed/usage_hist.zip" ${v_usage_period}

# Clean last execution step if exists.
sed -i '/OCI360_LAST_EXEC_STEP=/d' ${v_config_file}

echoTime "Script finished."

exit 0
####