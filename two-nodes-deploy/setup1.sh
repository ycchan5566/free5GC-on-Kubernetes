#!/bin/bash

swapoff -a

# Install K8s related utilities
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo "source <(kubectl completion bash)" >> ~/.bashrc

# Build a cluster using kubeadm
cat > cluster-config.yaml << "EOF"
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "10.20.30.50"
nodeRegistration:
  kubeletExtraArgs:
    node-ip: "10.20.30.50"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.17.0
apiServer:
  extraArgs:
    feature-gates: "SCTPSupport=true"
networking:
  podSubnet: "192.168.0.0/16"
EOF
sudo kubeadm init --config cluster-config.yaml
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-

# Install calicoctl
wget https://github.com/projectcalico/calicoctl/releases/download/v3.11.2/calicoctl-linux-amd64 -q -O calicoctl
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin
sudo mkdir -p /etc/calico && sudo tee /etc/calico/calicoctl.cfg > /dev/null << EOF
apiVersion: projectcalico.org/v3
kind: CalicoAPIConfig
metadata:
spec:
  datastoreType: "kubernetes"
  kubeconfig: "$HOME/.kube/config"
EOF

# Setup NFS server
sudo apt-get install -qqy nfs-kernel-server
sudo mkdir -p /nfsshare/mongodb
echo "/nfsshare *(rw,sync,no_root_squash)" | sudo tee /etc/exports
sudo exportfs -r
sudo showmount -e

git clone https://github.com/ycchan5566/free5GC-on-Kubernetes.git
kubeadm token create --print-join-command > /vagrant/join-command.tmp
