AWS_REGION     := us-east-1
ECR_REGISTRY   := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
PROJECT_NAME   := shorten-url-app
TAG            := latest

CREATE_SHORT_URL_IMAGE := $(ECR_REGISTRY)/$(PROJECT_NAME)/create-short-url:$(TAG)
REDIRECT_IMAGE         := $(ECR_REGISTRY)/$(PROJECT_NAME)/redirect:$(TAG)

TERRAFORM_DIR := terraform

.PHONY: init plan apply destroy fmt validate login build push test install-dev all

ifndef TF_IN_AUTOMATION
export AWS_PROFILE := projects
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text --profile $(AWS_PROFILE))
AUTO_APPROVE :=
else
export AWS_PROFILE  :=
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
AUTO_APPROVE := -auto-approve
endif

install-dev:
	pip install -r requirements-dev.txt

test:
	pytest tests/ -v

init:
	terraform -chdir=$(TERRAFORM_DIR) init

validate:
	terraform -chdir=$(TERRAFORM_DIR) validate

plan:
	terraform -chdir=$(TERRAFORM_DIR) plan

apply:
	terraform -chdir=$(TERRAFORM_DIR) apply $(AUTO_APPROVE)

destroy:
	terraform -chdir=$(TERRAFORM_DIR) destroy $(AUTO_APPROVE)

fmt:
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive

login:
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(ECR_REGISTRY)

build:
	docker build --target create-short-url -t $(CREATE_SHORT_URL_IMAGE) .
	docker build --target redirect -t $(REDIRECT_IMAGE) .

push: login
	docker push $(CREATE_SHORT_URL_IMAGE)
	docker push $(REDIRECT_IMAGE)

all: test build push
