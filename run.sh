#!/bin/bash

MAPR_HOST=maprdemo.mapr.io 
MAPR_USER=mapr
MAPR_GROUP=mapr
service ssh start
echo "ssh accessible using: ssh -p 2222 root@localhost"

echo "${MAPR_HOST}" > /etc/hostname 

IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
HOSTNAME=$(hostname -f)
head -n -1  /etc/hosts > tmp.txt && cp tmp.txt /etc/hosts && rm tmp.txt
echo "$IP  ${MAPR_HOST} ${HOSTNAME}" >> /etc/hosts
echo "session       required       pam_limits.so" >> /etc/pam.d/common-session

/opt/mapr/server/configure.sh -N ${MAPR_HOST} -C ${MAPR_HOST}:7222 -Z ${MAPR_HOST} -u ${MAPR_USER} -g ${MAPR_GROUP} 
# -genkeys -secure -dare
service mapr-posix-client-basic start

/bin/bash
