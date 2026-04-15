TERRAFORM_DIR  := terraform
PROJECT_NAME   := shorten-url
AWS_REGION     := us-east-1
TAG            := latest

# Use lazy evaluation
# := -- Evaluate immediately
# =  -- Evaluate lazyli, only when the variable is used
#
AWS_ACCOUNT_ID         = $(shell aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY           = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
CREATE_SHORT_URL_IMAGE = $(ECR_REGISTRY)/$(PROJECT_NAME)/create-short-url:$(TAG)
REDIRECT_IMAGE         = $(ECR_REGISTRY)/$(PROJECT_NAME)/redirect:$(TAG)

ifdef TF_IN_AUTOMATION
AUTO_APPROVE := -auto-approve
PYTEST       := pytest
else
AUTO_APPROVE :=
PYTEST       := $(HOME)/.venv/shorten-url-app/bin/pytest
endif

.PHONY: init plan apply destroy fmt validate login build push test install-dev check-env

check-env:
ifndef TF_IN_AUTOMATION
ifndef AWS_PROFILE
	$(error AWS_PROFILE is not set. Please set it in your shell: export AWS_PROFILE=<aws_profile>)
endif
endif

install-dev:
	pip install -r requirements-dev.txt

test:
	$(PYTEST) tests/ -v

init: check-env
	terraform -chdir=$(TERRAFORM_DIR) init

validate:
	terraform -chdir=$(TERRAFORM_DIR) validate

plan: check-env
	terraform -chdir=$(TERRAFORM_DIR) plan -input=false

apply: check-env
	terraform -chdir=$(TERRAFORM_DIR) apply $(AUTO_APPROVE)

destroy: check-env
	terraform -chdir=$(TERRAFORM_DIR) destroy $(AUTO_APPROVE)

fmt:
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive

login: check-env
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(ECR_REGISTRY)

build-only:
	# Without the -t (tag) option, Dockers builds and discards it,
	# just for testing the biuld.
	docker build --target create-short-url .
	docker build --target redirect .

build: check-env
	docker build --target create-short-url -t $(CREATE_SHORT_URL_IMAGE) .
	docker build --target redirect -t $(REDIRECT_IMAGE) .

push: login
	docker push $(CREATE_SHORT_URL_IMAGE)
	docker push $(REDIRECT_IMAGE)
