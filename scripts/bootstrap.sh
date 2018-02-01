#!/usr/bin/env bash

## Source of the vercomp function: https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
# vercomp () {
#     if [[ $1 == $2 ]]
#     then
#         return 0
#     fi
#     local IFS=.
#     local i ver1=($1) ver2=($2)
#     # fill empty fields in ver1 with zeros
#     for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
#     do
#         ver1[i]=0
#     done
#     for ((i=0; i<${#ver1[@]}; i++))
#     do
#         if [[ -z ${ver2[i]} ]]
#         then
#             # fill empty fields in ver2 with zeros
#             ver2[i]=0
#         fi
#         if ((10#${ver1[i]} > 10#${ver2[i]}))
#         then
#             return 1
#         fi
#         if ((10#${ver1[i]} < 10#${ver2[i]}))
#         then
#             return 2
#         fi
#     done
#     return 0
# }

LOOKY_BRANCH='master'

# Grub config (reverts network interface names to ethX)
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
DEFAULT_GRUB=/etc/default/grub

# Ubuntu version
UBUNTU_VERSION="$(lsb_release -r -s)"

# Webserver configuration
PATH_TO_LOOKY='/home/looky/lookyloo'
LOOKY_BASEURL=''
FQDN='localhost'

echo "--- Installing Lookyloo… ---"

# echo "--- Configuring GRUB ---"
#
# for key in GRUB_CMDLINE_LINUX
# do
#     sudo sed -i "s/^\($key\)=.*/\1=\"$(eval echo \${$key})\"/" $DEFAULT_GRUB
# done
# sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "--- Updating packages list ---"
sudo apt-get -qq update


echo "--- Install base packages ---"
sudo apt-get -y install curl net-tools gcc git make sudo vim zip python3-dev python3-pip > /dev/null 2>&1

echo "--- Install docker packages ---"
sudo apt install docker.io
sudo docker pull scrapinghub/splash
sudo docker run -p 8050:8050 -p 5023:5023 scrapinghub/splash --disable-ui --disable-lua

echo "--- Retrieving Lookyloo ---"
cd $PATH_TO_LOOKY/..
sudo -u looky git clone https://github.com/CIRCL/lookyloo.git
cd $PATH_TO_LOOKY
sudo -u looky git config core.filemode false
sudo pip3 install uwsgi
sudo pip3 install -r requirements.txt
sudo pip3 install -e .
wget https://d3js.org/d3.v4.min.js -O lookyloo/static/d3.v4.min.js

echo "--- Install nginx ---"
sudo apt install nginx

echo "\e[32mLookyloo is ready\e[0m"
echo "Login and passwords for the Lookyloo image are the following:"
#echo "Web interface (default network settings): $LOOKY_BASEURL"
echo "Shell/SSH: looky/loo"
