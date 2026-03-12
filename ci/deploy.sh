#!/bin/bash

# Deploy Delta Sharing Server to k8s cluster
# Usage: ./deploy.sh <gcloud-project>

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
  echo "Usage: $0 <gcloud-project>"
  exit 1
fi

GCLOUD_PROJECT="$1"

# Read VERSION and IMAGE_TAG from .env file (Makefile format: KEY := value)
if [ -f "${SCRIPT_DIR}/.env" ]; then
  IMAGE_TAG=$(grep '^IMAGE_TAG' "${SCRIPT_DIR}/.env" | cut -d':' -f2 | tr -d ' =')
fi

export IMAGE_TAG=${IMAGE_TAG:-$VERSION}

echo "Deploying Delta Sharing Server..."
echo "  Project   : $GCLOUD_PROJECT"
echo "  Image tag : $IMAGE_TAG"
echo ""

echo "Switching k8s context to $GCLOUD_PROJECT..."
gcloud container clusters get-credentials zing-cluster --project "$GCLOUD_PROJECT"

echo "Creating deployment..."
sed \
  -e "s/VERSION_PLACEHOLDER/${IMAGE_TAG}/g" \
  -e "s/GCLOUD_PROJECT_PLACEHOLDER/${GCLOUD_PROJECT}/g" \
  "${SCRIPT_DIR}/deployment-template.yaml" | kubectl apply -f -

echo ""
echo "✅ Deployment to $GCLOUD_PROJECT complete!"
echo ""
