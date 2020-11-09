#!/bin/bash
# v1.0
# This script will make the deployment and configuration of OCI360 files and folders.

# To execute the latest version of this script, execute the line below:
# bash -c "$(curl -L https://raw.githubusercontent.com/dbarj/oci360/v20.07/container/upgrade_oci360.sh)"

set -eo pipefail
set -x

trap_err ()
{
  echo "Error on line $1 of \"upgrade_oci360.sh\"."
  exit 1
}

trap 'trap_err $LINENO' ERR

[ "$(id -u -n)" != "root" ] && echo "Must be executed as root! Exiting..." && exit 1

v_oci360_tool='/u01/oci360_tool'

v_exec_date=$(/bin/date '+%Y%m%d%H%M%S')

cd ${v_oci360_tool}
git clone https://github.com/dbarj/oci360.git
[ -d app ] && rm -rf app
mv oci360 app

# If OCI360_BRANCH is defined, change to it.
if [ -n "${OCI360_BRANCH}" -a "${OCI360_BRANCH}" != "master" ]
then
  cd app
  git checkout ${OCI360_BRANCH}
  cd -
fi

cp -av ${v_oci360_tool}/app/sh/oci360_cron.sh ${v_oci360_config}/oci360_run.sh

chown oci360: ${v_oci360_config}/oci360_run.sh
chown -R oci360: ${v_oci360_tool}/app/

##############