import pytest

from unittest.mock import patch
from models.user import User
from models.user_relationship import UserRelationship, UserRelationshipType
from models.location_permission import LocationPermission

class TestLocationPermissions:
    @pytest.fixture(autouse=True)
    def mock_externals(self):
        with patch(
            "routes.user_locations._reverse_geocode",
            return_value={"city": "Portsmouth", "street": "Commercial Road"},
        ), patch("routes.user_locations.redis_client") as mock_redis:
            mock_redis.hgetall.return_value = {}
            yield mock_redis
    def _create_friend(self, db_session, main_user):
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

     return friend


    def _create_user_location(self, client, auth_headers):
        response = client.post(
            "/user-locations/",
            json={"latitude": 50.801412, "longitude": -1.088995},
            headers=auth_headers,
        )
        assert response.status_code == 201
        return response

    def test_location_permissions(self, client, auth_headers):
        self._create_user_location(client, auth_headers)
        response = client.get("/location-permissions/", headers=auth_headers)
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    def test_location_permissions_invalid_auth(self, client):
        response = client.get("/location-permissions/")
        assert response.status_code == 401

        response = client.get(
            "/location-permissions/",
            headers={"Authorization": "Bearer invalid_token"},
        )
        assert response.status_code == 401

    def test_post_location_permissions(self, db_session, client, auth_headers, main_user):
        friend = self._create_friend(db_session, main_user)
        self._create_user_location(client, auth_headers)

        response = client.post(
            "/location-permissions/",
            json={"user_id": friend.user_id},
            headers=auth_headers,
        )
        assert response.status_code == 201

        data = response.json()
        assert data["user_id"] == friend.user_id
        assert "loc_perm_id" in data
        assert "user_loc_id" in data
        assert "created_at" in data
        assert "updated_at" in data

    def test_post_location_permissions_invalid_user(self, client, auth_headers):
        response = client.post(
            "/location-permissions/",
            json={"user_id": 999999},
            headers=auth_headers,
        )
        assert response.status_code == 404

        response = client.post(
            "/location-permissions/",
            json={"user_id": "invalid"},
            headers=auth_headers,
        )
        assert response.status_code == 422

    def test_delete_location_permissions(self, db_session, client, auth_headers, main_user):
        friend = self._create_friend(db_session, main_user)
        self._create_user_location(client, auth_headers)

        create_response = client.post(
            "/location-permissions/",
            json={"user_id": friend.user_id},
            headers=auth_headers,
        )
        assert create_response.status_code == 201
        permission_id = create_response.json()["loc_perm_id"]

        delete_response = client.delete(
            f"/location-permissions/{friend.user_id}",
            headers=auth_headers,
        )
        assert delete_response.status_code == 204

        permission = db_session.query(LocationPermission).filter_by(loc_perm_id=permission_id).first()
        assert permission is None
