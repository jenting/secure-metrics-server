# Secure metrics server

Official [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deploys [Kubernetes](https://github.com/kubernetes-sigs/metrics-server/blob/master/deploy/kubernetes/metrics-apiservice.yaml) is insecure.

This repo provides a way to generate metrics-server certificate/key by Kubernetes CA.
Then, deploys metrics-server in secure.
