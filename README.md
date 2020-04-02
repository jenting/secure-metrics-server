# Secure metrics server

Official [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deploys onto [Kubernetes](https://github.com/kubernetes-sigs/metrics-server/blob/master/deploy/kubernetes/metrics-apiservice.yaml) is _insecure_.

This repo provides a way to generate metrics-server certificate/key by Kubernetes CA.
Then, deploys metrics-server _in secure_.

## Deployments

```
git clone git@github.com:kubernetes-sigs/metrics-server.git
kubectl apply -f metrics-server/deploy/kubernetes
./gen-metrics-server-cert-key.sh
```
