from base import client
from database.db import SessionLocal
from models.pin import Pin
from models.pin_reaction import PinReaction
import pytest

class TestPinReactions:
    def setup_method(self):
        self.pin_id = 1  # Assumes pin with ID 1 exists
        self.user_id = 2  # Assumes user with ID 2 exists
        self.auth_headers = {"Authorization": "Bearer testtoken"}  # Replace with actual token logic

    def test_react_to_pin_like(self):
        response = client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": 1})
        assert response.status_code in (200, 201)
        assert "message" in response.json()

    def test_react_to_pin_dislike(self):
        response = client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": -1})
        assert response.status_code in (200, 201)
        assert "message" in response.json()

    def test_change_reaction(self):
        client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": 1})
        response = client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": -1})
        assert response.status_code == 200
        assert response.json()["message"] == "Reaction updated"

    def test_duplicate_reaction(self):
        client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": 1})
        response = client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": 1})
        assert response.status_code == 200
        assert response.json()["message"] == "Reaction already set"

    def test_react_to_nonexistent_pin(self):
        response = client.post(f"/pins/9999/react", headers=self.auth_headers, json={"value": 1})
        assert response.status_code == 404

    def test_react_with_invalid_value(self):
        response = client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": 0})
        assert response.status_code == 422

    def test_react_with_invalid_user(self):
        headers = {"Authorization": "Bearer invalidtoken"}
        response = client.post(f"/pins/{self.pin_id}/react", headers=headers, json={"value": 1})
        assert response.status_code in (401, 403)
