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
DEFAULT_GRUB="/etc/default/grub"

# Ubuntu version
UBUNTU_VERSION="$(lsb_release -r -s)"

# Webserver configuration
PATH_TO_LOOKY='/home/looky/lookyloo'
LOOKY_BASEURL=''
FQDN='localhost'

SECRET_KEY="$(openssl rand -hex 32)"

export WORKON_HOME=~/lookyloo

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
sudo apt-get -y install curl net-tools gcc git make sudo vim zip python3-dev python3-pip python3-virtualenv virtualenvwrapper > /dev/null 2>&1

echo "--- Install docker packages ---"
sudo apt-get -y install docker.io
sudo docker pull scrapinghub/splash

echo "--- Retrieving and setting up Lookyloo ---"
cd ~looky
sudo -u looky git clone https://github.com/SteveClement/lookyloo.git
cd $PATH_TO_LOOKY
sudo cp ${PATH_TO_LOOKY}/etc/rc.local /etc/
sudo usermod -a -G looky www-data
sudo chmod g+rw ${PATH_TO_LOOKY}
sudo -u looky git config core.filemode false
. /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh
mkvirtualenv -p /usr/bin/python3 lookyloo
pip install uwsgi
pip install -r requirements.txt
pip install -e .
wget https://d3js.org/d3.v4.min.js -O lookyloo/static/d3.v4.min.js

echo "--- Install nginx ---"
sudo apt-get -y install nginx

echo "--- Copying config files ---"
sudo cp etc/nginx/sites-available/lookyloo /etc/nginx/sites-enabled/
sudo cp etc/systemd/system/lookyloo.service /etc/systemd/system/
sed -i "s/<CHANGE_ME>/looky/g" etc/nginx/sites-available/lookyloo
sed -i "s/<CHANGE_ME>/looky/g" etc/systemd/system/lookyloo.service
sed -i "s/<MY_VIRTUALENV_PATH>/.virtualenvs\/lookyloo/g" etc/systemd/system/lookyloo.service
sed -i "s/changeme/${SECRET_KEY}/g" lookyloo/__init__.py

sudo cp etc/nginx/sites-available/lookyloo /etc/nginx/sites-available/
sudo cp etc/systemd/system/lookyloo.service /etc/systemd/system/
sudo ln -sf /etc/nginx/sites-available/lookyloo /etc/nginx/sites-enabled/default

echo "\e[32mLookyloo is ready\e[0m"
echo "Login and passwords for the Lookyloo image are the following:"
#echo "Web interface (default network settings): $LOOKY_BASEURL"
echo "Shell/SSH: looky/loo"
