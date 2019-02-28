#!/bin/bash

set -eu
set -o pipefail

: "${ENV_NAME:?Need to set ENV_NAME}"
: "${KUBECONFIG_JSON:?Need to set KUBECONFIG_JSON}"

echo $KUBECONFIG_JSON > secret-kubeconfig
export KUBECONFIG=secret-kubeconfig

export NAMESPACE="cloudwatch-exporter"

kubectl -n ${NAMESPACE} get pods

# Try to connect to the pod port
POD_NAME=$(kubectl -n ${NAMESPACE} get pods -l app=prometheus-cloudwatch-exporter,release=${ENV_NAME}cld -o jsonpath="{.items[0].metadata.name}")
kubectl -n ${NAMESPACE} port-forward $POD_NAME 9106:9106 &

attempt_counter=0
max_attempts=20
until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:9106); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi
    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
done

curl http://127.0.0.1:9106/metrics
