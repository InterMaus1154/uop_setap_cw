from database.db import SessionLocal
from models.pin import Pin


class TestDeletePinReaction:
    """Test plan reference: Delete Pin Reaction"""

    TEST_PIN = {
        "cat_id": 1,
        "sub_cat_id": 3,
        "pin_title": "Test Pin for Reaction Deletion",
        "pin_description": "Test Pin for reaction deletion",
        "pin_latitude": 50.7891,
        "pin_longitude": -1.0889,
        "pin_expire_at": "2026-05-15 20:00:00",
    }

    def _create_test_pin(self, client, auth_headers):
        """Helper to create a test pin and return its id"""
        response = client.post("/pins", headers=auth_headers, data=self.TEST_PIN)
        assert response.status_code == 201
        return response.json()["pin_id"]


    def _add_reaction(self, client, auth_headers, pin_id, reaction_value=1):
        """Helper to add a reaction to a pin using the correct endpoint and payload"""
        response = client.patch(
            f"/pins/{pin_id}/react",
            headers=auth_headers,
            json={"value": reaction_value}
        )
        return response

    def test_delete_existing_reaction_expect_200(self, client, auth_headers):
        """Deleting a reaction that exists should remove it and return 200"""
        pin_id = self._create_test_pin(client, auth_headers)
        self._add_reaction(client, auth_headers, pin_id)

        response = client.delete(f"/pins/{pin_id}/react", headers=auth_headers)
        assert response.status_code == 200

        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_delete_reaction_that_does_not_exist_expect_404(self, client, auth_headers):
        """Attempting to delete a reaction that was never created should return 404"""
        pin_id = self._create_test_pin(client, auth_headers)

        # no reaction added, go straight to delete
        response = client.delete(f"/pins/{pin_id}/reactions", headers=auth_headers)
        assert response.status_code == 404

        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_delete_reaction_for_nonexistent_pin_expect_404(self, client, auth_headers):
        """Attempting to delete a reaction on a pin that does not exist should return 404"""
        response = client.delete("/pins/999999/reactions", headers=auth_headers)
        assert response.status_code == 404

    def test_delete_reaction_without_auth_expect_401(self, client):
        """Deleting a reaction without authentication should return 401"""
        response = client.delete("/pins/1/react")
        assert response.status_code == 401

    def test_delete_reaction_with_invalid_pin_id_expect_404(self, client, auth_headers):
        """A negative pin_id is not valid and should return 404 (not found)"""
        response = client.delete("/pins/-1/react", headers=auth_headers)
        assert response.status_code == 404

    def test_delete_reaction_then_verify_removed_from_db(self, client, auth_headers):
        """After deletion, the reaction should no longer exist"""
        pin_id = self._create_test_pin(client, auth_headers)
        self._add_reaction(client, auth_headers, pin_id)

        client.delete(f"/pins/{pin_id}/reactions", headers=auth_headers)

        # verify by trying to delete again — should now be 404
        response = client.delete(f"/pins/{pin_id}/reactions", headers=auth_headers)
        assert response.status_code == 404

        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)