#!/bin/bash

# Deploy Delta Sharing Server to a k8s cluster
# Usage: ./deploy.sh <environment>
# Environments: dev, preview, prod

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  echo "  Environments: dev, preview, prod"
  exit 1
fi

ENV="$1"

case "$ENV" in
  dev)
    GCLOUD_PROJECT="zing-dev-197522"
    TEMPLATE="${SCRIPT_DIR}/deployment-dev.yaml"
    ;;
  preview)
    GCLOUD_PROJECT="zing-preview"
    TEMPLATE="${SCRIPT_DIR}/deployment-preview.yaml"
    ;;
  prod)
    GCLOUD_PROJECT="zcloud-prod"
    TEMPLATE="${SCRIPT_DIR}/deployment-prod.yaml"
    ;;
  *)
    echo "Unknown environment: $ENV"
    echo "  Valid environments: dev, preview, prod"
    exit 1
    ;;
esac

# Read IMAGE_TAG from .env file (Makefile format: KEY := value)
if [ -f "${SCRIPT_DIR}/.env" ]; then
  IMAGE_TAG=$(grep '^IMAGE_TAG' "${SCRIPT_DIR}/.env" | cut -d':' -f2 | tr -d ' =')
fi

export IMAGE_TAG=${IMAGE_TAG:-latest}

echo "Deploying Delta Sharing Server..."
echo "  Environment : $ENV"
echo "  Project     : $GCLOUD_PROJECT"
echo "  Image tag   : $IMAGE_TAG"
echo "  Template    : $(basename "$TEMPLATE")"
echo ""

echo "Switching k8s context to $GCLOUD_PROJECT..."
gcloud container clusters get-credentials zing-cluster --project "$GCLOUD_PROJECT"

echo "Creating deployment..."
sed -e "s/VERSION_PLACEHOLDER/${IMAGE_TAG}/g" "${TEMPLATE}" | kubectl apply -f -

echo ""
echo "✅ Deployment to $ENV ($GCLOUD_PROJECT) complete!"
echo ""
