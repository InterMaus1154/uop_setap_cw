
class TestUpdatePin:
    """Test plan reference: TP2"""

    TEST_PIN = {
        "cat_id": 1,
        "pin_title": "Test Pin for Updating",
        "pin_description": "Test Pin for updating",
        "pin_latitude": 50.7891,
        "pin_longitude": -1.0889,
        "pin_expire_at": "2026-05-30 20:00:00",
    }

    def _create_test_pin(self, client, auth_headers):
        response = client.post("/pins", headers=auth_headers, data=self.TEST_PIN)
        assert response.status_code == 201
        return response.json()["pin_id"]

    def test_update_pin_title_set_to_null_200(self, client, auth_headers):
        """Null title should be ignored, leaving the existing title unchanged"""
        pin_id = self._create_test_pin(client, auth_headers)

        response = client.put(f"/pins/{pin_id}", headers=auth_headers, json={"pin_title": None})
        assert response.status_code == 200
        assert response.json()["pin_title"] == self.TEST_PIN["pin_title"]

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_update_pin_title_exceeds_max_length_422(self, client, auth_headers):
        """Title longer than 100 characters should return 422"""
        pin_id = self._create_test_pin(client, auth_headers)

        response = client.put(f"/pins/{pin_id}", headers=auth_headers, json={"pin_title": "a" * 101})
        assert response.status_code == 422

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_update_pin_by_different_user_403(self, client, auth_headers, alt_auth_headers):
        """A user who did not create the pin should not be able to update it"""
        pin_id = self._create_test_pin(client, auth_headers)

        response = client.put(f"/pins/{pin_id}", headers=alt_auth_headers, json={"pin_title": "Hijacked"})
        assert response.status_code == 403

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_update_pin_not_found_404(self, client, auth_headers):
        """Updating a pin that does not exist should return 404"""
        response = client.put("/pins/999999", headers=auth_headers, json={"pin_title": "New Title"})
        assert response.status_code == 404
