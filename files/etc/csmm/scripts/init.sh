#!/usr/bin/env bash
set -Eeuo pipefail
set -x

# Find the rows and columns. Will default to 80x24 if it can not be detected.
screen_size=$(stty size 2>/dev/null || echo 24 80)
rows=$(echo $screen_size | awk '{print $1}')
columns=$(echo $screen_size | awk '{print $2}')

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))


# pre-define all the variables we use
CSMM_VERSION=
CSMM_DOMAIN=csmm.example.com
API_KEY_STEAM=
DISCORDOWNERIDS=
DISCORDBOTTOKEN=
DISCORDCLIENTSECRET=
DISCORDCLIENTID=
LETSENCRYPT_EMAIL=
CSMM_ADMINS=
DBSTRING=
REDISSTRING=
CSMM_LOG_COUNT=50
CSMM_LOG_CHECK_INTERVAL=3000
CSMM_DONATOR_TIER=patron
CSMM_LOGLEVEL=info
CSMM_PORT=1337

whiptail --title "CSMM One Click Installer" --msgbox "Welcome to CSMM one-click installer.\nThis script will ask you a bunch of questions, and then do the final configuration.\nBefore we get started. Make sure you've created a steam app and discord see https://docs.csmm.app/en/CSMM/self-host/configuration.html#steam-api-key" ${r} ${c}

( \
  while [ ! -f /etc/csmm_version ]; do sleep 0.5; done \
) | whiptail --gauge "Please wait while we are still getting ready" ${r} ${c} 00

# load up any existing variables
source /etc/csmm_version

while [ "$CSMM_DOMAIN" == "csmm.example.com" ] || [ -z "$CSMM_DOMAIN" ]; do
  CSMM_DOMAIN=$(whiptail --inputbox 'What domain name do you want to use? Example, csmm.example.com' --title 'CSMM - Domain Name' ${r} ${c} "${CSMM_DOMAIN}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

# make this optional?
while [ -z "$LETSENCRYPT_EMAIL" ]; do
  LETSENCRYPT_EMAIL=$(whiptail --inputbox 'To generated an ssl cert for you, we need an email address to provide letsencrypt.' --title 'CSMM-Lets Encrypt' ${r} ${c} "${LETSENCRYPT_EMAIL}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

while [ -z "$API_KEY_STEAM" ]; do
  API_KEY_STEAM=$(whiptail --inputbox 'Steam API Key from https://steamcommunity.com/dev/apikey' --title 'CSMM-Steam API Key' ${r} ${c} "${API_KEY_STEAM}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

while [ -z "$DISCORDBOTTOKEN" ]; do
  DISCORDBOTTOKEN=$(whiptail --inputbox 'Discord Bot Token -- See https://docs.csmm.app/en/CSMM/self-host/configuration.html#discord-bot-account' --title 'CSMM-Discord Bot Token' ${r} ${c} "${DISCORDBOTTOKEN}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

while [ -z "$DISCORDCLIENTID" ]; do
  DISCORDCLIENTID=$(whiptail --inputbox "Discord OAuth Client ID\n\nSee https://docs.csmm.app/en/CSMM/self-host/configuration.html#discord-bot-account" --title 'CSMM-Discord Client ID' ${r} ${c} "${DISCORDCLIENTID}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    # handle canceling
    exit $exitstatus
  fi
done

while [ -z "$DISCORDCLIENTSECRET" ]; do
  DISCORDCLIENTSECRET=$(whiptail --inputbox "Discord OAuth Client Secret\n\nSee https://docs.csmm.app/en/CSMM/self-host/configuration.html#discord-bot-account" --title "CSMM-Discord Client Secret" ${r} ${c} "${DISCORDCLIENTSECRET}" 3>&1 1>&2 2>&3)
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
CSMM_LOGLEVEL=${CSMM_LOGLEVEL}
CSMM_PORT=${CSMM_PORT}

# This overrides the default donator check
CSMM_DONATOR_TIER=${CSMM_DONATOR_TIER}
# How often CSMM will check for new logs
CSMM_LOG_CHECK_INTERVAL=${CSMM_LOG_CHECK_INTERVAL}
# How many logs CSMM will gather per request
CSMM_LOG_COUNT=${CSMM_LOG_COUNT}

# Comma separated list of steam IDs for users that get extended control, uncomment and add your own IDs
CSMM_ADMINS=${CSMM_ADMINS}

# External APIs

API_KEY_STEAM=${API_KEY_STEAM}
DISCORDOWNERIDS=${DISCORDOWNERIDS}
DISCORDBOTTOKEN=${DISCORDBOTTOKEN}
DISCORDCLIENTSECRET=${DISCORDCLIENTSECRET}
DISCORDCLIENTID=${DISCORDCLIENTID}

DBSTRING=${DBSTRING}
REDISSTRING=${REDISSTRING}
EOF

systemctl restart nginx
systemctl restart csmm
systemctl enable csmm
