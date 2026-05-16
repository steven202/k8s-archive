#!/bin/bash
# Build and push the custom K8s pod image to Docker Hub.
# Usage: ./build.sh [tag]
#   On Mac with Docker Desktop: just run it.
#   On Linux without Docker: use the GitHub Actions workflow instead.

set -euo pipefail

TAG="${1:-latest}"
IMAGE="cwang33/k8s-dev:${TAG}"

echo "=== Building ${IMAGE} ==="
docker build -t "${IMAGE}" -f "$(dirname "$0")/Dockerfile" "$(dirname "$0")"

echo ""
echo "=== Pushing ${IMAGE} ==="
docker push "${IMAGE}"

echo ""
echo "=== Done. Update YAMLs to use: ${IMAGE} ==="
