#!/bin/bash

set -eu
set -o pipefail

# Tag is not always populated correctly by the docker-image resource (ie it defaults to latest)
# so use the actual source for tag
TAG=$(cat src/.git/ref)
REPO=$(cat img/repository)

cat <<EOF > deployment.yaml
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
---
kind: Service
apiVersion: v1
metadata:
  name: ${ENV}cld-cloudwatch-exporter
  labels:
    monitor: me
spec:
  selector:
    app: ${ENV}cld-cloudwatch-exporter
  ports:
  - name: web
    port: 9042  
EOF

cat deployment.yaml

echo $KUBECONFIG > k
export KUBECONFIG=k

kubectl apply --record -f - < deployment.yaml
kubectl rollout status deployment.apps/${ENV}cld-cloudwatch-exporter