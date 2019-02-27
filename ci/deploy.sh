#!/bin/bash

set -eu
set -o pipefail

: "${ENV_NAME:?Need to set ENV_NAME e.g. d}"
: "${KUBECONFIG_JSON:?Need to set KUBECONFIG_JSON}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo $KUBECONFIG_JSON > secret-kubeconfig
export KUBECONFIG=secret-kubeconfig

kubectl get po # just a test

# Starting tiller in the background"
export HELM_HOST=:44134
TILLER_NAMESPACE=cloudwatch-exporter tiller --storage=secret --listen "$HELM_HOST" >/dev/null 2>&1 &
helm init --client-only --wait

# helm dependency update charts/stable/prometheus-cloudwatch-exporter/

helm upgrade --install --wait \
  --namespace cloudwatch-exporter \
  -f <($SCRIPT_DIR/../gen-values.sh) \
  ${ENV_NAME}cld charts/stable/prometheus-cloudwatch-exporter/

# kubectl rollout status deployment.apps/${ENV_NAME}cld-cloudwatch-exporter
