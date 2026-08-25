# Build the go application into a binary
# Pinned to 1.26: golang.org/x/net v0.54.0 excludes its http2 server implementation under
# go1.27 (//go:build !(go1.27 && !http2legacy)), which drops http2.TrailerPrefix and breaks
# google.golang.org/grpc v1.81.1. The image sets GOTOOLCHAIN=local, so the tag decides the
# compiler outright - an unpinned golang:alpine breaks this build on every Go release.
FROM golang:1.26-alpine AS builder
RUN apk --update add ca-certificates
WORKDIR /app
COPY . ./
RUN go mod tidy -diff
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

# Run Tests inside docker image if you don't have a configured go environment
#RUN apk update && apk add --virtual build-dependencies build-base gcc
#RUN go test ./... -mod vendor

# Run the binary on an empty container
FROM scratch
COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
ENV GATUS_CONFIG_PATH=""
ENV GATUS_LOG_LEVEL="INFO"
ENV PORT="8080"
EXPOSE ${PORT}
ENTRYPOINT ["/gatus"]
