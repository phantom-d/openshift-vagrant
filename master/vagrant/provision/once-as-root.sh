#!/usr/bin/env bash

#== Import script args ==

app_path=$(echo "$1")
timezone=$(echo "$2")
web_console=$(echo "$3")
web_apps=$(echo "$4")
web_node=$(echo "$5")
version=$(echo "$6")
ip=$(echo "$7")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision script: 'once-as-root.sh', user: `whoami`"

info "Install additional software"
yum -y install epel-release
yum -y install docker wget git ansible screen mc htop
yum -y install puthon-cryptography pyOpenSSL.x86_64
yum -y install ansible
info "Done!"

info "Install Openshift cluster"
cd /usr/src
git clone https://github.com/openshift/openshift-ansible

cp -f ${app_path}/vagrant/config/invetory.erb ./invetory.erb
sed -i "s/__WEBCONSOLE__/${web_console}/g" ./invetory.erb
sed -i "s/__WEBCONSOLEIP__/${ip}/g" ./invetory.erb
sed -i "s/__VERSION__/${version}/g" ./invetory.erb
sed -i "s/__WEBAPPS__/${web_apps}/g" ./invetory.erb
sed -i "s/__WEBNODE__/${web_node}/g" ./invetory.erb

mkdir -p ~/.ssh/
[ -f ~/.ssh/id_rsa ] && rm -f ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
info "Done!"

info "Configure screen"
[ -f /etc/screenrc ] && rm -f /etc/screenrc
[ -L /etc/screenrc ] && rm -f /etc/screenrc
ln -s `echo ${app_path}`/vagrant/config/screenrc /etc/screenrc
info "Done!"

info "Configure locales"
localectl set-locale LANG=ru_RU.utf8
info "Done!"

info "Create bash-alias for root user"
echo 'alias app="cd '${app_path}'"' | tee /root/.bash_aliases
echo 'alias logs="cd '${app_path}'/vgrant/logs"' | tee -a /root/.bash_aliases
info "Done!"

if [ -z "`grep -i 'force_color_prompt' /root/.bashrc`" ]; then
    info "Enabling colorized prompt for guest console"
    cat >> /root/.bashrc<<-FILE

force_color_prompt=yes

if [ -n "\$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "\$color_prompt" = yes ]; then
    PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ '
else
    PS1='\${debian_chroot:+(\$debian_chroot)}\u@\h:\w\\$ '
fi

unset color_prompt force_color_prompt

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

FILE
fi

echo "ansible-playbook -i /usr/src/invetory.erb /usr/src/openshift-ansible/playbooks/byo/config.yml"
echo "htpasswd -b /etc/origin/master/htpasswd admin openshift"
echo "Script: 'once-as-root.sh'. Done"
