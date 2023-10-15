TAG=$(shell cat VERSION)


.PHONY: certs serve image.push image.build version


version:
	@echo $(TAG)

certs:
	./scripts/gen-certs.sh



serve:
	go run $(shell go list -f '{{ join .GoFiles "\n" }}' ) -tlsCertFile "./certs/ac-crt.pem" -tlsKeyFile "./certs/ac-key.pem"


image.build:
	nerdctl build --tag xmarlem/poc-admicon:$(TAG) .


image.push:
	nerdctl push xmarlem/poc-admicon:$(TAG)
