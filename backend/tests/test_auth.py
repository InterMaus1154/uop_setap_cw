import pytest


class TestAuth:
    def test_login_with_valid_credentials(self, client):
        """Test plan reference: AUTH"""

        response = client.post("/auth/login", json={"email": "test@test.app"})

        data = response.json()

        assert response.status_code == 200
        assert "token" in data
        assert len(data["token"]) > 0

    def test_login_with_invalid_credentials(self, client):
        response = client.post("/auth/login", json={"email": "invalidmail@test.com"})

        assert response.status_code == 401

    def test_logout_with_valid_token(self, auth_headers, client):
        response = client.post("/auth/logout", headers=auth_headers)

        assert response.status_code == 200


    def test_logout_with_invalid_token(self, client):
        response = client.post("/auth/logout", headers={"Authorization": "Bearer sdghsdfhsdfh"})

        assert response.status_code == 401