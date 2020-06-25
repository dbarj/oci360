#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Apr/2020 by Rodrigo Jorge
# v1.9
# ----------------------------------------------------------------------------
set -x
. ~/.bash_profile
set -eo pipefail

## Change following variables if required.

v_retention_period=60 # Number of days to keep past oci360 executions.
v_billing_period=90   # Number of days to get billing data.
v_audit_period=30     # Number of days to get audit data.
v_monit_period=30     # Number of days to get monitoring data.
v_usage_period=30     # Number of days to get reporting data.

v_basedir=$HOME/oci360_tool/   # Folder of OCI360 Tool
v_confdir=$v_basedir/scripts   # Folder of this script

export TMPDIR=$v_basedir/tmp/
export OCI_CLI_ARGS="--cli-rc-file /dev/null"

v_dir_www=/var/www/oci360       # Apache folder.
v_dir_oci360=$v_basedir/app     # OCI360 github tool folder.
v_dir_ociexp=$v_basedir/exp     # Output folder for exported json files.
v_dir_ociout=$v_basedir/out     # Output folder of OCI360 execution.
v_dir_ocilog=$v_basedir/log     # Log folder of OCI360 execution.

v_timeout=$((24*3600)) # Timeout to run JSON exporter. 3600 = 1 hour

# If you want to have multiple tenancies being executed for the same server, you can optionally pass the tenancy name as a parameter for this script.
# In this case, you must also create a profile for the tenancy on .oci/config and all the corresponding sub-folders.

if [ -n "$1" ]
then
  v_param1="$1"
  v_param1_lower=$(echo "$v_param1" | tr '[:upper:]' '[:lower:]')
  v_param1_upper=$(echo "$v_param1" | tr '[:lower:]' '[:upper:]')
  export OCI_CLI_ARGS="${OCI_CLI_ARGS} --profile ${v_param1_upper}"
  v_dir_www=${v_dir_www}/${v_param1_lower}
  v_dir_ociexp=${v_dir_ociexp}/${v_param1_lower}
  v_dir_ociout=${v_dir_ociout}/${v_param1_lower}
  v_dir_ocilog=${v_dir_ocilog}/${v_param1_lower}
  v_schema_name=${v_param1_upper}
  v_config_file=${v_param1_lower}.cfg # This file is optional for billing collector.
  export TMPDIR=${TMPDIR}/${v_param1_lower}
else
  v_schema_name="OCI360"
  v_config_file="oci360.cfg" # This file is optional for billing collector.
fi

[ ! -d "${v_dir_ociout}" ]   && { echo "Folder \"${v_dir_ociout}\" is not created."; exit 1; }
[ ! -d "${v_dir_ocilog}" ]   && { echo "Folder \"${v_dir_ocilog}\" is not created."; exit 1; }
[ ! -d ${v_dir_www} ]        && { echo "Folder \"${v_dir_www}\" is not created."; exit 1; }
[ ! -d ${v_dir_ociexp} ]     && { echo "Folder \"${v_dir_ociexp}\" is not created."; exit 1; }
[ ! -f ${v_confdir}/${v_config_file} ] && { echo "File \"${v_confdir}/${v_config_file}\" is not created."; exit 1; }

v_script_runtime=$(/bin/date '+%Y%m%d%H%M%S')
echo "From that point, all the output will be redirected to \"${v_dir_ocilog}/run.${v_script_runtime}.log\"."
# Redirect script STDOUT and STDERR to file.
exec 1<&-
exec 2<&-
exec 1<>"${v_dir_ocilog}/run.${v_script_runtime}.log"
exec 2<>"${v_dir_ocilog}/run.${v_script_runtime}.trc"

