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
check_exist_file ./sysconf/nginx/default
check_exist_file ./sysconf/init.d/ezztp-ftp
check_exist_file ./sysconf/init.d/ezztp-dhcpd
echo "OK."

aptitude update
aptitude safe-upgrade -Ry

# Ruby/Nginx/Passenger Configuration
aptitude install -Ry curl build-essential python-software-properties ruby-dev libsqlite3-dev

grep passenger /etc/apt/sources.list.d/passenger.list || gpg --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
grep passenger /etc/apt/sources.list.d/passenger.list || gpg --armor --export 561F9B9CAC40B2F7 | sudo apt-key add -

aptitude install -Ry apt-transport-https
grep passenger /etc/apt/sources.list.d/passenger.list || echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' >> /etc/apt/sources.list.d/passenger.list
chown root: /etc/apt/sources.list.d/passenger.list
chmod 600 /etc/apt/sources.list.d/passenger.list
aptitude update

aptitude install -Ry nginx-full passenger

sed -i "s/# passenger_root/passenger_root/g" /etc/nginx/nginx.conf
sed -i "s/# passenger_ruby/passenger_ruby/g" /etc/nginx/nginx.conf
cp ./sysconf/nginx/default /etc/nginx/sites-available/default

grep ezztp /etc/passwd || useradd -m -s /sbin/nologin ezztp
rm -rf /home/ezztp/ezztp
cp -rf ./webapp/ezztp /home/ezztp/

pushd /home/ezztp/ezztp
gem install bundler
bundle install
chown -R ezztp:ezztp /home/ezztp/ezztp
popd

/etc/init.d/nginx stop
/etc/init.d/nginx start

gem install --no-ri --no-rdoc ftpd rest-client 
cp ./sysconf/init.d/ezztp-ftp /etc/init.d/ezztp-ftp
cp ./sysconf/init.d/ezztp-dhcpd /etc/init.d/ezztp-dhcpd
