#!/usr/bin/bash
set -eux

#create secret with hcloud token for hcloud-csi driver
kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=$HCLOUD_TOKEN --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.5.1/deploy/kubernetes/hcloud-csi.yml
