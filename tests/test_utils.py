import pytest
from src.shared.utils import generate_short_code, build_response, build_redirect_response
import json


class TestGenerateShortCode:
    def test_default_length(self):
        code = generate_short_code()
        assert len(code) == 6

    def test_custom_length(self):
        code = generate_short_code(length=10)
        assert len(code) == 10

    def test_alphanumeric_only(self):
        for _ in range(100):
            code = generate_short_code()
            assert code.isalnum()

    def test_uniqueness(self):
        codes = {generate_short_code() for _ in range(100)}
        assert len(codes) > 90


class TestBuildResponse:
    def test_status_code(self):
        response = build_response(200, {"message": "ok"})
        assert response["statusCode"] == 200

    def test_body_is_json_string(self):
        response = build_response(200, {"message": "ok"})
        assert isinstance(response["body"], str)
        assert json.loads(response["body"]) == {"message": "ok"}

    def test_content_type_header(self):
        response = build_response(200, {"message": "ok"})
        assert response["headers"]["Content-Type"] == "application/json"


class TestBuildRedirectResponse:
    def test_status_code(self):
        response = build_redirect_response("https://www.google.com")
        assert response["statusCode"] == 301

    def test_location_header(self):
        response = build_redirect_response("https://www.google.com")
        assert response["headers"]["Location"] == "https://www.google.com"

    def test_empty_body(self):
        response = build_redirect_response("https://www.google.com")
        assert response["body"] == ""
