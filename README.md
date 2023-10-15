# Admission controllers: simple-webhook

**TL;DR**: I want to generate everything needed to scaffold a simple admission controller (validating webhook).
I was thinking to create some sort of simple script to generate whatever needed to deploy a simple validating webook in kubernetes.
In scripts folder you can run `generate-certs.sh` which will provide ca, server cert, manifests in two folders: k8s and certs.


## Steps

0. First you have to build and push a new image to your registry.

   There are two make targets for that.
   `make image.build && image.push`

But before that, just increase the semantic version in `VERSION` file if needed.


1. generate a `simple-webhook` admission controller in default namespace


If you are starting from scratch, just delete k8s and certs folder before running the following command:

`./scripts/generate-certs.sh simple-webhook default`

this will create two folders:
- **certs**: containing certs
- **k8s**: containing two manifests: one with secret and validating webhook configuration and one with deploy and svc definitions


2. Deploy all

`kubectl apply -f k8s`

Note: but if you notice pod doesn't get created, just apply first the deploy manifest and then manifest.yaml.


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

- whenever I generate new certificates, I will have to rebuild and push the container image with `make image.build && image.push` otherwise I might get "tls: bad certifcate"
