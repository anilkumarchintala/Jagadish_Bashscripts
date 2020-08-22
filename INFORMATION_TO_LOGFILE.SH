#!/bin/bash

# Shows the Time and Date, lists all logged-in users, and gives the system uptime. 
# The script then saves this information to a logfile

LOGFILE=/tmp/information_`date "+%d%m%y%H%M%S"`.log

echo -e "-----------------" >> ${LOGFILE}
echo -e "Date and time : $(date "+%d-%m-%y %H%M%S") " >> ${LOGFILE}
echo -e "List of users logged are: $(who -u | awk '{ print $1 }') " >> ${LOGFILE}
echo -e "server runnign since : $(uptime -s) " >> ${LOGFILE}
exit 0


