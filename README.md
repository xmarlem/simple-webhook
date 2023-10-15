# Admission controllers: simple-webhook

TL-DR: I want to generare everything needed to scaffold a simple admission controller (validating).

1. generate a simple-webhook in default namespace

`./scripts/generate-certs.sh simple-webhook default`

this will create two folders:
- certs: containing certs
- k8s: containing two manifests: one with secret and validating webhook configuration and one with deploy and svc definitions


2. Deploy all

`kubectl apply -f k8s`


3. Test the webhook

I can follow the tail log with: `k logs podname -f`

`kubectl apply -f examples/non-smooth-app.yaml` --> which should fail.


## Certificates creation

I have used the `generate-certs.sh` script in scripts folder... to generate:
- certificates (ca and server certificates)
- manifest with secret containing server certificate and validating webhook configuration
- manifest with webhook deployment and related service


## Troubleshooting

Note that:
- if you get a bad certificate --> most probabily it has to do either with caBundle not correct in validating webhook configuration or with the Subject and/or alternate names in certificates not matching the service name/DNS.

- whenever I generate new certificates, I will have to rebuild and push the container image with `make image && push.image` otherwise I might get "tls: bad certifcate"

