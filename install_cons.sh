#!/bin/bash

# Consultant+ is a popular Russian legislation assistance system
# http://en.wikipedia.org/wiki/Consultant_Plus
# This script intended to automate installation under Linux
# Tested under Ubuntu Linux, pls let me know if it fails/succeds under other distros
# Distributed under Creative Commons lincense

SERVER=arsenevmis
SERVER_IP=192.168.0.2
CONS_PATH=Veda3000/CONS/
HOSTS_FILE=/etc/hosts
MOUNT_POINT=/media/CONS
EGID=`id -g`
ESCAPED_FULLPATH=`python -c "import re;print re.escape('${SERVER}/${CONS_PATH}')"`
MOUNT_OPTIONS=users,uid=${EUID},gid=${EGID},username=`whoami`,,password=,iocharset=utf8

#smbfs is not in Ubuntu 14.04 repositories. To let it fail silently, it is installed separately
sudo apt-get install smbfs
sudo apt-get install cifs-utils wine wine-gecko

#create mount point
if [ ! -d ${MOUNT_POINT} ]; then
    sudo mkdir -p ${MOUNT_POINT}
fi

#add server record to hosts file
#you know, just in case this machine doesn"t use WINS
if grep -q ${SERVER} ${HOSTS_FILE}; then
    sudo sed -i "/#Consultant/d" ${HOSTS_FILE}
    sudo sed -i "/${SERVER}/d" ${HOSTS_FILE}
fi

echo "
#Consultant+
${SERVER_IP} ${SERVER}
" | sudo tee -a ${HOSTS_FILE}

#add record to fstab
if grep -q ${ESCAPED_FULLPATH} /etc/fstab; then
    sudo sed -i "/#Consultant/d" /etc/fstab
    sudo sed -i "/${ESCAPED_FULLPATH}/d" /etc/fstab
fi

echo "
#Consultant+
//${SERVER}/${CONS_PATH}      ${MOUNT_POINT}     cifs  auto,rw,${MOUNT_OPTIONS}  0  0
" | sudo tee -a /etc/fstab

#mount Consultant+ share
sudo mount.cifs //${SERVER}/${CONS_PATH} ${MOUNT_POINT} -o ${MOUNT_OPTIONS}


#copy conslin driver
#expected to have one in root of Consultant share
if [ -f ${MOUNT_POINT}/conslin ]; then
    sudo cp ${MOUNT_POINT}/conslin /usr/local/bin
else
    sudo wget -O /usr/local/bin/conslin https://raw.githubusercontent.com/user2589/conslinux/master/conslin
fi
sudo chmod a+x /usr/local/bin/conslin

if grep -q conslin /etc/rc.local; then
    sudo sed -i "/#Consultant/d" /etc/rc.local
    sudo sed -i "/conslin/d" /etc/rc.local
fi

sudo sed -i "/^exit 0/i #Consultant+\n/usr/local/bin/conslin" /etc/rc.local

sudo /usr/local/bin/conslin&

#create wine drive
mkdir -p ~/.wine/dosdevices
ln -s ${MOUNT_POINT} ~/.wine/dosdevices/y:

wine Y:\\cons.exe /group /LINUX

rm ~/{Desktop,Рабочий\ стол}/ConsultantPlus.lnk

if ! grep -q LINUX ~/{Desktop,Рабочий\ стол}/ConsultantPlus.desktop; then
    sed -i "s/Cons.exe/Cons.exe \/LINUX/i" ~/{Desktop,Рабочий\ стол}/ConsultantPlus.desktop
fi
