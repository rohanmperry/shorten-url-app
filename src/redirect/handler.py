import json
import logging
import os

import boto3
from botocore.exceptions import ClientError

from utils import build_response, build_redirect_response

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")


def get_original_url(table_name: str, short_code: str) -> str | None:
    """Look up the original URL for a given short code."""
    table = dynamodb.Table(table_name)
    try:
        response = table.get_item(Key={"short_code": short_code})
        item = response.get("Item")
        return item["original_url"] if item else None
    except ClientError as e:
        logger.error("DynamoDB error: %s", str(e))
        return None


def lambda_handler(event: dict, context) -> dict:
    logger.info("Received event: %s", json.dumps(event))

    # Extract short code from path parameters
    path_parameters = event.get("pathParameters") or {}
    short_code = path_parameters.get("code", "").strip()

    if not short_code:
        return build_response(400, {"error": "Missing short code"})

    # Look up original URL
    table_name = os.environ["DYNAMODB_TABLE"]
    original_url = get_original_url(table_name, short_code)

    if not original_url:
        return build_response(404, {"error": f"Short code not found: {short_code}"})

    logger.info("Redirecting %s -> %s", short_code, original_url)

    return build_redirect_response(original_url)
