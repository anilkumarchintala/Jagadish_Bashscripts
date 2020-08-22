#!/bin/bash
# servicemonitor script
# it should monitor the service continuously
# it should run indefinately and if service stops , it performs 3 things
# 1.) Restart the service
# 2.) Write a message to syslog
# 3.) send a email message to root user

if [ -z "$1" ];then
 echo "You didn't provide any arguments. Please enter arguments"
 exit 1
else
 SERVICE=$1  
fi

FuncStatus () {
STATUS="$(/sbin/systemctl ${SERVICE} status | grep -E "running")"
if [[ ${STATUS} =~ .*running.* ]]; then
 return 0
else
 return 1
fi
}



## Main script

while true; do
FuncStatus
 if [ $? = 1 ];then
  /sbin/logger Service ${SERVICE} in stopped state and starting now
  /sbin/systemctl ${SERVICE} start
  sleep 10
  /bin/logger Service ${SERVICE} started now
  /bin/mail -s "service ${SERVICE} restarted now" root@localhost < .
 else
 sleep 30
 fi
done





