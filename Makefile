# Makefile is at repo root
REPO_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SERVER_VERSION := $(shell grep 'version in ThisBuild' $(REPO_ROOT)version.sbt | sed 's/.*"\(.*\)".*/\1/')
# Resolve IMAGE_TAG from ci/.env (used for push and deploy)
# IMAGE_TAG := $(shell grep '^IMAGE_TAG' $(REPO_ROOT)ci/.env | cut -d':' -f2 | tr -d ' =')

.PHONY: image
image:
	@echo "Building Docker image from fork (version $(SERVER_VERSION))"
	@cd $(REPO_ROOT) && build/sbt server/docker:publishLocal
	@echo "Image built: deltaio/delta-sharing-server:$(SERVER_VERSION)"
	@docker tag deltaio/delta-sharing-server:$(SERVER_VERSION) ${SERVICE_IMAGE}:${IMAGE_TAG:-dev}

.PHONY: push-dev
push-dev:
	@echo "Pushing Docker image as tag $(IMAGE_TAG)"
	@docker tag ${SERVICE_IMAGE}:dev gcr.io/zing-dev-197522/${SERVICE_IMAGE}:$(IMAGE_TAG)
	@docker push gcr.io/zing-dev-197522/${SERVICE_IMAGE}:$(IMAGE_TAG)

.PHONY: clean
clean:
	@echo "Cleaning up old files (from any previous pull-based builds)"
	@rm -rf delta-sharing-*
	@rm -f v*.tar.gz
	@echo "Cleanup complete. To clean SBT build artifacts, run: build/sbt clean"

.PHONY: deploy
deploy: deploy-dev

.PHONY: deploy-dev
deploy-dev:
	@echo "Deploying image tag $(IMAGE_TAG) to zing-dev"
	@cd ci && ./deploy.sh zing-dev-197522

.PHONY: deploy-preview
deploy-preview:
	@echo "Deploying image tag $(IMAGE_TAG) to zing-preview"
	@cd ci && ./deploy.sh zing-preview

.PHONY: deploy-prod
deploy-prod:
	@echo "Deploying image tag $(IMAGE_TAG) to zcloud-prod"
	@cd ci && ./deploy.sh zcloud-prod
