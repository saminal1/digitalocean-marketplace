#!make
.DEFAULT_GOAL := help

.PHONY: build-docker
build-docker: ## Build docker image
	packer build docker-image.json

.PHONY: build-do
build-do: ## build on digital ocean
	packer build marketplace-image.json

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
