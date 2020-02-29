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

# Wait for master generating the join command
while [ ! -f /vagrant/join-command.tmp ]; do
  sleep 2
done
TOKEN=$(cut /vagrant/join-command.tmp -d ' ' -f 5)
CA_CERT_HASHES=$(cut /vagrant/join-command.tmp -d ' ' -f 11)
rm /vagrant/join-command.tmp

# Join to a cluster using kubeadm
cat > cluster-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
nodeRegistration:
  kubeletExtraArgs:
    node-ip: "10.20.30.51"
discovery:
  bootstrapToken:
    apiServerEndpoint: "10.20.30.50:6443"
    token: "$TOKEN"
    caCertHashes:
    - "$CA_CERT_HASHES"
EOF
sudo kubeadm join --config cluster-config.yaml
