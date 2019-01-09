#!/bin/bash

set -eux
set -o pipefail

ORIG_PWD="${PWD}"

# Create our own GOPATH
export GOPATH="${ORIG_PWD}/go"

# We are using a fork of github.com/technofy/cloudwatch_exporter.
# Symlink our source dir from inside of our own GOPATH to make sure we build 
# our fork and not upstream.
mkdir -p "${GOPATH}/src/github.com/technofy"
ln -s "${ORIG_PWD}/src" "${GOPATH}/src/github.com/technofy/cloudwatch_exporter"

curl -L https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 > /usr/local/bin/dep
chmod a+x /usr/local/bin/dep

cd "${GOPATH}/src/github.com/technofy/cloudwatch_exporter"
dep ensure

CGO_ENABLED=0 \
GOOS=linux \
GOARCH=amd64 \
go install github.com/technofy/cloudwatch_exporter

# cp -rf * $ORIG_PWD/output
mv $GOPATH/bin/cloudwatch_exporter ./config.yml Dockerfile $ORIG_PWD/output

ls -l $ORIG_PWD/output
