#!/bin/bash
# Enable port 22 and 1521 on linux Firewall
# iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# iptables -A INPUT -p tcp --dport 1521 -j ACCEPT


Funcstatus () {
OUTPUT="$(/sbin/service iptables status)"
if [[ ${OUTPUT} =~ .*not.* ]]; then
return 1
else
return 0
fi
}


# Main script
Funcstatus
if [ "$?" = 0 ]; then
{
echo "Firewall is running"
echo "adding Firewall rules for opening 22 and 1521 port"
/sbin/iptables -A INPUT -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 22 -j ACCEPT
/sbin/service iptables save
}
else
echo "Firewall in disabled state"
fi







