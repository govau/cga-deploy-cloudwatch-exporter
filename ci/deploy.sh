#!/bin/bash

set -eu
set -o pipefail

# Tag is not always populated correctly by the docker-image resource (ie it defaults to latest)
# so use the actual source for tag
TAG=$(cat src/.git/ref)
REPO=$(cat img/repository)

cat <<EOF > deployment.yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ${ENV}cld-cloudwatch-exporter-config
data:
  config.yml: |
    tasks:
      - name: rds
        default_region: ap-southeast-2
        metrics:
        - aws_namespace: "AWS/RDS"
          aws_dimensions: [DBInstanceIdentifier]
          aws_metric_name: FreeStorageSpace
          aws_statistics: [Average]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${ENV}cld-cloudwatch-exporter
spec:
  selector:
    matchLabels:
      app: ${ENV}cld-cloudwatch-exporter
  replicas: 1
  template:
    metadata:
      labels:
        app: ${ENV}cld-cloudwatch-exporter
    spec:
      containers:
      - name: ${ENV}cld-cloudwatch-exporter
        image: ${REPO}:${TAG}
        resources: {limits: {memory: "64Mi", cpu: "100m"}}
        envFrom:
        - secretRef: {name: ${ENV}cld-cloudwatch-exporter}
        ports:
        - name: http
          containerPort: 9042
        volumeMounts:
        - mountPath: /etc/cloudwatch_exporter
          name: config-volume
      volumes:
      - name: config-volume
        configMap:
          name: ${ENV}cld-cloudwatch-exporter-config
      
EOF

cat deployment.yaml

mkdir -p $HOME/.ssh
cat <<EOF >> $HOME/.ssh/known_hosts
@cert-authority *.cld.gov.au $(cat ca/terraform/sshca-ca.pub)
EOF
echo "${JUMPBOX_SSH_KEY}" > $HOME/.ssh/key.pem
chmod 600 $HOME/.ssh/key.pem
ssh -i $HOME/.ssh/key.pem -p "${JUMPBOX_SSH_PORT}" ec2-user@${JUMPBOX_SSH_L_HOST} kubectl apply --record -f - < deployment.yaml
ssh -i $HOME/.ssh/key.pem -p "${JUMPBOX_SSH_PORT}" ec2-user@${JUMPBOX_SSH_L_HOST} kubectl rollout status deployment.apps/${ENV}cld-cloudwatch-exporter