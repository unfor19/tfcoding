.EXPORT_ALL_VARIABLES:
TFCODING_VERSION ?= 0.0.12
TERRAFORM_VERSION ?= 1.6.6
DOCKER_TAG ?= unfor19/tfcoding:$(TERRAFORM_VERSION)-$(TFCODING_VERSION)
DOCKER_TAG_LATEST:=unfor19/tfcoding:latest
SRC_DIR_RELATIVE_PATH ?= examples/basic

ifndef DOCKER_PLATFORM
DOCKER_PLATFORM:=$(shell arch)
endif

help:                ## Available make commands
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:~~' | sed -e 's~##~~'

usage: help         


build:               ## Build tfcoding Docker image - default: terraform v0.13.6
	docker build --platform linux/${DOCKER_PLATFORM} \
		--progress=plain \
		-t $(DOCKER_TAG) -t ${DOCKER_TAG_LATEST} \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
		--build-arg OS_ARCH=${OS_ARCH} .


run:                 ## Run tfcoding in Docker
	docker run --rm -it \
	-v ${PWD}/:/src/:ro \
	$(DOCKER_TAG_LATEST) -r $(SRC_DIR_RELATIVE_PATH) --watching


up:                  ## Run tfcoding in Docker Compose
	@docker-compose -p tfcoding up


down:                ## Stop tfcoding in Docker Compose
	@docker-compose -p tfcoding down


clean:               ## Clean tfcoding in Docker Compose
	@docker-compose -p tfcoding down -v --remove-orphans
	@docker rm -f tfcoding 2>/dev/null || true


up-aws:              ## Run tfcoding-aws in Docker Compose
	@export SRC_DIR_RELATIVE_PATH="examples/mock-aws" && \
	docker-compose -p tfcoding_aws -f docker-compose-aws.yml up


down-aws:            ## Stop tfcoding-aws in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml down


test:                ## Run tests
	@./scripts/tests.sh


clean-aws:           ## Clean tfcoding in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml down -v --remove-orphans
	@docker rm -f tfcoding-aws 2>/dev/null || true

clean-all: clean clean-aws
