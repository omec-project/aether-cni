# Copyright 2019-present Open Networking Foundation
# SPDX-FileCopyrightText: 2024 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#
#

PROJECT_NAME             := aether-cni
VERSION                  ?= $(shell cat ./VERSION 2>/dev/null || echo "dev")

# Number of processors for parallel builds (Linux only)
NPROCS                   := $(shell nproc)

## Docker configuration
DOCKER_REGISTRY          ?=
DOCKER_REPOSITORY        ?=
DOCKER_TAG               ?= $(VERSION)
DOCKER_IMAGE_PREFIX      ?= 
DOCKER_IMAGENAME         := $(DOCKER_REGISTRY)$(DOCKER_REPOSITORY)$(DOCKER_IMAGE_PREFIX)$(PROJECT_NAME):$(DOCKER_TAG)
DOCKER_BUILDKIT          ?= 1
DOCKER_BUILD_ARGS        ?= --build-arg MAKEFLAGS=-j$(NPROCS)
DOCKER_PULL              ?= --pull

## Docker labels with better error handling
DOCKER_LABEL_VCS_URL     ?= $(shell git remote get-url origin 2>/dev/null || echo "unknown")
DOCKER_LABEL_VCS_REF     ?= $(shell \
	echo "$${GIT_COMMIT:-$${GITHUB_SHA:-$${CI_COMMIT_SHA:-$(shell \
		if git rev-parse --git-dir > /dev/null 2>&1; then \
			git rev-parse HEAD 2>/dev/null; \
		else \
			echo "unknown"; \
		fi \
	)}}}")
DOCKER_LABEL_BUILD_DATE  ?= $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")

## Build configuration
BINARY_NAME              := $(PROJECT_NAME)

# Default target
.DEFAULT_GOAL := help

## Help target
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | sort

## Docker targets
docker-build: ## Build Docker image
	@echo "Building Docker image: $(DOCKER_IMAGENAME)"
	@DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build $(DOCKER_PULL) $(DOCKER_BUILD_ARGS) \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_URL="$(DOCKER_LABEL_VCS_URL)" \
		--build-arg VCS_REF="$(DOCKER_LABEL_VCS_REF)" \
		--build-arg BUILD_DATE="$(DOCKER_LABEL_BUILD_DATE)" \
		--tag $(DOCKER_IMAGENAME) \
		. \
		|| exit 1

docker-push: ## Push Docker image to registry
	@echo "Pushing Docker image: $(DOCKER_IMAGENAME)"
	@docker push $(DOCKER_IMAGENAME)

docker-clean: ## Remove local Docker image
	@echo "Cleaning local Docker image..."
	@docker rmi $(DOCKER_IMAGENAME) 2>/dev/null || true

## Utility targets
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(BIN_DIR)
	@rm -rf $(COVERAGE_DIR)
	@rm -rf vendor
	@docker system prune -f --filter label=org.opencontainers.image.source="https://github.com/omec-project/$(PROJECT_NAME)" 2>/dev/null || true

print-version: ## Print current version
	@echo $(VERSION)

env: ## Print environment variables
	@echo "PROJECT_NAME=$(PROJECT_NAME)"
	@echo "VERSION=$(VERSION)"
	@echo "BINARY_NAME=$(BINARY_NAME)"
	@echo "DOCKER_REGISTRY=$(DOCKER_REGISTRY)"
	@echo "DOCKER_REPOSITORY=$(DOCKER_REPOSITORY)"
	@echo "DOCKER_IMAGE_PREFIX=$(DOCKER_IMAGE_PREFIX)"
	@echo "DOCKER_TAG=$(DOCKER_TAG)"
	@echo "DOCKER_IMAGENAME=$(DOCKER_IMAGENAME)"
	@echo "DOCKER_LABEL_VCS_URL=$(DOCKER_LABEL_VCS_URL)"
	@echo "DOCKER_LABEL_VCS_REF=$(DOCKER_LABEL_VCS_REF)"
	@echo "NPROCS=$(NPROCS)"
