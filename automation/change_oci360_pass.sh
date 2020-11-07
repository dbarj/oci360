#!/bin/bash
# v1.0
set -eo pipefail

trap_err ()
{
  echo "Error on line $1 of \"setup_oci360.sh\"."
  exit 1
}

trap 'trap_err $LINENO' ERR

[ "$(id -u -n)" != "root" ] && echo "Must be executed as root! Exiting..." && exit 1

v_oci360_pass="$1"

[ -z "$1" ] && echo "First parameter must be the OCI360 password." && exit 1

v_cmd=$(cat <<EOF
set -eo pipefail
. oraenv <<< "XE"

sqlplus /nolog <<EOM
whenever sqlerror exit sql.sqlcode
conn / as sysdba
alter session set container=XEPDB1;
alter user OCI360 identified by "${v_oci360_pass}";
exit
EOM
EOF
)

su - oracle -c "bash -s" < <(echo "$v_cmd")

exit 0
##############