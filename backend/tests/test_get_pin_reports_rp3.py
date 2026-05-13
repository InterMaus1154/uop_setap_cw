
class TestGetPinReports:
    """Test plan reference: RP3"""

    TEST_PIN = {
        "cat_id": 1,
        "pin_title": "Test Pin for Getting Reports",
        "pin_description": "Test Pin for getting reports",
        "pin_latitude": 50.7891,
        "pin_longitude": -1.0889,
        "pin_expire_at": "2026-05-30 20:00:00",
    }

    def _create_test_pin(self, client, auth_headers):
        response = client.post("/pins", headers=auth_headers, data=self.TEST_PIN)
        assert response.status_code == 201
        return response.json()["pin_id"]

    def test_get_reports_multiple_users_200(self, client, auth_headers, alt_auth_headers, db_session):
        """Get reports for a pin that has been reported by multiple users"""
        from models.user import User
        pin_id = self._create_test_pin(client, auth_headers)

        fresh_user = User(user_fname="Fresh", user_lname="User", user_email="fresh2@test.com", user_token="freshtoken888")
        db_session.add(fresh_user)
        db_session.flush()
        fresh_headers = {"Authorization": f"Bearer {fresh_user.user_token}"}

        client.post(f"/pins/{pin_id}/report", headers=alt_auth_headers, json={"report_type": "spam"})
        client.post(f"/pins/{pin_id}/report", headers=fresh_headers, json={"report_type": "inaccurate"})

        response = client.get(f"/pins/{pin_id}/reports", headers=auth_headers)
        assert response.status_code == 200
        assert len(response.json()) == 2

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_get_reports_no_reports_200(self, client, auth_headers):
        """Get reports for a pin with no reports returns empty list"""
        pin_id = self._create_test_pin(client, auth_headers)

        response = client.get(f"/pins/{pin_id}/reports", headers=auth_headers)
        assert response.status_code == 200
        assert response.json() == []

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_get_reports_nonexistent_pin_404(self, client, auth_headers):
        """Get reports for a pin that does not exist returns 404"""
        response = client.get("/pins/999999/reports", headers=auth_headers)
        assert response.status_code == 404

    def test_get_reports_without_auth_401(self, client):
        """Get reports without being logged in returns 401"""
        response = client.get("/pins/1/reports")
        assert response.status_code == 401

    def test_get_reports_non_integer_pin_id_422(self, client, auth_headers):
        """Get reports with a non-integer pin id returns 422"""
        response = client.get("/pins/invalid/reports", headers=auth_headers)
        assert response.status_code == 422