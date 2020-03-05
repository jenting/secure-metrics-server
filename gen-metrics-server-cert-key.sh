# Generate key and csr
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout server.key -subj "/CN=metrics-server.kube-system"
openssl req -new -sha256 -key server.key -out server.csr -subj "/CN=metrics-server.kube-system"

# Generate csr manifest
cat > metrics-server.csr.yaml <<EOF
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: metrics-server.kube-system
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# Apply csr manifest
kubectl apply -f metrics-server.csr.yaml

# Get csr
kubectl get csr

# Approve csr
kubectl certificate approve metrics-server.kube-system

# Get csr again
kubectl get csr

# Retrieve cert after approval
kubectl -n kube-system get csr metrics-server.kube-system -o jsonpath='{.status.certificate}' | base64 --decode > server.crt

# Create secret with `key and cert
kubectl -n kube-system create secret tls metrics-server-cert --cert=server.crt --key=server.key --dry-run=true -o yaml > metrics-server-cert.yaml
kubectl apply -f metrics-server-cert.yaml

# Update manifests
cat > metrics-server-apiservice.yaml <<EOF
apiVersion: apiregistration.k8s.io/v1beta1
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
  caBundle: $(cat pki/ca.crt | base64 -w 0 && echo)
EOF

kubectl apply -f metrics-server-apiservice.yaml

# Get apiservice
kubectl get apiservice v1beta1.metrics.k8s.io
