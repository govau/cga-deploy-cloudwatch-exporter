# Deploy cloudwatch exporter in cloud.gov.au

Export AWS cloudwatch metrics so they can be scraped by prometheus.

We use the [official prometheus cloudwatch exporter](https://github.com/prometheus/cloudwatch_exporter) deployed on Kubernetes.

## Setup

```bash
# Create kubernetes namespaces (requires cluster admin)
./k8s-bootstrap.sh

# set the secrets in CI
./ci/set-secrets.sh

# Upload/update pipeline to CI
./ci/create-pipeline.sh
```
