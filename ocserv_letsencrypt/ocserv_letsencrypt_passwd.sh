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
dmn_name="${DOMAIN_NAME}"
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

# 5. Теперь создаем АККАУНТЫ VPN
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

# 6. (необязательный шаг) Создаем директорию clients/configs где будем хранить клиентские конфиги с нужными IP и маршрутами
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

# 7. Получаем сертификаты Let's Encrypt
getLetsEncryptCerts() {
  apt-get install certbot -y
  echo y | certbot certonly --standalone --force-interactive --agree-tos --email test@test.com -d "${dmn_name}"
  certbot renew --dry-run
}

# 8. Устанавливаем правило crontab для автопродления сертификатов Let's Encrypt
setCrontab() {
    echo ""
    echo "Настраиваем crontab для автопродления сертификатов Let's Encrypt"
    echo ""

    echo "# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command" >> /var/spool/cron/crontabs/root

    # автопродление сертов 1 и 15 числа каждого месяца
    echo "30 4 1,15 * * certbot renew -n -q" >> /var/spool/cron/crontabs/root
    # перезагрузка сервера 1 и 15 числа каждого месяца через 15 минут после попытки автопродления сертов
    echo "45 4 1,15 * * reboot" >> /var/spool/cron/crontabs/root

    echo ""
    echo "ГОТОВО :)"
    echo ""
}

# 9. Теперь работаем с конфигом сервера
sedConfig() {
  echo ""
  echo "Работаем с конфигом сервера"
  echo ""

  cd ~/ocserv/src || exit

  echo "${PWD}"
  cat /root/sample_main.config > sample.config

  sed -i "s/server-cert = ..\/tests\/certs\/server-cert.pem/server-cert = \/etc\/letsencrypt\/live\/${dmn_name}\/fullchain.pem/" sample.config && \
  sed -i "s/server-key = ..\/tests\/certs\/server-key.pem/server-key = \/etc\/letsencrypt\/live\/${dmn_name}\/privkey.pem/" sample.config && \
  sed -i "s/mysecretkey/${secretkey}/" sample.config

  echo ""
  echo "ГОТОВО :)"
  echo ""
}

# 10. Включаем ipforwarding на сервере
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

# 11. Создаем автозапуск правил iptables (ВНИМАТЕЛЬНО СМОТРИМ НАШУ ПОДСЕТЬ, ЛОКАЛЬНЫЙ IP, И ПОРТ ИЗ КОНФИГА)
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

# 12. Создаем сервис ocserv (Можно убрать в ExecStart флаг -d 9, чтобы писалось меньше логов, либо выставить -d 4)
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

# Установка и настройка ocserv
instUtilsOC
cloneRepo
buildVpn
wgetConfig
createAccount
mkdirConfigs
getLetsEncryptCerts
setCrontab
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

#ipforwardingOff
#ufw_off