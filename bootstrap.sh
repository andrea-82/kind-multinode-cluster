#!/usr/bin/env bash

kind create cluster --config kind-multinode-nocni.yaml

### variables
# K8S_CP = control-plane container ID
# K8S_WN1 = worker node 1 container ID
# K8S_WN2 = worker node 2 container ID
# K8S_JOIN = command to join worker nodes to the master

#debug: find labels: docker ps --format "table {{.ID}}\t\t{{.Names}}\t{{.Labels}}"

#get control plane ID
K8S_CP=$(docker ps --format '{{.ID}}'  -f 'label=io.x-k8s.kind.cluster=k8s-kind' -f 'label=io.x-k8s.kind.role=control-plane')

# @todo: add for loop to dynamically get the node IDs
#get worked node1 ID
K8S_WN1=$(docker ps --format '{{.ID}}\t{{.Names}}' -f 'label=io.x-k8s.kind.cluster=k8s-kind' -f 'label=io.x-k8s.kind.role=worker' -f 'name=worker'|sort -k2|head -n1|awk '{print $1}')
#get worked node2 ID
K8S_WN2=$(docker ps --format '{{.ID}}\t{{.Names}}' -f 'label=io.x-k8s.kind.cluster=k8s-kind' -f 'label=io.x-k8s.kind.role=worker' -f 'name=worker'|sort -k2|tail -n1|awk '{print $1}')

#reset all nodes
docker exec -it $K8S_CP kubeadm reset -f
docker exec -it $K8S_WN1 kubeadm reset -f
docker exec -it $K8S_WN2 kubeadm reset -f

# kubeadm.conf file at /kind/kubeadm.conf (in the control place container)


docker exec -it $K8S_CP kubeadm init --config=/kind/kubeadm.conf --ignore-preflight-errors=all

#debug: get master node: docker exec -it $K8S_CP kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes

# install networking (ie calico)
# curl -s https://docs.projectcalico.org/manifests/tigera-operator.yaml -o calico/tigera-operator.yaml
# curl -s https://docs.projectcalico.org/manifests/custom-resources.yaml -o calico/custom-resources.yaml

docker cp -a calico $K8S_CP:/var/tmp/
docker exec -it $K8S_CP kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f /var/tmp/calico/tigera-operator.yaml
### fix Calico podSubnet (to match the config used for kubeadm

# @todo: dynamically retrieve the subnet used by kind and replace it in the calico config file
#docker exec -it $K8S_CP grep podSubnet /kind/kubeadm.conf|awk '{print $NF}'

docker exec -it $K8S_CP sed -i 's~cidr: 192.168.0.0/16~cidr: 10.244.0.0/16~' /var/tmp/calico/custom-resources.yaml
# install calico custom resources
docker exec -it $K8S_CP kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f /var/tmp/calico/custom-resources.yaml

# get command to allow other nodes to join the cluster
K8S_JOIN=$(docker exec -it $K8S_CP kubeadm token create --print-join-command|grep 'kubeadm join'|tr '\r' ' ')

docker exec -it $K8S_WN1 $K8S_JOIN --ignore-preflight-errors=all
docker exec -it $K8S_WN2 $K8S_JOIN --ignore-preflight-errors=all

kind export kubeconfig --name k8s-kind
