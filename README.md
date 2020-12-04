# Secure metrics server

Official [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deploys onto [Kubernetes](https://github.com/kubernetes-sigs/metrics-server/blob/master/deploy/kubernetes/metrics-apiservice.yaml) is _insecure_.

This repo provides a way to generate metrics-server server certificate and key by Kubernetes CA.
Then, deploys metrics-server _in secure_.

## Prerequisite

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux) CLI
- [kustomize](https://github.com/kubernetes-sigs/kustomize) CLI

## Demo

### KIND

1. Clone upstream metrics-server manifests.

   At here, we clone the current latest metrics-server tag `v0.4.1`, you could switch to your preferred metrics-server release version.
   ```shell
   git clone -b v0.4.1 git@github.com:kubernetes-sigs/metrics-server.git
   cd metrics-server/manifests
   git clone git@github.com:jenting/secure-metrics-server.git
   cd secure-metrics-server
   ```

2. Copy the Kubernetes CA certificate from remote machine to local machine.

   ```shell
   NODE_NAME=`kind get nodes`
   CONTAINER_ID=`docker ps --filter "name=$NODE_NAME" -q`
   docker cp $CONTAINER_ID:/etc/kubernetes/pki/ca.crt kubernetes-ca.crt
   ```

3. Run generate secure metrics-server patch manifests.

   ```shell
   ./secure-metrics-server.sh
   ```

4. Apply the _kustomization.yaml_ file

    ```shell
    cd ../
    kustomize build secure-metrics-server | kubectl apply -f -
    ```

5. Check the metrics-server bahavior

    ```shell
    kubectl top nodes
    kubectl top pods
    ```
