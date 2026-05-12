

class TestDeletePin:
    """Test plan reference: RP1"""
 
    TEST_PIN = {
        "cat_id": 1,
        "sub_cat_id": 3,
        "pin_title": "Test Pin for Deleting",
        "pin_description": "Test Pin for deleting",
        "pin_latitude": 50.7891,
        "pin_longitude": -1.0889,
        "pin_expire_at": "2026-05-15 20:00:00",
    }
 
    def _create_test_pin(self, client, auth_headers):
        """Helper to create a test pin and return its id"""
        response = client.post("/pins", headers=auth_headers, data=self.TEST_PIN)
        assert response.status_code == 201
        return response.json()["pin_id"]
 
    def test_delete_pin_by_different_user_expect_403(self, client, auth_headers, alt_auth_headers):
        """A user who did not create the pin should not be able to delete it"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        response = client.delete(f"/pins/{pin_id}", headers=alt_auth_headers)
        assert response.status_code == 403
 
        # cleanup
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
    def test_delete_pin_by_owner_returns_success_message(self, client, auth_headers):
        """Owner deleting their own pin should get a success message"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        response = client.delete(f"/pins/{pin_id}", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
 
    def test_deleted_pin_cannot_be_fetched(self, client, auth_headers):
        """Fetching a deleted pin should return 404"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
        response = client.get(f"/pins/{pin_id}", headers=auth_headers)
        assert response.status_code == 404
 
    def test_pin_count_decreases_after_delete(self, client, auth_headers):
        """User pin count should be 1 less after deleting a pin"""
        before = client.get("/pins", headers=auth_headers)
        count_before = len(before.json())
 
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
        after = client.get("/pins", headers=auth_headers)
        count_after = len(after.json())
 
        assert count_after == count_before
 
    def test_delete_already_deleted_pin_expect_404(self, client, auth_headers):
        """Deleting a pin that has already been deleted should return 404"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        client.delete(f"/pins/{pin_id}", headers=auth_headers)
 
        response = client.delete(f"/pins/{pin_id}", headers=auth_headers)
        assert response.status_code == 404
 
    def test_delete_pin_by_owner_expect_200(self, client, auth_headers):
        """The owner of a pin should be able to delete it successfully"""
        pin_id = self._create_test_pin(client, auth_headers)
 
        response = client.delete(f"/pins/{pin_id}", headers=auth_headers)
        assert response.status_code == 200

 