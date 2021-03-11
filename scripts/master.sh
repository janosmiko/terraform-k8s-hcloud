#!/usr/bin/bash
set -eux

declare KUBEADM_INIT_ARGS=()

if [ "$FEATURE_GATES" ]; then
  KUBEADM_INIT_ARGS+=("--feature-gates \"${FEATURE_GATES}\"")
fi

if [ "$MULTI_MASTER" = "true" ]; then
  #KUBEADM_INIT_ARGS+=("--upload-certs")
  KUBEADM_INIT_ARGS+=("--control-plane-endpoint=${LOAD_BALANCER_DNS}:${LOAD_BALANCER_PORT}")
fi

# Initialize Cluster
kubeadm init --pod-network-cidr="${POD_NETWORK_CIDR}" "${KUBEADM_INIT_ARGS[@]}"
CERT_KEY=$(kubeadm init phase upload-certs --upload-certs | tail -n1)

systemctl enable docker kubelet

# Used to join secondary masters to the cluster
kubeadm token create --print-join-command | tr -d "\n" >/tmp/kubeadm_master_join
echo " --control-plane --certificate-key ${CERT_KEY}" >>/tmp/kubeadm_master_join

# Used to join nodes to the cluster
kubeadm token create --print-join-command >/tmp/kubeadm_join

mkdir -p "$HOME/.kube"
cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
