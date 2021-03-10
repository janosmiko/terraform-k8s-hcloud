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
    #&& ufw allow from "${ALLOWED_IP}" to any port 6443
  done \
  && ufw allow 6443 \
  && ufw allow in from "${NODE_NETWORK_CIDR}" to any \
  && ufw allow in from "${POD_NETWORK_CIDR}" to any \
  && ufw default deny incoming \
  && ufw --force enable
