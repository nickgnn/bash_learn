#!/bin/bash

# если файл существует
if [[ -f "./env_ocserv.sh" ]]; then
  echo "Use env variables from file ${PWD}/env_ocserv.sh"
  source env_ocserv.sh
fi

workUsr="${WORKING_USER}"
workDir="/home/${WORKING_USER}"
pswrd="${PASSWORD}"
innr_ip="${INNER_IP}"
extrl_ip="${EXTERNAL_IP}"
secretkey="${CAMOUFLAGE_SECRET}"

# 1. Ставим все необходимые пакеты для OpenConnect v1.3.0
instUtilsOC() {
  echo ""
  echo "Ставим пакеты"
  echo ""

  apt update && sudo apt install -y vim nano git build-essential ipcalc libgnutls28-dev libev-dev autoconf automake libtool libpam0g-dev liblz4-dev libseccomp-dev libreadline-dev libnl-route-3-dev libkrb5-dev libradcli-dev libcurl4-gnutls-dev libcjose-dev libjansson-dev liboath-dev libprotobuf-c-dev libtalloc-dev libhttp-parser-dev protobuf-c-compiler gperf iperf3 lcov libuid-wrapper libpam-wrapper libnss-wrapper libsocket-wrapper gss-ntlmssp haproxy iputils-ping freeradius gawk gnutls-bin iproute2 yajl-tools tcpdump

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 2. Клонируем репо последней версии https://gitlab.com/openconnect/ocserv
# можно перейти и посмотреть в браузере по тегу какая последняя версия, сейчас 1.3.0
cloneRepo() {
  echo ""
  echo "Клонируем репку"
  echo ""

  cd ~ && git clone -b 1.3.0 https://gitlab.com/openconnect/ocserv

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 3. Собираем
buildVpn() {
  echo ""
  echo "Собираем"
  echo ""

  cd ocserv || exit

  autoreconf -fvi
  ./configure && make
  make install

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 4. Скачаем конфиг
wgetConfig() {
  echo ""
  echo "Качаем конфиг"
  echo ""

  cd ~/ocserv/src && wget https://gitlab.com/openconnect/ocserv/-/raw/master/doc/sample.config

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 5. Генерируем сертификаты и ключи сервера
# Первым делом создаем темплейт для генерации ключей

genKeys() {
  echo ""
  echo "Генерируем сертификаты и ключи сервера"
  echo ""

  cd ~/ocserv/src || exit

  echo "# X.509 Certificate options

# The organization of the subject.
organization = \"sber\"

# The common name of the certificate owner.
cn = \"Example CA\"

# The serial number of the certificate.
serial = 001

# In how many days, counting from today, this certificate will expire. Use -1 if there is no expiration date.
expiration_days = -1

# Whether this is a CA certificate or not
ca

# Whether this certificate will be used to sign data
signing_key

# Whether this key will be used to sign other certificates.
cert_signing_key

# Whether this key will be used to sign CRLs.
crl_signing_key
key encipherment
encryption_key
tls_www_server" > ca-cert.cfg

  certtool --generate-privkey > ./ocserv-key.pem
  certtool --generate-self-signed --load-privkey ocserv-key.pem --template ca-cert.cfg --outfile ocserv-cert.pem

  echo "key_type = RSA
key_bits = 2048
dh_bits = 2048" > dh.conf

  certtool --generate-dh-params --load-privkey dh.conf --outfile dh.pem

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 6. Теперь создаем АККАУНТЫ VPN
# Создаем директорию с конфигами внутри ~/ocserv/src
createAccount() {
  echo ""
  echo "Создаём аккаунты"
  echo ""

  cd ~/ocserv/src || exit

  if ! [[ -d "./clients" ]]; then
    mkdir ./clients
  fi

  echo "${pswrd}" | ocpasswd -c ./clients/ocpasswd "${workUsr}"

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 7. Создаем директорию clients/configs где будем хранить клиентские конфиги с нужными IP и маршрутами
mkdirConfigs() {
  echo ""
  echo "Создаём директорию clients/configs"
  echo ""

  cd ~/ocserv/src || exit

  if ! [[ -d "./clients/configs" ]]; then
    mkdir ./clients/configs
  fi

  cd ~/ocserv/src/clients/configs || exit

  touch "${workUsr}"

  echo "explicit-ipv4 = ${innr_ip}" >> "${workUsr}"

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 8. Теперь работаем с конфигом сервера
sedConfig() {
  echo ""
  echo "Работаем с конфигом сервера"
  echo ""

  cd ~/ocserv/src || exit

  echo "${PWD}"
  cat /root/sample_main.config > sample.config
  sed -i "s/mysecretkey/${secretkey}/" sample.config

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 9. Включаем ipforwarding на сервере
ipforwardingOn() {
  echo ""
  echo "Включаем ipforwarding на сервере"
  echo ""

  sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl -p

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 10. Создаем автозапуск правил iptables (ВНИМАТЕЛЬНО СМОТРИМ НАШУ ПОДСЕТЬ, ЛОКАЛЬНЫЙ IP, И ПОРТ ИЗ КОНФИГА)
autostartIptablesRules() {
    echo ""
    echo "Создаем автозапуск правил iptables"
    echo ""

    echo "[Unit]
Before=network.target
[Service]
Type=oneshot

ExecStart=/usr/sbin/iptables -t nat -A POSTROUTING -s 10.10.16.0/24 ! -d 10.10.16.0/24 -j SNAT --to ${extrl_ip}
ExecStart=/usr/sbin/iptables -I INPUT -p tcp --dport 443 -j ACCEPT
ExecStart=/usr/sbin/iptables -I FORWARD -s 10.10.16.0/24 -j ACCEPT
ExecStart=/usr/sbin/iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

ExecStop=/usr/sbin/iptables -t nat -D POSTROUTING -s 10.10.16.0/24 ! -d 10.10.16.0/24 -j SNAT --to ${extrl_ip}
ExecStop=/usr/sbin/iptables -D INPUT -p tcp --dport 443 -j ACCEPT
ExecStop=/usr/sbin/iptables -D FORWARD -s 10.10.16.0/24 -j ACCEPT
ExecStop=/usr/sbin/iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ocserv-iptables.service

    systemctl daemon-reload && \
    systemctl enable ocserv-iptables.service && \
    systemctl start ocserv-iptables.service && \
    systemctl status ocserv-iptables.service

    echo ""
    echo "ГОТОВО :)"
    echo ""

}

# 11. Создаем сервис ocserv (Можно убрать в ExecStart флаг -d 9, чтобы писалось меньше логов, либо выставить -d 4)
addOcservService() {
  echo ""
  echo "Создаем сервис ocserv"
  echo ""

  echo "[Unit]
After=network.target
[Service]
WorkingDirectory=/root/ocserv/src
Type=simple
ExecStart=/root/ocserv/src/ocserv -d 2 -f -c /root/ocserv/src/sample.config
ExecStop=/bin/kill $(cat /run/ocserv.pid)
Restart=on-failure
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ocserv.service

  systemctl daemon-reload && \
  systemctl enable ocserv.service && \
  systemctl start ocserv.service && \
  systemctl status ocserv.service

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 0. Включаем ufw
ufw_on() {
  echo ""
  echo "UFW ON..."
  echo ""

  ufw allow 22/tcp
  ufw allow 443/tcp
  echo y | ufw enable
  ufw status

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# Выключаем ipforwarding на сервере
ipforwardingOff() {
  echo ""
  echo "Выключаем ipforwarding на сервере"
  echo ""

  sed -i 's/net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl -p

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# Выключаем ufw
ufw_off() {
  echo ""
  echo "UFW OFF..."
  echo ""

  ufw disable

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# Добавить пользователя
addUser() {
  echo ""
  echo "Add user..."
  echo ""
  useradd -d "${workDir}" -m -s /bin/bash "${workUsr}"
  ls -l /home
}

# Установить пароль пользователя
setPasswd() {
  echo ""
  echo "PASSWD SET..."
  echo ""
  echo "${pswrd}" | passwd "${workUsr}"
}

# Добавить пользователя в группу sudo
addSudo() {
  usermod -G sudo -a "${workUsr}"
  echo ""
  echo "SUDO ADDED:)"
  echo ""
}

# Доступ по ключу ssh
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

# Пролить ключи ssh
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

# Поставить утилиты мониторинга
instUtils() {
  apt install vim htop tree mc tmux policycoreutils iperf3 net-tools vnstat bwm-ng iftop nload wget ufw cron -y
}

# Exit
exitFromServ() {
  exit
}

# Установка и настройка ocserv
instUtilsOC
cloneRepo
buildVpn
wgetConfig
genKeys
createAccount
mkdirConfigs
sedConfig
ipforwardingOn
autostartIptablesRules
addOcservService

# Настройка безопасности сервера от дудоса и взлома
addUser
setPasswd
addSudo
pubkey_on
ssh_keys
instUtils
ufw_on
exitFromServ

#ipforwardingOff
#ufw_off