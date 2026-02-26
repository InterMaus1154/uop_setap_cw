import pytest
from base import client

class TestAuth:
    def test_login_with_valid_credentials(self):
        response = client.post("/auth/login", json={"email": "test@test.app"})

        data = response.json()

        assert response.status_code == 200
        assert "token" in data
        assert len(data["token"]) > 0

    def test_login_with_invalid_credentials(self):
        response = client.post("/auth/login", json={"email": "invalidmail@test.com"})

        assert response.status_code == 401

    def test_logout_with_valid_token(self, auth_headers):
        response = client.post("/auth/logout", headers=auth_headers)

        assert response.status_code == 200

        # re-login with test user to have the token for further tests
        client.post("/auth/login", json={"email": "test@test.app"})

    def test_logout_with_invalid_token(self):
        response = client.post("/auth/logout", headers={"Authorization": "Bearer sdghsdfhsdfh"})

        assert response.status_code == 401