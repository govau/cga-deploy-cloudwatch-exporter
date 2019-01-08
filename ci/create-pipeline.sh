#!/usr/bin/env bash

set -eux

TARGET=${TARGET:-mcld}
PIPELINE=cloudwatch-exporter

export https_proxy=socks5://localhost:8112

fly validate-pipeline --config pipeline.yml

fly -t ${TARGET} set-pipeline -n \
  --config pipeline.yml \
  --pipeline "${PIPELINE}"

# Check all resources for errors
RESOURCES="$(fly -t "${TARGET}" get-pipeline -p "${PIPELINE}" | yq -r '.resources[].name')"
for RESOURCE in $RESOURCES; do
  fly -t ${TARGET} check-resource --resource "${PIPELINE}/${RESOURCE}"
done

unset https_proxy