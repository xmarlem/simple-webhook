#!/bin/bash

set -eu

service=$1
namespace=$2

echo "service is $service"
echo "namespace is $namespace"

version="VERSION"
k8sdir="k8s"
if [ ! -d "$k8sdir" ]; then
  mkdir ${k8sdir} || exit 1
fi

destdir="certs"
if [ ! -d "$destdir" ]; then
  mkdir ${destdir} || exit 1
fi
tmpdir=$(mktemp -d)

# Generate CA
#openssl genrsa -des3 -out $destdir/ca.key 2048
openssl req -x509 -new -nodes -keyout $destdir/ca.key -sha256 -days 3650 -out $destdir/ca.pem -addext "subjectAltName = DNS:${service}.${namespace}.svc" -subj "/CN=${service}.${namespace}.svc"

cat <<EOF >> ${tmpdir}/csr.conf
[req]
default_bits       = 2048
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
countryName = CL
commonName = test

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${service}
DNS.2 = ${service}.${namespace}
DNS.3 = ${service}.${namespace}.svc
EOF

outKeyFile=${destdir}/server-key.pem
outCertFile=${destdir}/server.crt
outManifest=${k8sdir}/manifest.yaml
outDeployManifest=${k8sdir}/deploy.yaml

#openssl genrsa -out ${outKeyFile} 2048 || exit 2

subjectCN="${service}.${namespace}.svc"
echo "Generating certificate for CN=${subjectCN}"
openssl req -new -nodes -keyout ${destdir}/server-key.pem -config ${tmpdir}/csr.conf -subj "/CN=${subjectCN}" -out ${tmpdir}/server.csr || exit 3
openssl x509 -req -in ${tmpdir}/server.csr -CA $destdir/ca.pem -CAkey $destdir/ca.key -CAcreateserial -extensions v3_req -extfile ${tmpdir}/csr.conf -out $outCertFile -days 3650

cat <<EOF > $outManifest
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
 name: ${service}.default.cluster.local
 namespace: $namespace
webhooks:
- name: ${service}.default.cluster.local
  clientConfig:
    service:
      name: ${service}
      namespace: $namespace
      path: "/validate"
    caBundle: $(cat $destdir/ca.pem | base64 | tr -d '\n')
  rules:
  - apiGroups: ["batch"]
    apiVersions: ["v1"]
    resources: ["jobs"]
    operations: ["CREATE"]
    scope: "*"
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  # namespaceSelector:
  #   matchExpressions:
  #   - key: name
  #     operator: In
  #     values: ["$namespace"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail
---
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: admission-certs
  namespace: $namespace
data:
  server-key.pem: $(cat $outKeyFile | base64 | tr -d '\n')
  server.pem: $(cat $outCertFile | base64 | tr -d '\n')
EOF


cat <<EOF > $outDeployManifest
---
apiVersion: v1
kind: Service
metadata:
  name: simple-webhook
  namespace: default
  labels:
    name: poc-admicon
spec:
  ports:
    - name: webhook
      port: 443
      targetPort: 443
  selector:
    name: poc-admicon
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-webhook-deploy
  namespace: default
  labels:
    name: poc-admicon
spec:
  replicas: 1
  selector:
    matchLabels:
      name: poc-admicon
  template:
    metadata:
      name: poc-admicon
      labels:
        name: poc-admicon
    spec:
      containers:
        - name: webhook
          image: xmarlem/poc-admicon:$(cat $version)
          imagePullPolicy: Always
          volumeMounts:
            - name: webhook-certs
              mountPath: /etc/certs
              readOnly: true
            - name: logs
              mountPath: /tmp
      volumes:
        - name: webhook-certs
          secret:
            secretName: admission-certs
        - name: logs
          emptyDir: {}
EOF



echo "Generated:"
echo ${outKeyFile}
echo ${outCertFile}
echo ${outManifest}
