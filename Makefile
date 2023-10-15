TAG=v0.1.5


.PHONY: certs serve


certs:
	./scripts/gen-certs.sh



serve:
	go run $(shell go list -f '{{ join .GoFiles "\n" }}' ) -tlsCertFile "./certs/ac-crt.pem" -tlsKeyFile "./certs/ac-key.pem"


image:
	nerdctl build --tag xmarlem/poc-admicon:$(TAG) .


image.push:
	nerdctl push xmarlem/poc-admicon:$(TAG)
