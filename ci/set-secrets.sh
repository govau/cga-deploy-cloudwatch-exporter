#!/usr/bin/env bash

# Sets the secrets in concourse's credhub and k8s needed by this pipeline.
# The credentials are rotated each time this script is run.

set -euxo pipefail

function trim_to_one_access_key(){
    iam_user=$1
    key_count=$(aws iam list-access-keys --user-name "${iam_user}" | jq '.AccessKeyMetadata | length')
    if [[ $key_count > 1 ]]; then
        oldest_key_id=$(aws iam list-access-keys --user-name "${iam_user}" | jq -r '.AccessKeyMetadata |= sort_by(.CreateDate) | .AccessKeyMetadata | first | .AccessKeyId')
        aws iam delete-access-key --user-name "${iam_user}" --access-key-id "${oldest_key_id}"
    fi
}

NAMESPACE=cloudwatch-exporter

if [[ $(kubectl get namespace ${NAMESPACE} 2>/dev/null) == "" ]]; then
  echo "Namespace not found - have you targetted the right cluster and run k8s-bootstrap.sh?"
  exit 1
fi

# set the k8s secrets used to access cloudwatch-exporter in each env
for ENV_NAME in b d g t y; do
    iam_user="cloudwatch_exporter"
    export AWS_PROFILE=${ENV_NAME}-cld

    trim_to_one_access_key $iam_user

    output="$(aws iam create-access-key --user-name "${iam_user}")"
    aws_access_key_id="$(echo $output | jq -r .AccessKey.AccessKeyId)"
    aws_secret_access_key="$(echo $output | jq -r .AccessKey.SecretAccessKey)"

    unset AWS_PROFILE

    kubectl -n ${NAMESPACE} create secret generic ${ENV_NAME}cld-aws \
        --from-literal "access_key=${aws_access_key_id}" \
        --from-literal "secret_key=${aws_secret_access_key}" \
        --dry-run -o yaml | kubectl apply -f -

done



