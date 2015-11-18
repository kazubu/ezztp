#!/bin/bash

check_linux(){
  echo -n "Checking OS : "
  if [ `uname` != 'Linux' ]; then
    echo 'This script could be execute under Linux Environment.'
    exit 1
  fi
  echo "Running with `uname`"
}

check_bash(){
  echo -n "Checking Shell : "
  if [ `readlink /proc/$$/exe` = '/bin/bash' ]; then
    echo 'Running with bash.'
    return 0
  fi
  echo 'This script reqires running with bash.'
  exit 2
}

check_root(){
  echo -n "Checking User : "
  if [ ${EUID:-${UID}} -ne 0 ]; then
    echo 'This script requires root privilege.'
    exit 3
  fi
  echo "This script running as root."
}

check_exist_file(){
  fname=$1
  if [ -e $fname ];then
    echo "${fname} is exist."
    return 0
  fi
  echo "${fname} is not exist."
  exit 4
}

set -e
cd `dirname $0`

check_linux
check_bash
check_root

echo "Checking required files... : "
check_exist_file ./sysconf/generate-system-configurations.rb
check_exist_file ./sysconf/ezztp_default_config.erb
check_exist_file ./sysconf/interfaces.erb
echo "OK."

echo 'Starting Network Configuration...'
pushd sysconf
/usr/bin/env ruby ./generate-system-configurations.rb -f
popd

echo 'Configuration auto start related daemons...'
update-rc.d ezztp-ftp defaults
update-rc.d ezztp-dhcpd defaults

echo 'Starting EzZTP Initial Configuration...'
pushd /home/ezztp/ezztp
chown -R ezztp:ezztp .
sudo -u ezztp /bin/bash ./init.sh
popd

