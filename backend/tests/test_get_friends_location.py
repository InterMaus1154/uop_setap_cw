import pytest

from unittest.mock import patch, MagicMock

from models import UserLocation
from models.user import User
from models.user_relationship import UserRelationship, UserRelationshipType
from models.location_permission import LocationPermission


class TestGetFriendsLocation:
    """Test reference in plan: UL4"""

    TEST_COORDINATES = {"latitude": 50.801412, "longitude": -1.088995}

    @pytest.fixture(autouse=True)
    def mock_externals(self):
        """Mock redis and geocoding for tests"""
        with patch("routes.user_locations._reverse_geocode",
                   return_value={"city": "Portsmouth", "street": "Commercial Road"}), \
                patch("routes.user_locations.redis_client") as mock_redis:
            mock_redis.hgetall.return_value = {}
            yield mock_redis

    @pytest.fixture
    def friend_with_location(self, db_session, main_user):
        # create a friend user to test with
        friend = User(
            user_fname="Friend",
            user_lname="User",
            user_email="friend@test.com",
            user_token="friendttoken123"
        )
        db_session.add(friend)
        db_session.flush()

        # create an accepted relationship (make them friends)
        relationship = UserRelationship(
            user_id=main_user.user_id,
            target_user_id=friend.user_id,
            user_rel_status=UserRelationshipType.ACCEPTED
        )

        db_session.add(relationship)
        db_session.flush()

        # create a location for the created friend
        location = UserLocation(
            user_id=friend.user_id,
            latitude=self.TEST_COORDINATES["latitude"],
            longitude=self.TEST_COORDINATES["longitude"],
            is_enabled=True
        )

        db_session.add(location)
        db_session.flush()

        # give permission for the main user
        permission = LocationPermission(
            user_loc_id=location.user_loc_id,
            user_id=main_user.user_id
        )

        db_session.add(permission)
        db_session.flush()

        return friend, location

    def test_get_friends_location_expect_200(self, client, auth_headers):
        """Get friends location, expect 200"""
        rg = client.get("/user-locations/friends", headers=auth_headers)
        assert rg.status_code == 200

    def test_get_friends_location_has_friend_200(self, client, auth_headers, friend_with_location):
        """Get friends location, expect 200 and array has the friend's location"""
        friend, location = friend_with_location
        rg = client.get("/user-locations/friends", headers=auth_headers)

        assert rg.status_code == 200
        data = rg.json()
        assert data is not None

        # find friend location
        in_array = False
        for loc in data:
            if loc["user_id"] == friend.user_id:
                in_array = True
                break
        assert in_array == True

    def test_get_friends_location_has_correct_coordinates_200(self, client, auth_headers, friend_with_location):
        """Get friends location, expect 200 and array has the friend's location with correct coordinates"""
        friend, location = friend_with_location
        rg = client.get("/user-locations/friends", headers=auth_headers)

        assert rg.status_code == 200
        data = rg.json()
        assert data is not None

        # find friend location
        friend_loc = None
        for loc in data:
            if loc["user_id"] == friend.user_id:
                friend_loc = loc
                break

        assert friend_loc is not None
        assert friend_loc["latitude"] == self.TEST_COORDINATES["latitude"]
        assert friend_loc["longitude"] == self.TEST_COORDINATES["longitude"]

    def test_get_friends_location_empty_array_200(self, client, auth_headers):
        """Get friends location if nobody is sharing with the user, should return empty array and no error"""
        rg = client.get("/user-locations/friends", headers=auth_headers)
        assert rg.status_code == 200
        data = rg.json()
        assert data is not None
        assert data == []

    def test_get_friends_location_with_invalid_auth_401(self, client, auth_headers):
        """Get friends location with invalid token or no token"""
        rg1 = client.get("/user-locations/friends")
        assert rg1.status_code == 401
        rg2 = client.get("/user-locations/friends", headers={"Authorization": "Bearer invallidtoken"})
        assert rg2.status_code == 401

