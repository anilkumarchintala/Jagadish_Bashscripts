#!/bin/bash
# Author: jagadish.uddandam@oracle.com


OCICURLFILE="/home/oracle/bash_scripts/ocicurl.sh"

. ${OCICURLFILE}

read -p "Enter the Tenancy name:"  NAMESPACE
read -p "Region:" region
read -p "bucketName:" bucketName
read -p "Filename:" FileName
echo -e "Enter your choice:"
echo -e "1.) To put an object"
echo -e "2.) To verify an object"
read CHOICE

case $CHOICE in
    1)
      oci-curl objectstorage.${region}.oraclecloud.com PUT /root/bin/${FileName} "/n/${NAMESPACE}/b/${bucketName}/o/${FileName}"
      if [ $? = 0 ];then
          echo "File upload comlpeted"
      else
          echo "Failed to upload"
      fi
      ;;
    2)
      oci-curl objectstorage.${region}.oraclecloud.com GET "/n/${NAMESPACE}/b/${bucketName}/o/${FileName}" > /root/bin/restore.tgz
      ;;
esac