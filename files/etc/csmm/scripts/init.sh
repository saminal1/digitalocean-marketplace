#!/usr/bin/env bash
set -Eeuo pipefail
set -x

CSMM_DOMAIN=csmm.example.com
API_KEY_STEAM=
DISCORDOWNERIDS=
DISCORDBOTTOKEN=
DISCORDCLIENTSECRET=
DISCORDCLIENTID=
LETSENCRYPT_EMAIL=
DBSTRING=mysql2://csmm:@localhost:3306/csmm
REDISSTRING=redis://localhost:6379

whiptail --title "CSMM One Click Installer" --infobox "Welcome to CSMM one-click installer.\nThis script will ask you a bunch of questions, and then do the final configuration." 8 78

( \
  while [ ! -f /etc/csmm_version ]; do sleep 0.5; done \
) | whiptail --gauge "Please wait while we are still getting ready" 8 78 00

source /etc/csmm_version

while [ "$CSMM_DOMAIN" == "csmm.example.com" ] || [ -z "$CSMM_DOMAIN" ]; do
  CSMM_DOMAIN=$(whiptail --inputbox 'What domain name do you want to use? Example, csmm.example.com' --title 'CSMM - Domain Name' 8 78 "${CSMM_DOMAIN}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

# make this optional?
while [ -z "$LETSENCRYPT_EMAIL" ]; do
  LETSENCRYPT_EMAIL=$(whiptail --inputbox 'To generated an ssl cert for you, we need an email address to provide letsencrypt.' --title 'CSMM-Lets Encrypt' 8 78 "${LETSENCRYPT_EMAIL}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

# create simple nginx with no ssl for letsencrypt
cat << EOF > /etc/nginx/sites-enabled/default
# HTTP redirect
server {
    listen      80;
    listen      [::]:80;
    server_name ${CSMM_DOMAIN};
    include     nginxconfig.io/letsencrypt.conf;

    location / {
        return 301 https://${CSMM_DOMAIN}\$request_uri;
    }
}
EOF

# start up nginx for lets encrypt
systemctl restart nginx

# Setup letsencrypt
mkdir -p /var/www/_letsencrypt
chown www-data /var/www/_letsencrypt

certbot certonly --webroot -d "${CSMM_DOMAIN}" --email "${LETSENCRYPT_EMAIL}" -n --agree-tos --force-renewal --webroot-path /var/www/_letsencrypt/

# reconfigure nginx with letsencrypt
openssl dhparam -out /etc/nginx/dhparam.pem 2048
cat << EOF > /etc/nginx/sites-enabled/default
server {
    listen                  443 ssl http2;
    listen                  [::]:443 ssl http2;
    server_name             ${CSMM_DOMAIN};

    # SSL
    ssl_certificate         /etc/letsencrypt/live/${CSMM_DOMAIN}/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/${CSMM_DOMAIN}/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/${CSMM_DOMAIN}/chain.pem;

    # security
    include                 nginxconfig.io/security.conf;

    # reverse proxy
    location / {
        proxy_pass http://127.0.0.1:1337;
        include    nginxconfig.io/proxy.conf;
    }

    # additional config
    include nginxconfig.io/general.conf;
}

# HTTP redirect
server {
    listen      80;
    listen      [::]:80;
    server_name ${CSMM_DOMAIN};
    include     nginxconfig.io/letsencrypt.conf;

    location / {
        return 301 https://${CSMM_DOMAIN}\$request_uri;
    }
}
EOF

cat << EOF > /etc/csmm_version
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
CSMM_VERSION=${CSMM_VERSION}
CSMM_DOMAIN=${CSMM_DOMAIN}
CSMM_HOSTNAME=https://${CSMM_DOMAIN}
CSMM_LOGLEVEL=info
CSMM_PORT=1337

# This overrides the default donator check
CSMM_DONATOR_TIER=patron
# How often CSMM will check for new logs
CSMM_LOG_CHECK_INTERVAL=3000
# How many logs CSMM will gather per request
CSMM_LOG_COUNT=50

# Comma separated list of steam IDs for users that get extended control, uncomment and add your own IDs
#CSMM_ADMINS=76561198028175941,76561198028175941

# External APIs

API_KEY_STEAM=${API_KEY_STEAM}
DISCORDOWNERIDS=${DISCORDOWNERIDS}
DISCORDBOTTOKEN=${DISCORDBOTTOKEN}
DISCORDCLIENTSECRET=${DISCORDCLIENTSECRET}
DISCORDCLIENTID=${DISCORDCLIENTID}

DBSTRING=mysql2://csmm:mysecretpasswordissosecure@db:3306/csmm
REDISSTRING=redis://localhost:6379
EOF

systemctl restart nginx
systemctl restart csmm
systemctl enable csmm
