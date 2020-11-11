#!/bin/bash
# v1.1
# This script will make the deployment and configuration of OCI360 files and folders.

set -eo pipefail
set -x

trap_err ()
{
  echo "Error on line $1 of \"setup_oci360.sh\"."
  exit 1
}

trap 'trap_err $LINENO' ERR

[ "$(id -u -n)" != "root" ] && echo "Must be executed as root! Exiting..." && exit 1

v_oci360_home='/home/oci360'
v_oci360_tool='/u01/oci360_tool'
v_oci360_www='/u01/www'
v_oci360_config="${v_oci360_tool}/scripts"
v_oci360_netadmin="${v_oci360_config}/network"
v_ocicli_dir="/u01/.oci"

# v_replace_config_files = true or false.
# Keep false to reuse your configuration. True to recreate default files.
v_replace_config_files=false

v_exec_date=$(/bin/date '+%Y%m%d%H%M%S')

yum install -y oraclelinux-developer-release-el7.x86_64
yum-config-manager --enable ol7_developer
yum install -y --setopt=tsflags=nodocs python-oci-cli jq git which

mkdir -p ${v_oci360_www}
mkdir -p ${v_oci360_tool}
mkdir -p ${v_oci360_tool}/{log,out,exp}
mkdir -p ${v_oci360_config}
mkdir -p ${v_oci360_netadmin}

mkdir -p /var/www/
ln -s ${v_oci360_www} /var/www/oci360

[ -z "${OCI360_UID}" ] && OCI360_UID=54322
useradd -u ${OCI360_UID} -g users -m -d ${v_oci360_home} oci360
chown -R oci360: ${v_oci360_www} ${v_oci360_home}

echo 'export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE' >> ${v_oci360_home}/.bash_profile
echo 'export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch' >> ${v_oci360_home}/.bash_profile
echo 'export ORACLE_SID=XE' >> ${v_oci360_home}/.bash_profile

source ${v_oci360_home}/.bash_profile

# Backup previous files if v_replace_config_files is true
if $v_replace_config_files
then
  if [ -f ${v_oci360_netadmin}/tnsnames.ora ]
  then
    mv ${v_oci360_netadmin}/tnsnames.ora ${v_oci360_netadmin}/tnsnames.ora.${v_exec_date}
  fi
  if [ -f ${v_oci360_netadmin}/sqlnet.ora ]
  then
    mv ${v_oci360_netadmin}/sqlnet.ora ${v_oci360_netadmin}/sqlnet.ora.${v_exec_date}
  fi
  if [ -f ${v_oci360_config}/oci360.cfg ]
  then
    mv ${v_oci360_config}/oci360.cfg ${v_oci360_config}/oci360.cfg.${v_exec_date}
  fi
  if [ -f ${v_oci360_home}/.oci/config ]
  then
    mv ${v_oci360_home}/.oci/config ${v_oci360_home}/.oci/config.${v_exec_date}
  fi
fi

# Wallet files must always be recreated as OCI360 user will have a new random pass.
if [ -f ${v_oci360_netadmin}/cwallet.sso ]
then
  mkdir -p ${v_oci360_netadmin}/old
  mv ${v_oci360_netadmin}/cwallet.sso ${v_oci360_netadmin}/old/cwallet.sso.${v_exec_date}
fi

if [ -f ${v_oci360_netadmin}/ewallet.p12 ]
then
  mkdir -p ${v_oci360_netadmin}/old
  mv ${v_oci360_netadmin}/ewallet.p12 ${v_oci360_netadmin}/old/ewallet.p12.${v_exec_date}
fi

# Create wallet files.
v_wallet_pass="Oracle.123.$(openssl rand -hex 4)"
orapki wallet create -wallet ${v_oci360_netadmin} -auto_login -pwd ${v_wallet_pass}
mkstore -wrl ${v_oci360_netadmin} -createCredential oci360xe oci360 oracle <<< "${v_wallet_pass}"

if ! grep -qF 'OCI360XE' ${v_oci360_netadmin}/tnsnames.ora
then
  echo 'OCI360XE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = XEPDB1)
    )
  )' >> ${v_oci360_netadmin}/tnsnames.ora
fi

if [ ! -f ${v_oci360_netadmin}/sqlnet.ora ]
then
  cat << EOF > ${v_oci360_netadmin}/sqlnet.ora
WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=${v_oci360_netadmin})))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
fi

if [ ! -f ${v_oci360_config}/oci360.cfg ]
then
  echo "export TNS_ADMIN=${v_oci360_netadmin}" > ${v_oci360_config}/oci360.cfg
  echo "v_conn='/@oci360xe'" >> ${v_oci360_config}/oci360.cfg
  echo 'export OCI_CLI_AUTH=instance_principal' >> ${v_oci360_config}/oci360.cfg
fi

chmod 600 ${v_oci360_config}/oci360.cfg

mkdir -p ${v_ocicli_dir}
chown -R oci360: ${v_ocicli_dir}
ln -s ${v_ocicli_dir} ${v_oci360_home}/.oci

if [ ! -f ${v_oci360_home}/.oci/config ]
then
  cat << 'EOF' > ${v_oci360_home}/.oci/config
[DEFAULT]
tenancy=ocid1.tenancy.oc1..xxx
region=us-ashburn-1
EOF
fi

chmod 600 ${v_oci360_home}/.oci/config
chown oci360: ${v_oci360_home}/.oci/config

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

# Change OCI360 password
v_oci360_pass="$(openssl rand -hex 6)"
bash ${v_oci360_tool}/app/container/change_oci360_pass.sh "${v_oci360_pass}"
mkstore -wrl ${v_oci360_netadmin} -modifyCredential oci360xe oci360 ${v_oci360_pass} <<< "${v_wallet_pass}"

if [ -f ${v_oci360_config}/credentials ]
then
  mv ${v_oci360_config}/credentials ${v_oci360_config}/credentials.${v_exec_date}
fi

echo "DB Wallet Pass is: ${v_wallet_pass}" > ${v_oci360_config}/credentials
echo "OCI360 DB Pass is: ${v_oci360_pass}" >> ${v_oci360_config}/credentials
echo "SYS/SYSTEM DB Pass is: $ORACLE_PWD" >> ${v_oci360_config}/credentials

chown -R oci360: ${v_oci360_home}
chown -R oci360: ${v_oci360_tool}

chown root: ${v_oci360_config}/credentials*
chmod 600 ${v_oci360_config}/credentials*

chgrp dba ${v_oci360_tool}/out/
chmod g+w ${v_oci360_tool}/out/

ln -s ${v_oci360_tool} ${v_oci360_home}/oci360_tool

yum clean all

##############