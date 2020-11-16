#!/usr/bin/env bash
set -euo pipefail
set -x
export DEBIAN_FRONTEND="noninteractive"
apt -qqy update
apt -qqy install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'
apt -qqy update
apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade
apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-utils expect ufw nginx-light docker-ce fail2ban mariadb-server redis whiptail certbot
systemctl enable mariadb redis-server fail2ban docker nginx certbot
systemctl disable rsync

ufw limit ssh
ufw allow https
ufw allow http
ufw --force enable

chmod +x /etc/csmm/scripts/init.sh
echo '/etc/csmm/scripts/init.sh && cp /etc/skel/.bashrc /root/.bashrc' >> /root/.bashrc

#CSMM_VERSION=$(wget -q https://registry.hub.docker.com/v1/repositories/catalysm/csmm/tags -O - | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n' | awk -F: '{print $3}' | egrep '^v[0-9]' | sort -V | tail -1)
perl -pi -e "s/%CSMM_VERSION%/${CSMM_VERSION}/g" /var/lib/cloud/scripts/per-instance/001_onboot
