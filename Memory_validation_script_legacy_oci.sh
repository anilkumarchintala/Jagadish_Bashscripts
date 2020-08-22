#!/bin/bash
# This script is to validate standard DB server memory parameters
# Author : jagadish.uddandam@oracle.com

declare -a Sga
declare -i EXA_CHK

VM_MON=$(lscpu | awk -F":" '/Hypervisor/ {print $2}' |sed -e 's/[[:space:]]*//')
[ -d "/etc/oracle/cell" ]  2>/dev/null && EXA_CHK=111 || EXA_CHK=999


FuncREADOSPARAMS () {

Ram=$(free -b | awk '/Mem/ {print $2}')                                                      # RAM in Bytes
Shmax=$(awk '/^kernel.shmmax/ {print $3}' /etc/sysctl.conf)                                  # SHAMMAX in bytes
Shpages=$(awk '/^kernel.shmall/ {print $3}' /etc/sysctl.conf)                                # SHMALL in pages
Smemlock=$(awk '!/^#/ && /^*|^oracle|^grid/ && /soft|Soft/ && /memlock/ {print $4}' /etc/security/limits.conf | uniq | tail -n1)     # Soft memlock in KB
Hmemlock=$(awk '!/^#/ && /^*|^oracle|^grid/ && /hard|Hard/ && /memlock/ {print $4}' /etc/security/limits.conf | uniq | tail -n1)     # Hard memlock in KB
Hugepages_T=$(awk '/HugePages_Total/ {print $2}' /proc/meminfo)                              # Hugh pages total
 }

FuncDBINSTANCESCHECK () {

ORA_HOMES=$(awk '!/^$|^#/ {print $0}' /etc/oratab | cut -d":" -f2 | sort | uniq)
for i in ${ORA_HOMES[@]}; do
  if [[ ${i} =~ .*grid.* ]];then
     echo -e "\n\e[31mInstances running from \"$i\" on this server(SGA,PGA in Bytes)\e[0m"
     instances+=$(ps aux|awk '/_pmon_/ {print $NF}'|grep -v "NF"| cut -d"_" -f3 |grep "ASM")
        if [ ${#instances[@]} = 0 ]; then
       echo -e "\e[32mThere are no instances running from this Home\e[0m"
        else
      for k in ${instances[@]}; do
      export ORACLE_SID=${k}
      export ORACLE_HOME=${i}
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

# else condition starts here

  else
  echo -e "\n\e[31mInstances running from \"$i\" on this server(SGA,PGA in Bytes)\e[0m"
  export ORACLE_HOME=${i}
  init_files=$(ls $i/dbs | awk '/init/ {print $0}'| sed -e 's/init//g' -e 's/_.$//' -e 's/.ora_*$//' -e 's/.ora.*$//' -e '/^$/d'|uniq)
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
fi
done

}

FuncCalc () {

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
echo -e "\n-->\e[32mPHYSICAL SERVER MEMORY = $(( $(( $(( Ram / 1024 )) / 1024 )) / 1024 )) GB\e[0m"
for i in ${Sga[@]}; do
#echo -e "${i}"
Totalsga=$((Totalsga + i))
done
#echo -e "-->\e[32mTotalSGA on the system = ${Totalsga} bytes \e[0m"
echo -e "-->\e[32mTotalSGA on the system = $(( $(( $(( Totalsga / 1024 )) / 1024 )) / 1024 )) GB \e[0m"
for m in ${Pga[@]}; do
#echo -e "${m}"
Totalpga=$((Totalpga + m))
done
#echo -e "-->\e[32mTotalPGA on the system = ${Totalpga} bytes \e[0m"
echo -e "-->\e[32mTotalPGA on the system = $(( $(( $(( Totalpga / 1024 )) / 1024 )) /1024 )) GB \e[0m"
DBUSAGE=$(( Totalsga + Totalpga ))

}

FuncDisplay () {

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

FuncvalidationXen () {
FuncCalc
RAM75PER=$(( $(( Ram * 75 )) / 100 ))
if [ ${DBUSAGE} -le ${RAM75PER} ];then
 echo -e "\n\e[1mTotal (SGA + PGA) < 75% of SERVER MEMORY. LOOKS GOOD\e[0m"
else
 echo -e "\n\e[1mTotal (SGA + PGA) > 75% of SERVER MEMORY..Please ensure Total(SGA+PGA) below or Equal to 75%\e[0m"
fi
STDHUGEPAGES="$((Totalsga/2097152))"
}


FuncvalidationKVM () {
FuncCalc
RAM50PER=$(( $(( Ram * 50 )) / 100 ))
if [ ${DBUSAGE} -le ${RAM50PER} ];then
 echo -e "\n\e[1mTotal (SGA + PGA) <= 50% of SERVER MEMORY. LOOKS GOOD\e[0m"
else
 echo -e "\n\e[1mTotal (SGA + PGA) > 50% of SERVER MEMORY..Please ensure Total(SGA+PGA) below or Equal to 50%\e[0m"
fi
STDHUGEPAGES="$((Totalsga/2097152))"
}

######## Main Script #########

if [ ! -f /etc/oratab ]; then
 echo -e "\e[31mTHIS IS NOT A DB SERVER\e[0m\n"
 exit 1
fi

case "${VM_MON}" in

   "Xen"|"VMware"|"") if [ ${EXA_CHK} = 111 ];then
           echo -e "\e[32m\e[1mThis is an Exadata environment.This script wont support Exadata environment..exiting\e[0m"
           exit
          else
           echo -e "\n\e[32m\e[1mTHis is GBUCS legacy(1.0, 2.0, HGBU) environment\e[0m"
           FuncREADOSPARAMS
           FuncDBINSTANCESCHECK
           FuncvalidationXen
           if [ ${Hugepages_T} = 0 ]; then
             echo -e "\e[33m\nHugepages not configured on this system\e[0m"
             echo -e "Note:Please check with SYSTEM Team if this VM supports Hugepages or Not"
             echo -e "   PVM machine wont support Hugepages on recent and some legacy OVM versions\n"
             FuncDisplay
           else
             echo -e "\e[33m\nHUGEPAGES CONFIGURED ON THE SYSTEM\e[0m"
             echo -e "\e[32mCurrent = ${Hugepages_T}\e[0m"
             echo -e "\e[32mExpected = ${STDHUGEPAGES}\e[0m"
             FuncDisplay
           fi
          fi
          ;;

   "KVM") echo -e "\n\e[32m\e[1mTHis is GBUCS 3.0(OCI) environment\e[0m"
          FuncREADOSPARAMS
          FuncDBINSTANCESCHECK
          FuncvalidationKVM
          if [ ${Hugepages_T} = 0 ]; then
            echo -e "\e[33m\nHugepages not configured on this system\e[0m"
            echo -e "\e[33mGBUCS 3.0 by default provides hugepages\e[0m"
            FuncDisplay
          else
            echo -e "\e[33m\nHUGEPAGES CONFIGURED ON THE SYSTEM\e[0m"
            echo -e "\e[32mCurrent = ${Hugepages_T}\e[0m"
            echo -e "\e[32mExpected = ${STDHUGEPAGES}\e[0m"
            FuncDisplay
          fi
          ;;

    "*")  echo "exiting.."
          ;;
esac

echo -e "\n"
echo -e "You have got all what you want.Agree? if not tell us\n"

