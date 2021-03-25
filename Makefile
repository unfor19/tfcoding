.EXPORT_ALL_VARIABLES:
DOCKER_IMAGE_PREFIX ?= unfor19/tfcoding:latest
TERRAFORM_VERSION ?= 0.13.5
DOCKER_TAG ?= unfor19/tfcoding:latest-tf$(TERRAFORM_VERSION)
SRC_DIR_RELATIVE_PATH ?= examples/basic

help:               ## Available make commands
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:~~' | sed -e 's~##~~' | sed -e '2d'

usage: help         ## Available make commands

build:              ## Build tfcoding Docker image - default: terraform v0.13.5
	docker build -t $(DOCKER_TAG) \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) .

run:                ## Run tfcoding
	docker run --rm -it \
	-v ${PWD}/:/src/:ro \
	$(DOCKER_TAG) -r $(SRC_DIR_RELATIVE_PATH) --watching 

up:         ## Run tfcoding
	@docker-compose -p tfcoding up

down:       ## Stop tfcoding
	@docker-compose -p tfcoding down

up-localstack:     ## Run localstack (AWS mock)
	@docker-compose -p tfcoding_aws -f docker-compose-localstack.yml up --detach

up-aws:            ## Run tfcoding and localstack (AWS mock)
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml up

up-aws-localstack: up-localstack up-aws

down-aws:          ## Run tfcoding and localstack (AWS mock)
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml down

down-localstack:   ## Run tfcoding and localstack (AWS mock)
	@docker-compose -p tfcoding_aws -f docker-compose-localstack.yml down

down-aws-localstack: down-aws down-localstack

test:              ## Run tests
	@./scripts/tests.sh

clean:
	@docker-compose -p tfcoding down -v --remove-orphans
	@docker rm -f tfcoding 2>/dev/null || true
	@docker volume rm tfcoding_code_dir_tmp 2>/dev/null || true

clean-aws:
	@docker-compose -p tfcoding_aws -f docker-compose-aws.yml down -v --remove-orphans
	@docker rm -f tfcoding-aws 2>/dev/null || true
	@docker volume rm tfcoding_code_dir_tmp_aws tfcoding_plugins_cache_dir 2>/dev/null || true

clean-localstack:
	@docker-compose -p tfcoding_aws -f docker-compose-localstack.yml down -v --remove-orphans
	@docker rm -f localstack 2>/dev/null || true
	@rm -rf .localstack 2>/dev/null || true

clean-aws-localstack: clean-aws clean-localstack

clean-all: clean clean-aws-localstack
