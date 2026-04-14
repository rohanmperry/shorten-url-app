import json
import os
import pytest
import boto3
from moto import mock_aws


@pytest.fixture(autouse=True)
def set_env_vars():
    os.environ["DYNAMODB_TABLE"] = "test-urls"
    os.environ["BASE_URL"] = "https://test.example.com"
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
        yield table


def make_event(url: str) -> dict:
    return {
        "version": "2.0",
        "routeKey": "POST /shorten",
        "rawPath": "/shorten",
        "rawQueryString": "",
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"url": url}),
        "isBase64Encoded": False,
    }


class TestCreateShortUrl:
    def test_valid_url_returns_201(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = make_event("https://www.google.com")
        response = lambda_handler(event, {})
        assert response["statusCode"] == 201

    def test_response_contains_short_url(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = make_event("https://www.google.com")
        response = lambda_handler(event, {})
        body = json.loads(response["body"])
        assert "short_url" in body
        assert "short_code" in body
        assert "original_url" in body

    def test_short_url_contains_base_url(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = make_event("https://www.google.com")
        response = lambda_handler(event, {})
        body = json.loads(response["body"])
        assert body["short_url"].startswith("https://test.example.com")

    def test_missing_url_returns_400(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = make_event("")
        response = lambda_handler(event, {})
        assert response["statusCode"] == 400

    def test_invalid_url_scheme_returns_400(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = make_event("ftp://invalid.com")
        response = lambda_handler(event, {})
        assert response["statusCode"] == 400

    def test_invalid_json_returns_400(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = {**make_event(""), "body": "not json"}
        response = lambda_handler(event, {})
        assert response["statusCode"] == 400

    def test_url_saved_to_dynamodb(self, mock_table):
        from src.create_short_url.handler import lambda_handler
        event = make_event("https://www.google.com")
        response = lambda_handler(event, {})
        body = json.loads(response["body"])
        short_code = body["short_code"]

        item = mock_table.get_item(Key={"short_code": short_code})
        assert "Item" in item
        assert item["Item"]["original_url"] == "https://www.google.com"
