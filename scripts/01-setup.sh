export DEBIAN_FRONTEND="noninteractive"
apt -qqy update
apt -qqy install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'
apt -qqy update
apt-cache policy docker-ce
apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade
apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install nginx docker-ce fail2ban mysql-server expect

