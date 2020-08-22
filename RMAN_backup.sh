#!/bin/bash

### RMAN Backup script

rmanscriptpath=/home/oracle/bash_scripts
rmanlogpath=/home/oracle/bash_scripts
scriptdatetime=$(date --date "now" +%Y%m%d%H%M)
scriptdate=$(date --date "now" +%Y%m%d)

O_HOME=$(awk -F":" '!/ASM/ && !/^$/ && !/^#/ { print $2 }' /etc/oratab)
#DB_UNQ_NAME=( $(${ORACLE_HOME}/bin/srvctl config database) )

#inst_run=( $(ps -ef|grep pmon | awk -F"_" '/ora_/ { print $NF }') )
#init_inst=( $(ls -l $ORACLE_HOME/dbs/ | awk '/init/ { print $NF }' | sed -e 's/init//g' -e 's/.ora.*//g' -e '/^$/d' | uniq ) )

for i in ${O_HOME}; do
    init_inst=$(ls -l $O_HOME/dbs/ | awk '/init/ { print $NF }' | sed -e 's/init//g' -e 's/.ora.*//g' -e '/^$/d' | uniq )
    for j in ${init_inst};do
      chk=$(ps -ef|grep pmon | awk -F"_" '/ora_/ { print $NF }' | grep -w ${j})
      if [ -z  ${chk} ];then
        continue
      fi
    export ORACLE_HOME=${O_HOME}
    export ORACLE_SID=${j}

#  Checking if RMAN is running on Not

   if [ ! `ps -ef | grep -E '(\s|\/)rman\s' | grep -v grep | grep -v rmanBackup.sh| grep -v stats_|grep -v check_|grep -v tail|grep -v vi |wc -l` -eq 0 ];then
      echo "RMAN process currently running. $(hostname -s) $j $(date)" >> ${rmanlogpath}/rman_${j}_${scriptdate}.log
      exit 1
   fi

   ${O_HOME}/bin/rman target / cmdfile=${rmanscriptpath}/${1} log=${rmanlogpath}/rman_${j}_${scriptdate}.log append  >/dev/null 2>&1
   done
init_inst=""
done

