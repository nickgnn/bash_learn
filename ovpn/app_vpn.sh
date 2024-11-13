#!/bin/bash

# если файл существует
if [[ -f "./env.sh" ]]; then
  echo "Use env variables from file ${PWD}/env.sh"
  source ./env.sh
fi

workUsr="${WORKING_USER}"
workDir="/home/${WORKING_USER}"
pswrd="${PASSWORD}"
workConf="${WORKING_CONFIG}"

update() {
  echo ""
  echo "Update..."
  echo ""
  apt update -y && apt upgrade -y
  apt-get update && apt dist-upgrade -y
}

addUser() {
  echo ""
  echo "Add user..."
  echo ""
  useradd -d "${workDir}" -m -s /bin/bash "${workUsr}"
  ls -l /home
}

setPasswd() {
  echo ""
  echo "PASSWD SET..."
  echo ""
  echo "${pswrd}" | passwd "${workUsr}"
}

addSudo() {
  usermod -G sudo -a "${workUsr}"
  echo ""
  echo "SUDO ADDED:)"
  echo ""
}

pubkey_on() {
  echo ""
  echo "PUBKEY ON..."
  echo ""

  echo "${PWD}"

  sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
  sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  sed -i 's/#KerberosAuthentication no/KerberosAuthentication no/' /etc/ssh/sshd_config && \
  sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

  service sshd restart
}

pubkey_off() {
  echo ""
  echo "PUBKEY ON..."
  echo ""

  echo "${PWD}"

  sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config && \
  sed -i 's/PubkeyAuthentication yes/#PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i 's/PasswordAuthentication no/#PasswordAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i 's/KerberosAuthentication no/#KerberosAuthentication no/' /etc/ssh/sshd_config && \
  sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

  service sshd restart
}

instll_ovpn(){
  echo ""
  echo "INSTALL OVPN..."
  echo ""

  cd "${workDir}" || exit

  ls -l
  echo "${PWD}"
  wgt
  call_script_ovpn
  mv /root/"${workConf}".ovpn "${workDir}"/"${workConf}".ovpn
  chown "${workUsr}" "${workDir}"/"${workConf}".ovpn
  ls -l "${workDir}"/
}

ssh_keys() {
  echo ""
  echo "SSH KEYS..."
  echo ""

  cd "${workDir}" || exit

  mkdir .ssh

  cd .ssh/ || exit

  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDn5Ur5uvyYracySZa4eYPmbnF/PUx6gt5HBYXKKye5K0VBJri/JL8NwjYVD7i+ezS5ySiQ/CJQ/Qk0O8hsMllryAy+N4QZ2yv3eTTzblGGFrJmWPs7zwImiHAhb/CagsLS7Gw4+lg3w3C0H8iRJSW1ZKKCfmmxIWO/7d6s7ZRqe5FQ1mZcMhisTmbOGDDOXakAMwOpPx84X3/9jT7Yh0nbw4pCImjLGLtqtswsPVVoV69Cw2PmKObE7RbKc1lTp4ZIhmFnvMokBA96p6YsF8uuS02xWD/kEDZaL8z2s8Uu7zswdOFSDg5EVgjgswL3ijJ4UGVo/kvlThJq1V9Qu0fiaE7IkTrDpj3ZOvbtI38AdhxU7q30YMyXRvTDnACZAUx9XOF4JSngnnKVeVqxpR3V+fS84MfWa8UHbxA6cDcsikTIB3FdJ5/VKlDNP2p0I+GYJKVTQlSFP8Iy1aPVezRPfyZws9yX6l1NtztvmjumGZZLGdhSlxhT7U7QO9ka9LU= pispo@15s-eq2094ur" >> authorized_keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCre1PgEP1K96gSDr7/UHjuu02e4t4avf/5fNd7+qmHd65gaINH9N643OGmpf8/WlF8o0WDQdIB0re+tb0E+r0JxSdWKFPYTBRLc72eWEkG/zWE8lXCiwi3UCCFbowKhpRfgbNb4wcDAD7172ZURZWunnKuyfDZRKECQSo0qvIEoWPG7HGyT+Vs7+Lj8BXAvOyVwvibGEBSUYQpSAch6J6KkEgjw0NDfHDtSL6Ah3mmxDB5K6v0SwviwutbaoN48B7qnq7dAceJl1mTu6SFjJ7TpZoksGFGLFFZyjmwEpOCEwhkdt0Syyv21Cg51pjYgbpZfQKYcDYsKT6HW+aKrOxPXKrZZg9wnzKyNEgBTzCHwaFibG7ggM9Ql6UJ0gIjB8msORoBjQCEs6RW09UFGv7uZ0e9s8zZIAGJ9pkOd2lhJtgIolLAYZlEPWO2bblndpmf4k8ixiwE1DdVPjQxAE5s2bptovNhYsw5qQRn/9SIQtNyZH6k98RxWkxoENFDAss= gnn@FORMULA-mint" >> authorized_keys
}

ufw_on() {
  echo ""
  echo "UFW ON..."
  echo ""

  ufw allow 22/tcp
  ufw allow 1194/udp
  echo y | ufw enable
  ufw status
}

instUtils() {
  apt install vim htop tree mc tmux policycoreutils iperf3 net-tools vnstat bwm-ng iftop nload wget cron -y
}

ufw_off() {
  ufw disable
}

dropUser() {
  deluser --remove-all-files "${workUsr}"
  dropHome
}

dropHome() {
  cd /home || exit
  rm -rfv "${workUsr}"
}

rm_ovpn() {
  echo ""
  echo "Delete OVPN..."
  echo ""

  cd "${workDir}" || exit

  ls -l
  echo "${PWD}"
  call_script_ovpn
}

wgt() {
  echo ""
  echo "Wget..."
  echo ""
  wget https://git.io/vpn -O openvpn-install.sh
}

call_script_ovpn() {
  bash ./openvpn-install.sh
}

update
addUser
setPasswd
addSudo
pubkey_on
instll_ovpn
ssh_keys
ufw_on
instUtils

#pubkey_off
#ufw_off
#rm_ovpn
#dropUser

