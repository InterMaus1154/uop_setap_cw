from database.db import SessionLocal
from models.pin import Pin
 
 
class TestReactToPin:
    """Test plan reference: React to pin (PR1)"""
 
    TEST_PIN = {
        "cat_id": 1,
        "sub_cat_id": 3,
        "pin_title": "Test Pin for Reacting",
        "pin_description": "Test Pin for reacting",
        "pin_latitude": 50.7891,
        "pin_longitude": -1.0889,
        "pin_expire_at": "2026-05-15 20:00:00",
    }
 
    def _create_test_pin(self, client, auth_headers):
        """Helper to create a test pin and return its id"""
        response = client.post("/pins", headers=auth_headers, data=self.TEST_PIN)
        assert response.status_code == 201
        return response.json()["pin_id"]
 
    def test_valid_like_reaction_expect_201(self, client, auth_headers):
        """A valid like reaction on an existing pin should be created successfully"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        response = client.patch(
            f"/pins/{pin_id}/react",
            headers=auth_headers,
            json={"value": 1}
        )
        assert response.status_code == 201
 
        # cleanup
        client.delete(f"/pins/{pin_id}/react", headers=auth_headers)
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_change_reaction_from_like_to_dislike_expect_200(self, client, auth_headers):
        """Updating an existing reaction from like to dislike should return 200"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.patch(
            f"/pins/{pin_id}/react",
            headers=auth_headers,
            json={"value": 1}
        )
 
        response = client.patch(
            f"/pins/{pin_id}/react",
            headers=auth_headers,
            json={"value": -1}
        )
        assert response.status_code == 200
 
        # cleanup
        client.delete(f"/pins/{pin_id}/react", headers=auth_headers)
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_remove_reaction_with_delete_expect_200(self, client, auth_headers):
        """Deleting a reaction should remove the existing reaction"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.patch(
            f"/pins/{pin_id}/react",
            headers=auth_headers,
            json={"value": 1}
        )
 
        response = client.delete(
            f"/pins/{pin_id}/react",
            headers=auth_headers
        )
        assert response.status_code == 200
 
        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_react_to_nonexistent_pin_expect_404(self, client, auth_headers):
        """Reacting to a pin that does not exist should return 404"""
        response = client.patch(
            "/pins/999999/react",
            headers=auth_headers,
            json={"value": 1}
        )
        assert response.status_code == 404
 
    def test_react_with_invalid_value_type_expect_422(self, client, auth_headers):
        """Passing a string instead of an integer should be rejected by FastAPI with 422"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        response = client.patch(
            f"/pins/{pin_id}/react",
            headers=auth_headers,
            json={"value": "love"}
        )
        assert response.status_code == 422
 
        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_react_without_auth_expect_401(self, client):
        """Reacting without authentication should return 401"""
        response = client.patch(
            "/pins/1/react",
            json={"value": 1}
        )
        assert response.status_code == 401
 