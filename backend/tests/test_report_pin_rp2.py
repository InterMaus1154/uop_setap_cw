import pytest

class TestReportPin:

    TEST_PIN = {
        "cat_id": 1,
        "pin_title": "Test Pin for Reporting",
        "pin_description": "Test Pin for reporting",
        "pin_latitude": 50.7891,
        "pin_longitude": -1.0889,
        "pin_expire_at": "2026-05-30 20:00:00",
    }

    def _create_test_pin(self, client, auth_headers):
        response = client.post("/pins", headers = auth_headers, data=self.TEST_PIN)
        assert response.status_code == 201
        return response.json()["pin_id"]
    
    def test_report_valid_pin_201(self, client, auth_headers, alt_auth_headers):
        """Logged in user can report an existing pin"""
        pin_id = self._create_test_pin(client, auth_headers)

        response = client.post(f"/pins/{pin_id}/report", headers=alt_auth_headers, json={"report_type": "spam"})
        assert response.status_code == 201

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_report_same_pin_twice_400(self, client, auth_headers, alt_auth_headers):
        """A user can't report same pin more than once"""
        pin_id = self._create_test_pin(client, auth_headers)

        client.post(f"/pins/{pin_id}/report", headers=alt_auth_headers, json={"report_type": "spam"})
        response = client.post(f"/pins/{pin_id}/report", headers=alt_auth_headers, json={"report_type": "spam"})
        assert response.status_code == 400

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_report_nonexistent_pin_404(self, client, auth_headers):
        """Can't report nonexistent pin"""
        response = client.post("/pins/999999/report", headers=auth_headers, json={"report_type": "spam"})
        assert response.status_code == 404

    def test_report_invalid_reason_422(self, client, auth_headers):
        """Report type must be a valid option"""
        pin_id = self._create_test_pin(client, auth_headers)

        response = client.post(f"/pins/{pin_id}/report", headers=auth_headers, json={"report_type": "invalid"})
        assert response.status_code == 422

        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_report_missing_reason_422(self, client, auth_headers):
        """Report type is required"""
        pin_id = self._create_test_pin(client, auth_headers)
    
        response = client.post(f"/pins/{pin_id}/report", headers=auth_headers, json={})
        assert response.status_code == 422
        
        client.delete(f"/pins/{pin_id}", headers=auth_headers)

    def test_report_without_auth_401(self, client):
        """Can't report a pin without logging in"""
        response = client.post("/pins/1/report", json={"report_type": "spam"})
        assert response.status_code == 401