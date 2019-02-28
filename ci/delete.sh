#!/bin/bash

set -eu
set -o pipefail

: "${ENV_NAME:?Need to set ENV_NAME e.g. d}"
: "${KUBECONFIG_JSON:?Need to set KUBECONFIG_JSON}"

echo $KUBECONFIG_JSON > secret-kubeconfig
export KUBECONFIG=secret-kubeconfig

export NAMESPACE="sentry-${DEPLOY_ENV}"

set -x

# Starting tiller in the background"
export HELM_HOST=:44134
TILLER_NAMESPACE=cloudwatch-exporter tiller --storage=secret --listen "$HELM_HOST" >/dev/null 2>&1 &
helm init --client-only --wait

helm delete ${ENV_NAME}cld --purge || true
