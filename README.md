# kind-multinode-cluster
kind-multinode-cluster is a bash script that allows to setup up a multinode kubernetes cluster in one command

## Prerequisites

Before you begin, ensure you have met the following requirements:
* `docker` - [install based on your OS](https://docs.docker.com/engine/install/debian/)
* `kind` - [installation docs](https://kind.sigs.k8s.io/docs/user/quick-start/)
* `kubectl` - [installation docs](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

NB: `kubectl` is only needed for interacting with the cluster, not for the actual installation.


## Launch cluster setup

```
./bootstrap.sh
```

If everything went find, you can check the status of the worker nodes with:
```
kubectl get nodes
NAME                     STATUS   ROLES    AGE    VERSION                                                                        k8s-kind-control-plane   Ready    master   148m   v1.19.1                                                                        k8s-kind-worker          Ready    <none>   147m   v1.19.1                                                                        k8s-kind-worker2         Ready    <none>   147m   v1.19.1
```

## Thanks

Thanks to [Duffie Cooley](https://github.com/mauilion) for his great [video](https://k8s.work/cka-lab.mp4) on what is possible with `kind`.
