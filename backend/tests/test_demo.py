import pytest

from base import client


class TestDemo:
    def test_index(self):
        response = client.get("/")
        data = response.json()

        assert response.status_code == 200
        assert "message" in data
        assert data["message"] == "test"
