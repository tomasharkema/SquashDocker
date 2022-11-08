#!/bin/bash

set -x
set -e

docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag docker.harkema.io/squash:latest .
docker pull docker.harkema.io/squash