import pytest

from unittest.mock import patch, MagicMock


class TestDeleteUserLocation:
    """Test reference in the plan: UL2"""

    TEST_COORDINATES = {"latitude": 50.801412, "longitude": -1.088995}

    @pytest.fixture(autouse=True)
    def mock_externals(self):
        """Mock redis and geocoding for tests"""
        with patch("routes.user_locations._reverse_geocode",
                   return_value={"city": "Portsmouth", "street": "Commercial Road"}), \
                patch("routes.user_locations.redis_client") as mock_redis:
            mock_redis.hgetall.return_value = {}
            yield mock_redis

    def test_delete_user_location_expect_204(self, client, auth_headers):
        """Delete an existing user location, expect 204"""
        rp = client.post("/user-locations/", json=self.TEST_COORDINATES, headers=auth_headers)
        assert rp.status_code == 201
        rd = client.delete("/user-locations", headers=auth_headers)
        assert rd.status_code == 204
        rg = client.get("/user-locations", headers=auth_headers)
        assert rg.status_code == 404

    def test_delete_user_location_invalid_auth_expect_401(self, client):
        """Delete a user location with no or invalid auth headers"""
        rd1 = client.delete("/user-locations")
        assert rd1.status_code == 401
        rd2 = client.delete("/user-locations", headers={"Authorization": "Bearer invalidttoken"})
        assert rd2.status_code == 401

    def test_delete_user_location_when_one_doesnt_exist_expect_404(self, client, auth_headers):
        """Delete a user location when one doesnt exist, expect 404"""
        rp = client.post("/user-locations/", json=self.TEST_COORDINATES, headers=auth_headers)
        assert rp.status_code == 201
        rd1 = client.delete("/user-locations", headers=auth_headers)
        assert rd1.status_code == 204
        rd2 = client.delete("/user-locations", headers=auth_headers)
        assert rd2.status_code == 404
