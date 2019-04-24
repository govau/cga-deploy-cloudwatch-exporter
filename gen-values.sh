#!/bin/bash

set -eu
set -o pipefail

: "${ENV_NAME:?Need to set ENV_NAME e.g. d}"

cat <<EOF
aws:
  secret:
    name: ${ENV_NAME}cld-aws
rbac:
  create: false
serviceAccount:
  create: false
service:
  labels:
    monitor: me
config: |-
  region: ap-southeast-2
  metrics:
  - aws_namespace: "AWS/RDS"
    aws_dimensions: [DBInstanceIdentifier]
    aws_metric_name: FreeStorageSpace
    aws_statistics: [Average]
    period_seconds: 240
  - aws_namespace: "AWS/ES"
    aws_dimensions: [ClientId,DomainName]
    aws_metric_name: FreeStorageSpace
    aws_statistics: [Average]
  - aws_namespace: "AWS/Kinesis"
    aws_dimensions: [StreamName]
    aws_metric_name: GetRecords.IteratorAgeMilliseconds
    aws_statistics: [Average]

  # todo add more
  # - aws_namespace: AWS/S3
  #   aws_metric_name: BucketSizeBytes
  #   aws_dimensions: [BucketName, StorageType]
  #   period_seconds: 1
  # - aws_namespace: AWS/ELB
  #   aws_metric_name: HealthyHostCount
  #   aws_dimensions: [AvailabilityZone, LoadBalancerName]
  #   aws_statistics: [Average]

  # - aws_namespace: AWS/ELB
  #   aws_metric_name: UnHealthyHostCount
  #   aws_dimensions: [AvailabilityZone, LoadBalancerName]
  #   aws_statistics: [Average]

  # - aws_namespace: AWS/ELB
  #   aws_metric_name: RequestCount
  #   aws_dimensions: [AvailabilityZone, LoadBalancerName]
  #   aws_statistics: [Sum]

  # - aws_namespace: AWS/ELB
  #   aws_metric_name: Latency
  #   aws_dimensions: [AvailabilityZone, LoadBalancerName]
  #   aws_statistics: [Average]

  # - aws_namespace: AWS/ELB
  #   aws_metric_name: SurgeQueueLength
  #   aws_dimensions: [AvailabilityZone, LoadBalancerName]
  #   aws_statistics: [Maximum, Sum]
EOF
