#!/bin/bash
# This script is to validate standard DB server memory parameters
# Author : jagadish.uddandam@oracle.com

declare -a Sga

FuncREADOSPARAMS () {

Ram=$(free -b | awk '/Mem/ {print $2}')                                                      # RAM in Bytes
Shmax=$(awk '/^kernel.shmmax/ {print $3}' /etc/sysctl.conf)                                  # SHAMMAX in bytes
Shpages=$(awk '/^kernel.shmall/ {print $3}' /etc/sysctl.conf)                                # SHMALL in pages
Smemlock=$(awk '!/^#/ && !/^*/ && /soft|Soft/ && /memlock/ {print $4}' /etc/security/limits.conf | uniq | tail -n1)     # Soft memlock in KB
Hmemlock=$(awk '!/^#/ && !/^*/ && /hard|Hard/ && /memlock/ {print $4}' /etc/security/limits.conf | uniq | tail -n1)     # Hard memlock in KB
Hugepages_T=$(awk '/HugePages_Total/ {print $2}' /proc/meminfo)                              # Hugh pages total
 }

FuncDBINSTANCESCHECK () {

ORA_HOMES=$(awk '!/^$|^#/ {print $0}' /etc/oratab | cut -d":" -f2 | uniq)
for i in ${ORA_HOMES[@]}; do
  echo -e "\n\e[31mInstances running from \"$i\" on this server(SGA,PGA in Bytes)\e[0m"
  export ORACLE_HOME=${i}
  init_files=$(ls $i/dbs | awk '/init/ {print $0}'| sed -e 's/init//g' -e 's/_.$//' -e 's/.ora_*$//' -e '/^$/d')
     for j in ${init_files}; do
       instances+=$(ps aux|awk '/_pmon_/ {print $NF}'|grep -v "NF"| cut -d"_" -f3 |grep -w "${j}")" "
     done
      if [ ${#instances[@]} = 0 ]; then
       echo -e "\e[32mThere are no instances running from this Home\e[0m"
      else
      for k in ${instances[@]}; do
      export ORACLE_SID=${k}
           # "-" is used before EOF as to allow indentation when closing HERE documents with EOF but only to use tabs
      Sga+=( `${i}/bin/sqlplus -s / as sysdba <<-EOF
set pagesize 0 heading off  feedback off
select replace(upper(value),' ','')
from v\\$parameter where name='sga_max_size';
EOF` )
#it is is used tabs for space , but not actuals spaces
# "-" is used before EOF as to allow indentation when closing HERE documents with EOF but only to use tabs
      Pga+=( `${i}/bin/sqlplus -s / as sysdba <<-EOF
set pagesize 0 heading off  feedback off
select replace(upper(value),' ','')
from v\\$parameter where name='pga_aggregate_target';
EOF` )
#it is is used tabs for space , but not actuals spaces
       echo -e "-->\e[32m ${k} \t SGA = ${Sga[${#Sga[@]}-1]} ,PGA = ${Pga[${#Pga[@]}-1]} \e[0m"
#       echo -e "-->\e[32m ${k} \t SGA = ${#Sga[@]} \e[0m"
      done
      fi
    instances=""
    init_files=""
done
}

Display () {

echo -e "\n\e[33mkernel Information:\e[0m"
echo -e "\e[31mCurrent:\e[0m"
if [ ! -z "${Shmax}" ];then
 echo -e "-->\e[32mkernel.shmmax = $(echo ${Shmax}) bytes \e[0m"
else
 echo -e "-->\e[32mkernel.shmmax = NOTCONFIGURED\e[0m"
fi
if [ ! -z "${Shpages}" ];then
 echo -e "-->\e[32mkernel.shmall = $(echo ${Shpages}) pages\e[0m"
else
 echo -e "-->\e[32mkernel.shmall = NOTCONFIGURED\e[0m"
fi
if [ ! -z "$Smemlock}" ];then
 echo -e "-->\e[32msoft memlock = $(echo ${Smemlock}) kb\e[0m"
else
 echo -e "-->\e[32msoft memlock = \e[31mNOTCONFIGURED\e[0m"
fi
if [ ! -z "${Hmemlock}" ];then
 echo -e "-->\e[32mhard memlock = \e[32m$(echo ${Hmemlock}) kb\e[0m"
else
 echo -e "-->\e[32mhard memlock = \e[31mNOTCONFIGURED\e[0m"
fi

echo -e "\e[31mExpected: \e[0m"
echo -e "-->\e[32mkernel.shmmax --> ${STDSHMMAX}\e[0m"
echo -e "-->\e[32mkernel.shmall -->${STDSHMALL}\e[0m"
echo -e "-->\e[32msoft memlock -->${STDSMEMLOCK}\e[0m"
echo -e "-->\e[32mhard memlock -->${STDHMEMLOCK}\e[0m"

}

Funcvalidation () {
s="scale=2"
Totalsga=0
totalpga=0
#STDSHMMAX="$(echo "${s}; ${Ram} * 0.8" | bc)"
STDSHMMAX="$(( $(( Ram * 80 )) / 100 ))"
#STDSHMALL="$(echo "${s}; ${STDSHMMAX} / 4096" | bc)"
STDSHMALL="$(( STDSHMMAX / 4096 ))"
#STDSMEMLOCK="$(echo "${s}; ${Ram} * 0.9" | bc)"
STDSMEMLOCK="$(( $(( Ram * 90 )) / 102400 ))"
STDHMEMLOCK="${STDSMEMLOCK}"
echo -e "\n-->\e[32mPHYSICAL SERVER MEMORY = $(expr $(expr ${Ram} / 1024 ) / 1024 )Mb\e[0m"
for i in ${Sga[@]}; do
#echo -e "${i}"
Totalsga=$((Totalsga + i))
done
echo -e "-->\e[32mTotalSGA on the system = ${Totalsga} bytes \e[0m"
for m in ${Pga[@]}; do
#echo -e "${m}"
Totalpga=$((Totalpga + m))
done
echo -e "-->\e[32mTotalPGA on the system = ${Totalpga} bytes \e[0m"
DBUSAGE=$(( Totalsga + Totalpga ))
RAMPERCENT=$(( $(( Ram * 75 )) / 100 ))
if [ ${DBUSAGE} -le ${RAMPERCENT} ];then
echo -e "\n\e[1mTotal (SGA + PGA) < 75% of SERVER MEMORY. LOOKS GOOD\e[0m"
else
echo -e "\n\e[1mTotal (SGA + PGA) > 75% of SERVER MEMORY..Please ensure Total(SGA+PGA) below or Equal to 75%\e[0m"
fi
Totalsga=$((Totalsga + 2147483648))
STDHUGEPAGES="$((Totalsga/2097152))"
}



######## Main Script #########


FuncREADOSPARAMS

if [ -f /etc/oratab ]; then
 FuncDBINSTANCESCHECK
else
 echo -e "\e[31mTHIS IS NOT A DB SERVER\e[0m\n"
 exit 1
fi

Funcvalidation

if [ $Hugepages_T = 0 ]; then
 echo -e "\e[33m\nHugepages not configured on this system\e[0m"
 echo -e "Note:Please check with SYSTEM Team if this VM supports Hugepages or Not"
 echo -e "   PVM machine wont support Hugepages on recent and some legacy OVM versions\n"
 Display
else
 echo -e "\e[33m\nHUGEPAGES CONFIGURED ON THE SYSTEM\e[0m"
 echo -e "\e[32mCurrent = ${Hugepages_T}\e[0m"
 echo -e "\e[32mExpected = ${STDHUGEPAGES}\e[0m"
 Display
fi


#### Checking if Hugh pages & kernel parameters are as per the standard #####

echo -e "\n"
echo -e "You have got all what you want.Agree? if not tell us\n"
