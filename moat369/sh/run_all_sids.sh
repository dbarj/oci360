#!/bin/sh
# moat369 collector

if [ $# -eq 0 ]
then
  TOOLFDR="--"
elif [ $# -eq 1 ]
then
  TOOLFDR="$1"
elif [ $# -ge 2 ]
then
  echo "Wrong Call."
  exit 1
fi

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=/usr/xpg4/bin/awk
  SEDCMD=/usr/xpg4/bin/sed
  GRPCMD=/usr/xpg4/bin/grep
  PRCCMD="ps -ef -o comm"
  ORATAB=/var/opt/oracle/oratab
else
  AWKCMD=awk
  SEDCMD=sed
  GRPCMD=grep
  PRCCMD="ps axo cmd"
  ORATAB=/etc/oratab
fi


ORIG_PATH=$PATH
ORIG_ORACLE_SID=$ORACLE_SID
ORIG_ORAENV_ASK=$ORAENV_ASK
which oraenv >/dev/null || export PATH=$PATH:/usr/local/bin

for INST in $($PRCCMD | $GRPCMD ora_pmo[n] | $SEDCMD 's/^ora_pmon_//' | $GRPCMD -v "$SEDCMD "); do
  if [ $INST = "$( cat $ORATAB | $GRPCMD -v ^# | $GRPCMD -v ^$ | $AWKCMD -F: '{ print $1 }' | $GRPCMD $INST | head -1)" ]; then
    echo "$INST: instance name = db_unique_name (single instance database)"
    export ORACLE_SID=$INST; export ORAENV_ASK=NO; . oraenv
  else
    # remove last char (instance nr) and look for name again
    LAST_REMOVED=$(echo "${INST:0:$(echo ${#INST}-1 | bc)}")
    if [ $LAST_REMOVED = "$( cat $ORATAB | $GRPCMD -v ^# | $GRPCMD -v ^$ | $AWKCMD -F: '{ print $1 }' | $GRPCMD $LAST_REMOVED )" ]; then
      echo "$INST: instance name with last char removed = db_unique_name (RAC: instance number added)"
      export ORACLE_SID=$LAST_REMOVED; export ORAENV_ASK=NO; . oraenv; export ORACLE_SID=$INST
    elif [[ "$(echo $INST | $SEDCMD 's/.*\(_[12]\)/\1/')" =~ "_[12]" ]]; then
      # remove last two chars (rac one node addition) and look for name again
      LAST_TWO_REMOVED=$(echo "${INST:0:$(echo ${#INST}-2 | bc)}")
      if [ $LAST_TWO_REMOVED = "$( cat $ORATAB | $GRPCMD -v ^# | $GRPCMD -v ^$ | $AWKCMD -F: '{ print $1 }' | $GRPCMD $LAST_TWO_REMOVED )" ]; then
        echo "$INST: instance name with either _1 or _2 removed = db_unique_name (RAC one node)"
        export ORACLE_SID=$LAST_TWO_REMOVED; export ORAENV_ASK=NO; . oraenv; export ORACLE_SID=$INST
      fi
    else
      echo "Couldn't find instance $INST in $ORATAB"
      continue
    fi
  fi
  sqlplus -s /nolog <<EOF
  connect / as sysdba
  $(echo -e ${TOOLFDR})
  @@moat369/sql/moat369_0a_main.sql
EOF
  #zip -qmT esp_requirements_host_$INST.zip res_requirements_*.txt esp_requirements_*.csv cpuinfo_model_name.txt
  #zip -qmT esp_requirements_host_$INST.zip res_requirements_stp_*.txt esp_requirements_stp_*.csv
done

export PATH=$ORIG_PATH
export ORACLE_SID=$ORIG_ORACLE_SID
export ORAENV_ASK=$ORIG_ORAENV_ASK
