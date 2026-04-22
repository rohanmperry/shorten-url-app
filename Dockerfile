# Base stage — shared Python runtime and utils
# diff

FROM public.ecr.aws/lambda/python:3.11 AS base
COPY src/shared/utils.py ${LAMBDA_TASK_ROOT}/

# create_short_url stage
FROM base AS create-short-url
COPY src/create_short_url/handler.py ${LAMBDA_TASK_ROOT}/
CMD ["handler.lambda_handler"]

# redirect stage
FROM base AS redirect
COPY src/redirect/handler.py ${LAMBDA_TASK_ROOT}/
CMD ["handler.lambda_handler"]