pid_check() {
  PIDFILE="${v_dir_ocilog}"/${v_schema_name}.pid
  [ -n "${v_pid_file}" ] && PIDFILE="${v_pid_file}"
  if [ -f $PIDFILE ]
  then
    PID=$(cat $PIDFILE)
    ps -p $PID > /dev/null 2>&1 && v_ret=$? || v_ret=$?
    if [ $v_ret -eq 0 ]
    then
      echo "Process already running"
      exit 1
    else
      ## Process not found assume not running
      echo $1 > $PIDFILE && v_ret=$? || v_ret=$?
      if [ $v_ret -ne 0 ]
      then
        echo "Could not create PID file"
        exit 1
      fi
    fi
  else
    echo $1 > $PIDFILE && v_ret=$? || v_ret=$?
    if [ $v_ret -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    fi
  fi
}

pid_check $$

# Create TMPDIR
[ ! -d ${TMPDIR} ] && mkdir ${TMPDIR}

# Clean past temp files.
rm -rf ${TMPDIR}/.oci/

# Load db.cfg
[ -f ${v_confdir}/db.cfg ] && . ${v_confdir}/db.cfg

# Load optional config file, if available.
[ -f ${v_confdir}/${v_config_file} ] && . ${v_confdir}/${v_config_file}

###
### Checks
###

[ -z "${v_conn}" ] && { echo "Connection variable v_conn is undefined on \"${v_confdir}/db.cfg\"."; exit 1; }

###
### Start extractor
###

# Variables
v_dir_exp="${v_dir_ociexp}/exp_tenancy"
v_dir_bill="${v_dir_ociexp}/exp_billing"
v_dir_audit="${v_dir_ociexp}/exp_audit"
v_dir_monit="${v_dir_ociexp}/exp_monit"
v_dir_usage="${v_dir_ociexp}/exp_usage"


# Tenancy Collector
[ ! -d "${v_dir_exp}" ] && mkdir "${v_dir_exp}"
cd "${v_dir_exp}"
echo "Calling oci_json_export.sh."
timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_export.sh ALL_REGIONS > ${v_dir_ocilog}/oci_json_export.log 2>&1 &
v_pid_exp=$!

# Billing Collector
if [ -f ${v_confdir}/${v_config_file} -a ${v_billing_period} -gt 0 ]
then
  [ ! -d "${v_dir_bill}" ] && mkdir "${v_dir_bill}"
  cd "${v_dir_bill}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/billing_hist.zip"
  [ -d "${HIST_ZIP_FILE}.lock.d" ] && rmdir "${HIST_ZIP_FILE}.lock.d"
  echo "Calling oci_json_billing.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_billing.sh ALL $(date -d "-${v_billing_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_json_billing.log 2>&1 &
  v_pid_bill=$!
fi

# Audit Collector
if [ ${v_audit_period} -gt 0 ]
then
  [ ! -d "${v_dir_audit}" ] && mkdir "${v_dir_audit}"
  cd "${v_dir_audit}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/audit_hist.zip"
  [ -d "${HIST_ZIP_FILE}.lock.d" ] && rmdir "${HIST_ZIP_FILE}.lock.d"
  echo "Calling oci_json_audit.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_audit.sh ALL_REGIONS $(date -d "-${v_audit_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_json_audit.log 2>&1 &
  v_pid_audit=$!
fi

# Monitoring Collector
if [ ${v_monit_period} -gt 0 ]
then
  [ ! -d "${v_dir_monit}" ] && mkdir "${v_dir_monit}"
  cd "${v_dir_monit}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/monit_hist.zip"
  [ -d "${HIST_ZIP_FILE}.lock.d" ] && rmdir "${HIST_ZIP_FILE}.lock.d"
  echo "Calling oci_json_monitoring.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_json_monitoring.sh ALL_REGIONS $(date -d "-${v_monit_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_json_monitoring.log 2>&1 &
  v_pid_monit=$!
fi

# Usage Collector
if [ ${v_usage_period} -gt 0 ]
then
  [ ! -d "${v_dir_usage}" ] && mkdir "${v_dir_usage}"
  cd "${v_dir_usage}"
  [ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"
  export HIST_ZIP_FILE="${v_dir_ociexp}/processed/usage_hist.zip"
  echo "Calling oci_csv_usage.sh."
  timeout ${v_timeout} bash ${v_dir_oci360}/sh/oci_csv_usage.sh -r $(date -d "-${v_usage_period} day" +%Y-%m-%d) > ${v_dir_ocilog}/oci_csv_usage.log 2>&1 &
  v_pid_usage=$!
fi

###
### Start merger
###

cd ${v_dir_ociexp}

# Tenancy Merger
echo "Waiting for oci_json_export.sh to finish."
echo "For execution status, run: tail -f ${v_dir_ocilog}/oci_json_export.log"
wait $v_pid_exp && v_ret=$? || v_ret=$?
if [ $v_ret -ne 0 ]
then
  echo "oci_json_export.sh failed. Return: ${v_ret}. Code will stop here."
  cp -av "${v_dir_ocilog}/oci_json_export.log" "${v_dir_ocilog}/oci_json_export.${v_script_runtime}.log" || true
  echo "Check logfile for more info: ${v_dir_ocilog}/oci_json_export.${v_script_runtime}.log"
  exit 1
fi
echo "Merging oci_json_export.sh outputs."
mv "${v_dir_exp}"/oci_json_export_*.zip ${v_dir_ociexp}
rmdir "${v_dir_exp}" || true
v_exp_file=$(ls -t1 oci_json_export_*.zip | head -n 1 | sed 's/_[^_]*$//')
${v_dir_oci360}/sh/oci_json_merger.sh "${v_exp_file}_*.zip" "${v_exp_file}.zip"

# Billing Merger
if [ -f ${v_confdir}/${v_config_file} -a ${v_billing_period} -gt 0 ]
then
  echo "Waiting for oci_json_billing.sh to finish."
  echo "For execution status, run: tail -f ${v_dir_ocilog}/oci_json_billing.log"
  wait $v_pid_bill && v_ret=$? || v_ret=$?
  echo "Merging oci_json_billing.sh outputs."
  mv "${v_dir_bill}"/oci_json_billing_*.zip ${v_dir_ociexp} || true
  rmdir "${v_dir_bill}" || true
  if [ $v_ret -eq 0 ]
  then
    v_file=$(ls -t1 oci_json_billing_*.zip | sed 's/.zip$//' | head -n 1)
    if [ -f ${v_file}.zip ]
    then
      mkdir ${v_file}
      unzip -d ${v_file} ${v_file}.zip
      cd ${v_file}
      zip -m ${v_dir_ociexp}/${v_exp_file}.zip *.json
      cd ${v_dir_ociexp}
      rm -rf ${v_file}
    fi
  fi
fi

# Audit Merger
if [ ${v_audit_period} -gt 0 ]
then
  echo "Waiting for oci_json_audit.sh to finish."
  echo "For execution status, run: tail -f ${v_dir_ocilog}/oci_json_audit.log"
  wait $v_pid_audit && v_ret=$? || v_ret=$?
  echo "Merging oci_json_audit.sh outputs."
  mv "${v_dir_audit}"/oci_json_audit_*.zip ${v_dir_ociexp} || true
  rmdir "${v_dir_audit}" || true
  if [ $v_ret -eq 0 ]
  then
    export MERGE_UNIQUE=0
    v_prefix_file=$(ls -t1 oci_json_audit_*.zip | head -n 1 | sed 's/_[^_]*$//')
    ${v_dir_oci360}/sh/oci_json_merger.sh "${v_prefix_file}_*.zip" "${v_prefix_file}.zip"
    unset MERGE_UNIQUE
    v_file=$(ls -t1 oci_json_audit_*.zip | sed 's/.zip$//' | head -n 1)
    if [ -f ${v_file}.zip ]
    then
      mkdir ${v_file}
      unzip -d ${v_file} ${v_file}.zip
      cd ${v_file}
      zip -m ${v_dir_ociexp}/${v_exp_file}.zip *.json
      cd ${v_dir_ociexp}
      rm -rf ${v_file}
    fi
  fi
fi

# Monitoring Merger
if [ ${v_monit_period} -gt 0 ]
then
  echo "Waiting for oci_json_monitoring.sh to finish."
  echo "For execution status, run: tail -f ${v_dir_ocilog}/oci_json_monitoring.log"
  wait $v_pid_monit && v_ret=$? || v_ret=$?
  echo "Merging oci_json_monitoring.sh outputs."
  mv "${v_dir_monit}"/oci_json_monitoring_*.zip ${v_dir_ociexp} || true
  rmdir "${v_dir_monit}" || true
  if [ $v_ret -eq 0 ]
  then
    export MERGE_UNIQUE=0
    v_prefix_file=$(ls -t1 oci_json_monitoring_*.zip | head -n 1 | sed 's/_[^_]*$//')
    ${v_dir_oci360}/sh/oci_json_merger.sh "${v_prefix_file}_*.zip" "${v_prefix_file}.zip"
    unset MERGE_UNIQUE
    v_file=$(ls -t1 oci_json_monitoring_*.zip | sed 's/.zip$//' | head -n 1)
    if [ -f ${v_file}.zip ]
    then
      mkdir ${v_file}
      unzip -d ${v_file} ${v_file}.zip
      cd ${v_file}
      zip -m ${v_dir_ociexp}/${v_exp_file}.zip *.json
      cd ${v_dir_ociexp}
      rm -rf ${v_file}
    fi
  fi
fi

# Usage Report
if [ ${v_usage_period} -gt 0 ]
then
  echo "Waiting for oci_csv_usage.sh to finish."
  echo "For execution status, run: tail -f ${v_dir_ocilog}/oci_csv_usage.log"
  wait $v_pid_usage && v_ret=$? || v_ret=$?
  mv "${v_dir_usage}"/oci_csv_usage_*.zip ${v_dir_ociexp} || true
  rmdir "${v_dir_usage}" || true
  if [ $v_ret -eq 0 ]
  then
    v_csv_file=$(ls -t1 oci_csv_usage_*.zip | head -n 1)
  fi
fi

###
### Move output to OCI Bucket
###

rm -f ${v_dir_ociout}/oci_csv_usage_*.zip
rm -f ${v_dir_ociout}/oci_json_export_*.zip

if [ -n "${v_oci_bucket}" ]
then
  [ -n "${OCI_CLI_ARGS_BUCKET}" ] && OCI_CLI_ARGS_BKP="${OCI_CLI_ARGS}" && export OCI_CLI_ARGS="${OCI_CLI_ARGS_BUCKET}"
  export OCI_UP_GZIP=1
  export OCI_CLEAN_BUCKET=1
  bash ${v_dir_oci360}/sh/oci_bucket_upload.sh "${v_oci_bucket}" "${v_dir_ociexp}/${v_exp_file}.zip"
  unset OCI_CLEAN_BUCKET
  [ -n "${v_csv_file}" ] && bash ${v_dir_oci360}/sh/oci_bucket_upload.sh "${v_oci_bucket}" "${v_dir_ociexp}/${v_csv_file}"
  [ -n "${OCI_CLI_ARGS_BUCKET}" ] && export OCI_CLI_ARGS="${OCI_CLI_ARGS_BKP}"
else
  [ -n "${v_csv_file}" ] && cp -av ${v_dir_ociexp}/${v_csv_file} ${v_dir_ociout}
  cp -av ${v_dir_ociexp}/${v_exp_file}.zip ${v_dir_ociout}
fi

###
### Start reporter (OCI360 SQL script)
###

cd ${v_dir_oci360}

echo "Calling oci360.sql. SQLPlus will be executed with the following options:"

cat << EOF
--
DEF moat369_pre_sw_output_fdr = '${v_dir_ociout}'
DEF oci360_pre_obj_schema = '${v_schema_name}'
DEF oci360_clean_on_exit = 'OFF'
${v_oci360_opts}
@oci360.sql
--
EOF

echo "For execution status, run: tail -f ${v_dir_ocilog}/oci360.out"
sqlplus ${v_conn} > ${v_dir_ocilog}/oci360.out << EOF
DEF moat369_pre_sw_output_fdr = '${v_dir_ociout}'
DEF oci360_pre_obj_schema = '${v_schema_name}'
DEF oci360_clean_on_exit = 'OFF'
${v_oci360_opts}
@oci360.sql
EOF

###
### Move result to Apache
###

echo "Moving results to Apache."

v_oci_file=$(ls -1t ${v_dir_ociout}/oci360_*.zip | head -n 1)
v_dir_name=$(basename $v_oci_file .zip)
v_dir_path=${v_dir_ociout}/${v_dir_name}

mkdir ${v_dir_path}
unzip -q -d ${v_dir_path} ${v_oci_file}
chmod -R a+r ${v_dir_path}
find ${v_dir_path} -type d | xargs chmod a+x
mv ${v_dir_path}/00001_*.html ${v_dir_path}/index.html

###
### Run obfuscation tool if present
###

cd ${v_dir_path}
if [ -f ${v_confdir}/oci360_obfuscate.sh -a "${v_obfuscate}" == "yes" ]
then
  echo "Running obfuscation."
  . ${v_confdir}/oci360_obfuscate.sh || true
fi

###

mv ${v_dir_path} ${v_dir_www}
cd ${v_dir_www}
rm -f latest
ln -sf ${v_dir_name} latest
/usr/sbin/restorecon -R ${v_dir_www}

# Create folders if not exit
[ ! -d "${v_dir_ociout}/processed" ] && mkdir "${v_dir_ociout}/processed"
[ ! -d "${v_dir_ociexp}/processed" ] && mkdir "${v_dir_ociexp}/processed"

# Clean based on retention period
find ${v_dir_ocilog}/ -maxdepth 1 -type f -mtime +${v_retention_period} -name *.log -exec rm -f {} \;
find ${v_dir_ocilog}/ -maxdepth 1 -type f -mtime +${v_retention_period} -name *.trc -exec rm -f {} \;
find ${v_dir_ociout}/processed/ -maxdepth 1 -type f -mtime +${v_retention_period} -exec rm -f {} \;
find ${v_dir_ociexp}/processed/ -maxdepth 1 -type f -mtime +${v_retention_period} -exec rm -f {} \;
find ${v_dir_www} -maxdepth 1 -type d -mtime +${v_retention_period} -exec rm -rf {} \;
[ -d "/opt/oracle/admin/XE/adump/" ] && find /opt/oracle/admin/XE/adump/ -type f -mtime +${v_retention_period} -name *.aud -exec rm -f {} \;

# Always clean csv_usage as they occupy a huge space:
find ${v_dir_ociexp}/processed/ -maxdepth 1 -type f -name oci_csv_usage_*.zip -exec rm -f {} \;

# Move processed ZIP file
mv ${v_dir_ociexp}/oci_json_export_*.zip     ${v_dir_ociexp}/processed/
mv ${v_dir_ociexp}/oci_json_billing_*.zip    ${v_dir_ociexp}/processed/ || true
mv ${v_dir_ociexp}/oci_json_audit_*.zip      ${v_dir_ociexp}/processed/ || true
mv ${v_dir_ociexp}/oci_json_monitoring_*.zip ${v_dir_ociexp}/processed/ || true
mv ${v_dir_ociexp}/oci_csv_usage_*.zip       ${v_dir_ociexp}/processed/ || true
mv ${v_oci_file} ${v_dir_ociout}/processed/

# Clean HIST Files once a week

#if [ $(date '+%u') -eq 1 ]
#then
  echo "Cleaning hist files."
  bash ${v_dir_oci360}/sh/oci_zip_hist_clean.sh "${v_dir_ociexp}/processed/billing_hist.zip" history_list.txt ${v_billing_period} || true
  bash ${v_dir_oci360}/sh/oci_zip_hist_clean.sh "${v_dir_ociexp}/processed/monit_hist.zip"   history_list.txt ${v_audit_period}   || true
  bash ${v_dir_oci360}/sh/oci_zip_hist_clean.sh "${v_dir_ociexp}/processed/audit_hist.zip"   history_list.txt ${v_monit_period}   || true
  bash ${v_dir_oci360}/sh/oci_zip_hist_clean.sh "${v_dir_ociexp}/processed/usage_hist.zip"   history_list.txt ${v_usage_period}   || true
#fi

echo "Script finished."
exit 0
####
