#!/usr/bin/bash
set -eux

eval "$(cat /tmp/kubeadm_master_join)"
systemctl enable docker kubelet
