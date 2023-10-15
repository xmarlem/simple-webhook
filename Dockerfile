# syntax=docker/dockerfile:1

FROM golang:1.21 as build-stage
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./

COPY ./certs/server.crt ./
COPY ./certs/server-key.pem ./

RUN CGO_ENABLED=0 GOOS=linux go build -o /admicon

FROM gcr.io/distroless/base-debian11 AS build-release-stage
WORKDIR /
COPY --from=build-stage /admicon /admicon
COPY --from=build-stage /app/*.pem /
COPY --from=build-stage /app/*.crt /
COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh
EXPOSE 443
#USER nonroot:nonroot
# Run
CMD ["/admicon", "-tlsCertFile", "/server.crt", "-tlsKeyFile", "/server-key.pem"]
