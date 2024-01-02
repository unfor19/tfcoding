.EXPORT_ALL_VARIABLES:
TFCODING_VERSION ?= 0.0.10
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
	docker build --platform linux/${DOCKER_PLATFORM} -t $(DOCKER_TAG) -t ${DOCKER_TAG_LATEST} \
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
	@docker volume rm tfcoding_code_dir_tmp 2>/dev/null || true

up-localstack:       ## Run localstack in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-localstack.yml up --detach

up-aws:              ## Run tfcoding-aws in Docker Compose
	@export SRC_DIR_RELATIVE_PATH="examples/mock-aws" && \
	docker-compose -p tfcoding_aws -f docker-compose-aws.yml up

up-aws-localstack:    up-localstack up-aws ##

up-localstack-aws:    up-aws-localstack

down-aws:            ## Stop tfcoding-aws in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml down

down-localstack:     ## Stop localstack in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-localstack.yml down

clean-localstack:    ## Clean localstack in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-localstack.yml down -v --remove-orphans
	@docker rm -f localstack 2>/dev/null || true
	@rm -rf .localstack 2>/dev/null || true

clean-aws:           ## Clean tfcoding in Docker Compose
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml down -v --remove-orphans
	@docker rm -f tfcoding-aws 2>/dev/null || true
	@docker volume rm tfcoding_aws_code_dir_tmp_aws tfcoding_aws_plugins_cache_dir 2>/dev/null || true

down-aws-localstack:  down-aws down-localstack ##

down-localstack-aws:  down-aws-localstack

clean-aws-localstack: clean-aws clean-localstack ##

clean-localstack-aws: clean-aws-localstack

test:                ## Run tests
	@./scripts/tests.sh

clean-all:            clean clean-aws-localstack ##
