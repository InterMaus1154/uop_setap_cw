from models.user_relationship import UserRelationship


class TestAddFriend:
    """Test plan reference: AF1"""

    def test_friend_request_with_invalid_format(self, auth_headers, client):
        """Test sending friend request with invalid email format returns 422"""
        response = client.post("/friends/", headers=auth_headers, json={"target_user_id": "test@com"})
        assert response.status_code == 422

    def test_send_friend_request_to_existing_user(self, auth_headers, db_session, client):
        """Test sending a friend request to a valid existing user returns 201"""
        from models.user import User
        fresh_user = User(user_fname="Fresh", user_lname="User", user_email="fresh@test.com", user_token="freshtoken999")
        db_session.add(fresh_user)
        db_session.flush()

        response = client.post("/friends/", headers=auth_headers, json={"target_user_id": fresh_user.user_id})
        assert response.status_code == 201

        rel_id = response.json()["user_rel_id"]
        client.delete(f"/friends/{rel_id}", headers=auth_headers)


    def test_send_friend_request_to_nonexistent_user(self, auth_headers, client):
        """Test sending friend request to a nonexistent user returns 404"""
        response = client.post("/friends/", headers=auth_headers, json={"target_user_id": 999999})
        assert response.status_code == 404

    def test_send_friend_request_to_yourself(self, auth_headers, client):
        """Test sending friend request to yourself returns 422"""
        me = client.get("/users/me", headers=auth_headers).json()
        response = client.post("/friends/", headers=auth_headers, json={"target_user_id": me["user_id"]})
        assert response.status_code == 422

    def test_send_friend_request_without_auth(self, client):
        """Test sending a friend request without authentication (rejected)"""
        response = client.post("/friends/", json={"target_user_id": 1})
        assert response.status_code == 401