#!/bin/sh
set -e

# generate metrics-server server key, csr, and certifcate
gen_server_cert_key() {
  cat > server.conf <<EOF
  [req]
  distinguished_name = req_distinguished_name
  req_extensions = v3_req
  prompt = no

  [req_distinguished_name]
  CN = metrics-server.kube-system.svc

  [v3_req]
  basicConstraints = critical,CA:FALSE
  keyUsage = critical,digitalSignature,keyEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names

  [alt_names]
  DNS.1 = metrics-server.kube-system.svc
EOF

  openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout server.key -subj "/CN=metrics-server.kube-system.svc"
  openssl req -new -sha256 -key server.key -config server.conf -out server.csr

  # Generate csr manifest
  cat > metrics-server.csr.yaml <<EOF
  apiVersion: certificates.k8s.io/v1beta1
  kind: CertificateSigningRequest
  metadata:
    name: metrics-server.kube-system.svc
  spec:
    request: $(cat server.csr | base64 | tr -d '\n')
    usages:
    - digital signature
    - key encipherment
    - server auth
EOF

  # Delete all csr
  kubectl delete csr --all

  # Apply csr manifest
  kubectl apply -f metrics-server.csr.yaml

  rm metrics-server.csr.yaml

  # Get csr
  kubectl get csr

  # Approve csr
  kubectl certificate approve metrics-server.kube-system.svc

  # Get csr again
  kubectl get csr

  # Retrieve cert after approval
  kubectl -n kube-system get csr metrics-server.kube-system.svc -o jsonpath='{.status.certificate}' | base64 --decode > server.crt

  # Create secret with key and cert
  kubectl -n kube-system create secret tls metrics-server-cert --cert=server.crt --key=server.key || true
}

# generate Deployment patch manifest
gen_deployment_patch_manifest() {
  cat > patch-deployment.yaml <<EOF
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: metrics-server
    namespace: kube-system
  spec:
    template:
      spec:
        volumes:
        - name: metrics-server-cert-path
          secret:
            secretName: metrics-server-cert
        containers:
        - name: metrics-server              
          volumeMounts:
          - name: metrics-server-cert-path
            mountPath: /etc/metrics-server/pki
            readOnly: true
EOF
}

# generate APIService patch manifest
gen_apiservice_patch_manifest() {
  cat > patch-apiservice.yaml <<EOF
  apiVersion: apiregistration.k8s.io/v1
  kind: APIService
  metadata:
    name: v1beta1.metrics.k8s.io
  spec:
    service:
      name: metrics-server
      namespace: kube-system
    group: metrics.k8s.io
    version: v1beta1
    insecureSkipTLSVerify: false
    groupPriorityMinimum: 100
    versionPriority: 100
    caBundle: $(cat kubernetes-ca.crt | base64 -w 0 && echo)
EOF
}

# generate kustomize kustomization.yaml
gen_kustomization_manifest() {
  cp ../release/kustomization.yaml .

  cat >> kustomization.yaml <<EOF
patchesJson6902:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: metrics-server
    namespace: kube-system
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/args/0
      value: --tls-cert-file=/etc/metrics-server/pki/tls.crt
    - op: add 
      path: /spec/template/spec/containers/0/args/1
      value: --tls-private-key-file=/etc/metrics-server/pki/tls.key
    - op: add 
      path: /spec/template/spec/containers/0/args/-
      value: --kubelet-insecure-tls
patches:
- patch-deployment.yaml
- patch-apiservice.yaml	  
EOF
}

{
  gen_server_cert_key
  gen_deployment_patch_manifest
  gen_apiservice_patch_manifest
  gen_kustomization_manifest
}
