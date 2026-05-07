import pytest

from unittest.mock import patch, MagicMock


class TestCreateUserLocation:
    """Test reference in the plan: ULT1"""

    TEST_COORDINATES = {"latitude": 50.801412, "longitude": -1.088995}

    @pytest.fixture(autouse=True)
    def mock_externals(self):
        """Mock redis and geocoding for tests"""
        with patch("routes.user_locations._reverse_geocode",
                   return_value={"city": "Portsmouth", "street": "Commercial Road"}), \
                patch("routes.user_locations.redis_client") as mock_redis:
            mock_redis.hgetall.return_value = {}
            yield mock_redis

    def test_create_location_returns_201(self, client, auth_headers):
        """Basic test: check if user location has been created (201)"""
        response = client.post("/user-locations/", json=self.TEST_COORDINATES, headers=auth_headers)
        assert response.status_code == 201

    def test_create_location_enabled_by_default(self, client, auth_headers):
        """User location should be enabled by default"""
        response = client.post("/user-locations/", json=self.TEST_COORDINATES, headers=auth_headers)
        assert response.status_code == 201
        data = response.json()
        assert data is not None
        assert data["is_enabled"] == True

    def test_create_location_has_the_given_coordinates(self, client, auth_headers):
        """Should have the given longitude and latitude coordinates"""
        response = client.post("/user-locations/", json=self.TEST_COORDINATES, headers=auth_headers)
        assert response.status_code == 201
        data = response.json()
        assert data is not None
        assert data["latitude"] == self.TEST_COORDINATES["latitude"]
        assert data["longitude"] == self.TEST_COORDINATES["longitude"]

    def test_create_location_without_authentication_headers_expect_401(self, client):
        """No authentication headers, expect 401"""
        response = client.post("/user-locations", json=self.TEST_COORDINATES)
        assert response.status_code == 401

    def test_create_location_with_valid_token_expect_401(self, client):
        """Token passed, but invalid"""
        response = client.post("/user-locations", json=self.TEST_COORDINATES, headers={"Authorization": "Bearer invalid"})
        assert response.status_code == 401

    def test_post_updates_existing_location_with_new(self, client, auth_headers):
        """Post request should update existing location if exists"""
        client.post("/user-locations", json=self.TEST_COORDINATES, headers=auth_headers)
        response = client.post("/user-locations", json={"latitude": 52.0, "longitude": -1.1}, headers=auth_headers)
        data = response.json()
        assert data is not None
        assert data["latitude"] == 52.0
        assert data["longitude"] == -1.1

    def test_create_user_location_without_data(self, client, auth_headers):
        """Do not pass in any data"""
        response = client.post("/user-locations", headers=auth_headers)
        assert response.status_code == 422

    def test_patch_location_returns_200(self, client, auth_headers):
        """Update should return 200"""
        client.post("/user-locations", json=self.TEST_COORDINATES, headers=auth_headers)
        response = client.patch("/user-locations", json={"latitude": 52.0}, headers=auth_headers)
        assert response.status_code == 200

    def test_patch_location_update_latitude_only(self, client, auth_headers):
        """Should update latitude only, without touching longitude"""
        client.post("/user-locations", json=self.TEST_COORDINATES, headers=auth_headers)
        response = client.patch("/user-locations", json={"latitude": 52.0}, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data is not None
        assert data["latitude"] == 52.0
        assert data["longitude"] == self.TEST_COORDINATES["longitude"]



