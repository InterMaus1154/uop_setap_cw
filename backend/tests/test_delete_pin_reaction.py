from base import client
from database.db import SessionLocal
from models.pin import Pin
from models.pin_reaction import PinReaction
import pytest

class TestDeletePinReaction:
    def setup_method(self):
        self.pin_id = 1  # Assumes pin with ID 1 exists
        self.user_id = 2  # Assumes user with ID 2 exists
        self.auth_headers = {"Authorization": "Bearer testtoken"}  # Replace with actual token logic

    def test_delete_existing_reaction(self):
        # Ensure reaction exists first
        client.post(f"/pins/{self.pin_id}/react", headers=self.auth_headers, json={"value": 1})
        response = client.delete(f"/pins/{self.pin_id}/react", headers=self.auth_headers)
        assert response.status_code == 200
        assert "message" in response.json() or response.json() == {}

    def test_delete_nonexistent_reaction(self):
        # Ensure reaction does not exist
        client.delete(f"/pins/{self.pin_id}/react", headers=self.auth_headers)
        response = client.delete(f"/pins/{self.pin_id}/react", headers=self.auth_headers)
        assert response.status_code == 200 or response.status_code == 404

    def test_delete_reaction_nonexistent_pin(self):
        response = client.delete(f"/pins/9999/react", headers=self.auth_headers)
        assert response.status_code == 404

    def test_delete_reaction_nonexistent_user(self):
        headers = {"Authorization": "Bearer invalidtoken"}
        response = client.delete(f"/pins/{self.pin_id}/react", headers=headers)
        assert response.status_code in (401, 403)

    def test_delete_reaction_invalid_pin_id(self):
        response = client.delete(f"/pins/-1/react", headers=self.auth_headers)
        assert response.status_code in (404, 422)

    def test_delete_reaction_invalid_user_id(self):
        # This test assumes user_id is derived from the token, so invalid token is used
        headers = {"Authorization": "Bearer invalidtoken"}
        response = client.delete(f"/pins/{self.pin_id}/react", headers=headers)
        assert response.status_code in (401, 403)
