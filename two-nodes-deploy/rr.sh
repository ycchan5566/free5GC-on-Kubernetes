#!/bin/bash

cp -r /vagrant/calico-config ~
calicoctl get ippool -o yaml > calico-config/ippool.yaml
sed -i 's/Always/CrossSubnet/g' calico-config/ippool.yaml
calicoctl apply -f calico-config/ippool.yaml

calicoctl get node node1 -o yaml > calico-config/node1.yaml
sed -i '/node-role.kubernetes.io\/master/a \    route-reflector: true' calico-config/node1.yaml
sed -i '/ipv4IPIPTunnelAddr/a \    routeReflectorClusterID: 1.0.0.1' calico-config/node1.yaml
calicoctl apply -f calico-config/node1.yaml

calicoctl apply -f calico-config/bgp-config.yaml
calicoctl apply -f calico-config/bgp-peer.yaml
calicoctl apply -f calico-config/host-endpoint.yaml
