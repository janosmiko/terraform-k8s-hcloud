#!/usr/bin/bash
set -eux

eval "$(cat /tmp/kubeadm_join)"
systemctl enable docker kubelet
