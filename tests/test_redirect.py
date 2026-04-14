import json
import os
import pytest
import boto3
from moto import mock_aws


@pytest.fixture(autouse=True)
def set_env_vars():
    os.environ["DYNAMODB_TABLE"] = "test-urls"
    os.environ["ENVIRONMENT"] = "test"


@pytest.fixture
def mock_table():
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb.create_table(
            TableName="test-urls",
            KeySchema=[{"AttributeName": "short_code", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "short_code", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        table.put_item(Item={
            "short_code": "abc123",
            "original_url": "https://www.google.com"
        })
        yield table


def make_event(code: str) -> dict:
    return {
        "version": "2.0",
        "routeKey": "GET /{code}",
        "rawPath": f"/{code}",
        "rawQueryString": "",
        "headers": {"content-type": "application/json"},
        "pathParameters": {"code": code},
        "isBase64Encoded": False,
    }


class TestRedirect:
    def test_valid_code_returns_301(self, mock_table):
        from src.redirect.handler import lambda_handler
        event = make_event("abc123")
        response = lambda_handler(event, {})
        assert response["statusCode"] == 301

    def test_valid_code_returns_correct_location(self, mock_table):
        from src.redirect.handler import lambda_handler
        event = make_event("abc123")
        response = lambda_handler(event, {})
        assert response["headers"]["Location"] == "https://www.google.com"

    def test_unknown_code_returns_404(self, mock_table):
        from src.redirect.handler import lambda_handler
        event = make_event("unknown")
        response = lambda_handler(event, {})
        assert response["statusCode"] == 404

    def test_missing_code_returns_400(self, mock_table):
        from src.redirect.handler import lambda_handler
        event = make_event("")
        response = lambda_handler(event, {})
        assert response["statusCode"] == 400
