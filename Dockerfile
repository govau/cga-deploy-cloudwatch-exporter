FROM golang:1.11 AS builder

# Install dep
RUN curl -L https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 > /usr/local/bin/dep && \
    chmod a+x /usr/local/bin/dep

# This docker file expects you to have copied it into
# https://github.com/govau/cga_cloudwatch_exporter 
COPY . /go/src/github.com/technofy/cloudwatch_exporter

# If we don't disable CGO, the binary won't work in the scratch image. Unsure why?
RUN cd /go/src/github.com/technofy/cloudwatch_exporter && \
    dep ensure && \
    CGO_ENABLED=0 go install github.com/technofy/cloudwatch_exporter

FROM scratch
# FROM alpine:latest
# RUN apk update && \
#     apk add ca-certificates && \
#     update-ca-certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY --from=builder /go/bin/cloudwatch_exporter /bin/cloudwatch_exporter
COPY --from=builder /go/src/github.com/technofy/cloudwatch_exporter/config.yml /etc/cloudwatch_exporter/config.yml

EXPOSE      9042
ENTRYPOINT  [ "/bin/cloudwatch_exporter", "-config.file=/etc/cloudwatch_exporter/config.yml" ]
