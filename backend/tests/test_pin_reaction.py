from database.db import SessionLocal
from models.pin import Pin
 
 
class TestReactToPin:
    """Test plan reference: React to pin"""
 
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
 
        response = client.post(
            f"/pins/{pin_id}/reactions",
            headers=auth_headers,
            json={"reaction": "like"}
        )
        assert response.status_code == 201
 
        # cleanup
        client.delete(f"/pins/{pin_id}/reactions", headers=auth_headers)
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_change_reaction_from_like_to_dislike_expect_200(self, client, auth_headers):
        """Updating an existing reaction from like to dislike should return 200"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.post(
            f"/pins/{pin_id}/reactions",
            headers=auth_headers,
            json={"reaction": "like"}
        )
 
        response = client.post(
            f"/pins/{pin_id}/reactions",
            headers=auth_headers,
            json={"reaction": "dislike"}
        )
        assert response.status_code == 200
 
        # cleanup
        client.delete(f"/pins/{pin_id}/reactions", headers=auth_headers)
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_remove_reaction_with_null_expect_204(self, client, auth_headers):
        """Passing null as the reaction value should remove the existing reaction"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.post(
            f"/pins/{pin_id}/reactions",
            headers=auth_headers,
            json={"reaction": "like"}
        )
 
        response = client.post(
            f"/pins/{pin_id}/reactions",
            headers=auth_headers,
            json={"reaction": None}
        )
        assert response.status_code == 204
 
        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_react_to_nonexistent_pin_expect_404(self, client, auth_headers):
        """Reacting to a pin that does not exist should return 404"""
        response = client.post(
            "/pins/999999/reactions",
            headers=auth_headers,
            json={"reaction": "like"}
        )
        assert response.status_code == 404
 
    def test_react_with_invalid_reaction_type_expect_422(self, client, auth_headers):
        """An unrecognised reaction type should be rejected with 422"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        response = client.post(
            f"/pins/{pin_id}/reactions",
            headers=auth_headers,
            json={"reaction": "love"}
        )
        assert response.status_code == 422
 
        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_react_without_auth_expect_401(self, client):
        """Reacting without authentication should return 401"""
        response = client.post(
            "/pins/1/reactions",
            json={"reaction": "like"}
        )
        assert response.status_code == 401