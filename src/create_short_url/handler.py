import json
import logging
import os
import time

import boto3
from botocore.exceptions import ClientError

from utils import build_response, generate_short_code

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")


def lambda_handler(event: dict, context) -> dict:
    logger.info("Received event: %s", json.dumps(event))

    # Parse request body
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return build_response(400, {"error": "Invalid JSON in request body"})

    # Validate input
    original_url = body.get("url", "").strip()
    if not original_url:
        return build_response(400, {"error": "Missing required field: url"})

    if not original_url.startswith(("http://", "https://")):
        return build_response(400, {"error": "URL must start with http:// or https://"})

    # Generate unique short code
    table_name = os.environ["DYNAMODB_TABLE"]
    base_url = os.environ["BASE_URL"]
    table = dynamodb.Table(table_name)

    for _ in range(5):
        short_code = generate_short_code()
        try:
            table.put_item(
                Item={
                    "short_code": short_code,
                    "original_url": original_url,
                    "expires_at": int(time.time()) + (3 * 24 * 60 * 60),  # 3 days
                },
                ConditionExpression="attribute_not_exists(short_code)"
            )
            break
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                logger.warning("Short code collision: %s — retrying", short_code)
                continue
            logger.error("DynamoDB error: %s", str(e))
            return build_response(500, {"error": "Internal server error"})
    else:
        return build_response(500, {"error": "Could not generate unique short code"})

    short_url = f"{base_url}/{short_code}"
    logger.info("Created short URL: %s -> %s", short_url, original_url)

    return build_response(201, {
        "short_url": short_url,
        "short_code": short_code,
        "original_url": original_url,
    })
