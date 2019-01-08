# Deploy cloudwatch exporter in cloud.gov.au

Export AWS cloudwatch metrics so they can be scraped by prometheus.

We use the [technofy cloudwatch exporter](https://github.com/govau/cga_cloudwatch_exporter) deployed on Kubernetes.

## Docker image

The docker image is built and published into ECR as part of the pipeline.

If you want to build and run the image locally:

```bash
# Get the app files and trick go to use our fork and not upstream
mkdir -p $GOPATH/src/github/technofy/cloudwatch_exporter
cd $GOPATH/src/github/technofy/cloudwatch_exporter
git checkout https://github.com/govau/cga_cloudwatch_exporter.git

# Build the app for linux
CGO_ENABLED=0 \
GOOS=linux \
GOARCH=amd64 \
go build .

# Build the image
docker build --tag govau/cga_cloudwatch_exporter .

# Run the image
docker run -it --rm --tag govau/cga_cloudwatch_exporter
```

## Configuration and secrets

The cloudwatch exporter needs a config.yml file, and secrets to access cloudwatch in each environment.

To set these, run [ci/set-secrets.sh](ci/set-secrets.sh). If run again, it will rotate them.

## misc

```bash
# list pods
k get pods

# ssh to pod
k exec -it <pod-name> sh
