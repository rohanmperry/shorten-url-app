# shorten-url-app

Application code and container infrastructure for the [shorten-url](https://short.manamperi.com) 
serverless URL shortener project.

## What it contains

- **Lambda functions** — Python 3.11 handlers for creating and redirecting short URLs
- **Frontend** — Static HTML/CSS/JS web interface served via CloudFront
- **ECR repositories** — Docker image storage for Lambda functions
- **Tests** — pytest/moto test suite

## Architecture

Two Lambda functions, each built as a separate Docker image from a multi-stage Dockerfile:

- `create_short_url` — validates and stores a long URL, returns a short code
- `redirect` — looks up a short code in DynamoDB and redirects to the original URL

## Repository structure
```
shorten-url-app/
├── src/
│   ├── create_short_url/   # Lambda handler for creating short URLs
│   ├── redirect/           # Lambda handler for redirecting
│   └── shared/             # Shared utilities (response builder, code generator)
├── tests/                  # pytest test suite using moto for AWS mocking
├── terraform/              # ECR repository Terraform
├── src/frontend/           # Static web frontend
│   ├── index.html          # Main page
│   ├── 404.html            # Custom error page
│   └── description.html    # Project description (editable separately)
└── Dockerfile              # Multi-stage build for both Lambda functions
```
## Local development

### Prerequisites
- Python 3.11
- Docker
- AWS CLI with `projects` profile
- Terraform >= 1.14

### Setup
```bash
# Create virtual environment
python3 -m venv ~/.venv/shorten-url-app
source ~/.venv/shorten-url-app/bin/activate

# Install dependencies
make install-dev
```

### Running tests
```bash
make test
```

### Building Docker images locally
```bash
make build
```

### Pushing images to ECR
```bash
make push
```

## CI/CD pipeline

### On pull request
1. Run pytest test suite
2. `terraform plan` — shows ECR changes
3. `docker build` — validates Dockerfile builds correctly (no push)

### On merge to main
1. Run pytest test suite
2. `terraform apply` — creates/updates ECR repositories
3. `docker build` — builds both Lambda images
4. `docker push` — pushes images to ECR
5. CloudFront cache invalidation — ensures latest frontend is served

## Infrastructure

ECR repositories managed by this repo:
- `shorten-url/create-short-url` — Docker image for create_short_url Lambda
- `shorten-url/redirect` — Docker image for redirect Lambda

Terraform state stored in S3: `my-projects-tfstate/shorten-url-app/terraform.tfstate`

## Related projects

- [aws-terraform-bootstrap](https://github.com/yourusername/aws-terraform-bootstrap) — Shared AWS bootstrap
- [shorten-url-infra](https://github.com/yourusername/shorten-url-infra) — AWS infrastructure
