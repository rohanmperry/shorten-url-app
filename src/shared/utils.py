import random
import string


def generate_short_code(length: int = 6) -> str:
    """Generate a random alphanumeric short code."""
    characters = string.ascii_letters + string.digits
    return "".join(random.choices(characters, k=length))


def build_response(status_code: int, body: dict) -> dict:
    """Build a standard Lambda response."""
    import json
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }


def build_redirect_response(url: str) -> dict:
    """Build a 301 redirect response."""
    return {
        "statusCode": 301,
        "headers": {
            "Location": url
        },
        "body": ""
    }
