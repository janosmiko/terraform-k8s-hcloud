#!/usr/bin/bas
set -eu

sleep 30

#create secret with hcloud token for hcloud-csi driver
kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=$HCLOUD_TOKEN

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.4.0/deploy/kubernetes/hcloud-csi.yml