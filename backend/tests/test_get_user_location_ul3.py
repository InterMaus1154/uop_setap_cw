import pytest

from unittest.mock import patch, MagicMock


class TestGetUserLocation:
    """Test reference in test plan: UL3"""

    TEST_COORDINATES = {"latitude": 50.801412, "longitude": -1.088995}

    @pytest.fixture(autouse=True)
    def mock_externals(self):
        """Mock redis and geocoding for tests"""
        with patch("routes.user_locations._reverse_geocode",
                   return_value={"city": "Portsmouth", "street": "Commercial Road"}), \
                patch("routes.user_locations.redis_client") as mock_redis:
            mock_redis.hgetall.return_value = {}
            yield mock_redis

    def test_get_user_location_if_exists_expect_200(self, client, auth_headers):
        """Get user location if exists, status 200 expected"""

        rp = client.post("/user-locations", json=self.TEST_COORDINATES, headers=auth_headers)
        assert rp.status_code == 201
        rg = client.get("/user-locations", headers=auth_headers)
        assert rg.status_code == 200

    def test_get_user_location_correct_data_returned(self, client, auth_headers):
        """Get user location that returns correct data"""
        rp = client.post("/user-locations", json=self.TEST_COORDINATES, headers=auth_headers)
        assert rp.status_code == 201
        rg = client.get("/user-locations", headers=auth_headers)
        assert rg.status_code == 200
        data = rp.json()
        assert data is not None
        assert "latitude" in data
        assert "longitude" in data
        assert data["latitude"] == self.TEST_COORDINATES["latitude"]
        assert data["longitude"] == self.TEST_COORDINATES["longitude"]
        assert data["is_enabled"] == True

    def test_get_user_location_invalid_auth_expect_401(self, client):
        """Get a user location with no or invalid auth headers"""
        rg1 = client.get("/user-locations")
        assert rg1.status_code == 401
        rg2 = client.get("/user-locations", headers={"Authorization": "Bearer invalidttoken"})
        assert rg2.status_code == 401

    def test_get_user_location_when_one_doesnt_exist_expect_404(self, client, auth_headers):
        """Get a user location when one doesnt exist, expect 404"""
        rg2 = client.get("/user-locations", headers=auth_headers)
        assert rg2.status_code == 404