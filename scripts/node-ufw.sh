#!/usr/bin/bash
set -eux

waitforapt() {
  while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for other software managers to finish..."
    sleep 1
  done
}

waitforapt

apt-get -qq update
apt-get -qq install -y ufw

ufw --force reset \
  && for ALLOWED_IP in ${FIREWALL_ALLOWED_IPS}; do
    ufw allow from "${ALLOWED_IP}" to any port 22
  done \
  && for ALLOWED_MASTER_IP in ${MASTER_IPS}; do
    ufw allow in from "${ALLOWED_MASTER_IP}" to any
  done \
  && ufw allow in from "${NODE_NETWORK_CIDR}" to any \
  && ufw allow in from "${POD_NETWORK_CIDR}" to any \
  && ufw default deny incoming \
  && ufw --force enable
