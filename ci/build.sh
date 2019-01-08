#!/bin/bash

set -eu
set -o pipefail

ORIG_PWD="${PWD}"

# Create our own GOPATH
export GOPATH="${ORIG_PWD}/go"

# Symlink our source dir from inside of our own GOPATH
mkdir -p "${GOPATH}/src/github.com/technofy"
ln -s "${ORIG_PWD}/src" "${GOPATH}/src/github.com/technofy/cloudwatch_exporter"
cd "${GOPATH}/src/github.com/technofy/cloudwatch_exporter"

go build

mv ./cloudwatch_exporter ./config.yml Dockerfile $ORIG_PWD/output
