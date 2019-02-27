#!/bin/bash

set -euo pipefail

: "${KUBECONFIG_JSON:?Need to set KUBECONFIG_JSON}"

cat <<EOF > deployment.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: "cloudwatch-exporter"
  labels:
    release: prometheus-operator
spec:
  selector:
    matchLabels:
      monitor: me
  endpoints:
  - port: http
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    app: prometheus-operator
    release: prometheus-operator
  name: cloudwatch-exporter-rules
  namespace: cloudwatch-exporter
spec:
  groups:
  - name: cloudwatch-exporter.alerts
    rules:
    - alert: AwsCloudwatchExporterScrapeDurationHigh
      annotations:
        summary: Cloudwatch exporter scrape duration high
        message: Cloudwatch exporter scrape took more than 10 seconds
      expr: cloudwatch_exporter_scrape_duration_seconds > 10
      for: 5m
      labels:
        severity: warning
  - name: awsrds.alerts
    rules:
    - alert: AwsRdsFreeStorageSpaceLow
      annotations:
        summary: RDS database low space
        message: AWS RDS instance {{\`{{ \$labels.dbinstance_identifier }}\`}} FreeStorageSpace is less than 1GB.
      expr: |
        aws_rds_free_storage_space_average offset 10m < 1073741824
      for: 10m
      labels:
        severity: warning
    - alert: AwsRdsFreeStorageSpaceCritical
      annotations:
        summary: RDS database very low space
        message: AWS RDS instance {{\`{{ \$labels.dbinstance_identifier }}\`}} FreeStorageSpace is less than 100MB.
      expr: |
        aws_rds_free_storage_space_average offset 10m < 104857600
      for: 10m
      labels:
        severity: critical
    - alert: AwsRdsFreeStorageSpaceWillFillIn4Hours
      annotations:
        summary: RDS database out of space soon
        message: AWS RDS instance {{\`{{ \$labels.dbinstance_identifier }}\`}} will run out of free space in 4 hours.
      expr: |
        predict_linear(aws_rds_free_storage_space_average[6h] offset 10m, 4 * 3600) < 0
      for: 10m
      labels:
        severity: warning
EOF

cat deployment.yaml

echo $KUBECONFIG_JSON > k
export KUBECONFIG=k

kubectl apply --record -f - < deployment.yaml
