# Terraform Kubernetes on Hetzner Cloud

This repository will help to setup an opionated Kubernetes Cluster
with [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
on [Hetzner Cloud](https://www.hetzner.com/cloud?country=us).

## Usage

```
$ git clone https://github.com/solidnerd/terraform-k8s-hcloud.git
$ terraform init
$ terraform apply
```

## Example

```
$ terraform init
$ terraform apply
$ KUBECONFIG=secrets/admin.conf kubectl get nodes
$ KUBECONFIG=secrets/admin.conf kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/etcd.yaml
$ KUBECONFIG=secrets/admin.conf kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/rbac.yaml
$ KUBECONFIG=secrets/admin.conf kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/calico.yaml
$ KUBECONFIG=secrets/admin.conf kubectl get pods --namespace=kube-system -o wide
$ KUBECONFIG=secrets/admin.conf kubectl run nginx --image=nginx
$ KUBECONFIG=secrets/admin.conf kubectl expose deploy nginx --port=80 --type NodePort
```

## Variables

|  Name                    |  Default     |  Description                                                                      | Required |
|:-------------------------|:-------------|:----------------------------------------------------------------------------------|:--------:|
| `hcloud_token`        | ``                      |API Token that will be generated through your hetzner cloud project https://console.hetzner.cloud/projects                   | Yes |
| `master_count`        | `1`                     | Amount of masters that will be created                                                                                      | No  |
| `master_image`        | `ubuntu-20.04`          | Predefined Image that will be used to spin up the machines | No  |
| `master_type`         | `cx21`                  | Machine type for more types have a look at https://www.hetzner.de/cloud                                                     | No  |
| `node_count`          | `1`                     | Amount of nodes that will be created                                                                                        | No  |
| `node_image`          | `ubuntu-20.04`          | Predefined Image that will be used to spin up the machines  | No  |
| `node_type`           | `cx21`                  | Machine type for more types have a look at https://www.hetzner.de/cloud                                                     | No  |
| `ssh_private_key`     | `~/.ssh/id_ed25519`     | Private Key to access the machines                                                                                          | No  |
| `ssh_public_key`      | `~/.ssh/id_ed25519.pub` | Public Key to authorized the access for the machines                                                                        | No  |
| `docker_version`      | `19.03`                 | Docker CE version that will be installed                                                                                    | No  |
| `kubernetes_version`  | `1.18.6`                | Kubernetes version that will be installed                                                                                   | No  |
| `feature_gates`       | ``                      | Add your own Feature Gates for Kubeadm                                                                                      | No  |
| `calico_enabled`      | `false`                 | Installs Calico Network Provider after the master comes up                                                                  | No  |
| `location`            | `nbg1`                  | Location of hetzner datacenter (`nbg1`, `fsn1` or `hel1`)                                                                    | No  |
| `ufw_enabled`          | `false`                  | Installs rudimentary firewall setup using ufw*                                                                              | No  |
| `pod_network_cidr`    | `10.244.0.0/16`        | Network range of pod ips                                                                                                    | No  |
| `node_network_cidr`   | `10.8.0.0/16`            | Network range of node ips                                                                                                    | No  |
| `network_cidr`        | `10.0.0.0/8`            | Network range of vpc network                                                                                                | No  |
| `csi_driver_enabled`  | `false`                  | Installs [hcloud-csi driver](https://github.com/hetznercloud/csi-driver) for persistent volume support                      | No  |
| `hcloud_controller_manager_enabled` | `false`   | Installs [hcloud-cloud-controller-manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager) for persistent volume support | No  |

All variables cloud be passed through `environment variables` or a `tfvars` file.

*services with type NodePort are still accessible because kube-proxy creates iptables rules overwriting ufw

An example for a `tfvars` file would be the following `terraform.tfvars`

```toml
# terraform.tfvars
hcloud_token = "<yourgeneratedtoken>"
master_type = "cx21"
master_count = 1
node_type = "cx31"
node_count = 2
kubernetes_version = "1.18.6"
docker_version = "19.03"
```

Or passing directly via Arguments

```console
$ terraform apply \
  -var hcloud_token="<yourgeneratedtoken>" \
  -var docker_version=19.03 \
  -var kubernetes_version=1.18.6 \
  -var master_type=cx21 \
  -var master_count=1 \
  -var node_type=cx31 \
  -var node_count=2
```

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/solidnerd/terraform-k8s-hcloud/issues) to report any bugs or file
feature requests.

**Tested with**

- Terraform [v0.14.7](https://github.com/hashicorp/terraform/tree/v0.12.24)
- provider.hcloud [v1.19.0](https://github.com/terraform-providers/terraform-provider-hcloud)
