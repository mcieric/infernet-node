# Use bash as shell
SHELL := /bin/bash

# Phony targets
.PHONY: install run deps

# Default: install deps
all: install

# Install dependencies
install:
	@uv venv && \
	source .venv/bin/activate && \
	uv pip install -r requirements.lock

# Update dependencies & generate new lockfile
update-lockfile:
	@uv venv && \
	source .venv/bin/activate && \
	uv pip install -r requirements.txt && \
	uv pip freeze > requirements.lock

# Lint code
lint:
	@echo "Linting src/"
	@ruff check src --fix
	@echo "Linting scripts/"
	@ruff check scripts --fix

# Type check code
types:
	@mypy src/main.py --check-untyped-defs

# Format code
format:
	@echo "Formatting src/"
	@ruff format src
	@echo "Formatting scripts/"
	@ruff format scripts

# Run process
run:
	@python3.11 src/main.py

# Script: register node
register-node:
	@PYTHONPATH=$$PYTHONPATH:src python3.11 scripts/register_node.py

# Script: activate node
activate-node:
	@PYTHONPATH=$$PYTHONPATH:src python3.11 scripts/activate_node.py

# Get the current git commit hash
GIT_COMMIT_HASH := $(shell git rev-parse --short HEAD)

# Set the tag to include commit hash
tag ?= 1.2.0

image_id = ritualnetwork/infernet-node:$(tag)

build:
	docker build -t $(image_id) .

build-gpu:
	docker build -t $(image_id)-gpu -f Dockerfile-gpu .

publish:
	docker image push $(image_id)

run-node:
	docker-compose -f deploy/docker-compose.yaml up

service := echo

stop-node:
	docker-compose -f deploy/docker-compose.yaml kill || true
	docker-compose -f deploy/docker-compose.yaml rm -f || true
	docker kill $(service) || true
	docker rm $(service) || true

# You may need to set up a docker builder, to do so run:
# docker buildx create --name mybuilder --bootstrap --use
# refer to https://docs.docker.com/build/building/multi-platform/#building-multi-platform-images for more info
build-multiplatform:
	docker buildx build --platform linux/amd64,linux/arm64 -t $(image_id) --push .
	docker buildx build --platform linux/amd64,linux/arm64 -t $(image_id)-gpu -f Dockerfile-gpu --push .
