#!/bin/bash -e

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

echo "Your current shell is ${SHELL}"

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
sudo -u looky mkdir ~/.virtualenvs
sudo -u looky ln -s ${PATH_TO_LOOKY}/venv ~/.virtualenvs/lookyloo
cd $PATH_TO_LOOKY
sudo cp ${PATH_TO_LOOKY}/etc/rc.local /etc/
sudo usermod -a -G looky www-data
sudo chmod g+rw ${PATH_TO_LOOKY}
sudo -u looky git config core.filemode false
sudo ${PATH_TO_LOOKY}/install_dependencies.sh

echo "--- Install nginx ---"
sudo apt-get -y install nginx

echo "--- Copying config files ---"
sed -i "s/<CHANGE_ME>/looky/g" $PATH_TO_LOOKY/etc/nginx/sites-available/lookyloo
sed -i "s/<CHANGE_ME>/looky/g" $PATH_TO_LOOKY/etc/systemd/system/lookyloo.service
sed -i "s/<MY_VIRTUALENV_PATH>/.virtualenvs\/lookyloo/g" $PATH_TO_LOOKY/etc/systemd/system/lookyloo.service
sed -e "0,/changeme/ s/changeme/${SECRET_KEY}/" $PATH_TO_LOOKY/lookyloo/__init__.py > /tmp/__init__.py
cat /tmp/__init__.py | sudo tee $PATH_TO_LOOKY/lookyloo/__init__.py
rm /tmp/__init__.py
sudo cp $PATH_TO_LOOKY/etc/nginx/sites-available/lookyloo /etc/nginx/sites-available/
sudo cp $PATH_TO_LOOKY/etc/systemd/system/lookyloo.service /etc/systemd/system/
sudo ln -sf /etc/nginx/sites-available/lookyloo /etc/nginx/sites-enabled/default
sudo chgrp -R www-data ~looky
sudo chmod -R g+rw ~looky
sudo systemctl start lookyloo
sudo systemctl enable lookyloo

echo "\e[32mLookyloo is ready\e[0m"
echo "Login and passwords for the Lookyloo image are the following:"
#echo "Web interface (default network settings): $LOOKY_BASEURL"
echo "Shell/SSH: looky/loo"
