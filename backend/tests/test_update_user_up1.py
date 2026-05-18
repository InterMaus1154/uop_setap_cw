
class TestUpdateUser:
    """Test plan reference: UP1"""

    TEST_UPDATE_DATA = {
        "user_fname": "Test First Name Update",
        "user_lname": "Test Last Name Update",
        "user_display_name": "Test Update Display Name",
        "user_use_displayname": True
    }

    def test_get_user_profile_200(self, client, auth_headers, main_user):
        """Get user profile"""

        rg = client.get("/users/me", headers=auth_headers)
        assert rg.status_code == 200
        data = rg.json()
        assert data["user_email"] == main_user.user_email

    def test_get_user_profile_no_auth_401(self, client):
        """Get user profile without auth"""
        rg = client.get("/users/me")
        assert rg.status_code == 401

    def test_update_user_names(self, client, auth_headers):
        """Update user's first and last name"""

        rp = client.put("/users", headers=auth_headers, json=self.TEST_UPDATE_DATA)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["user_fname"] == self.TEST_UPDATE_DATA["user_fname"]
        assert data["user_lname"] == self.TEST_UPDATE_DATA["user_lname"]
        assert data["user_displayname"] == self.TEST_UPDATE_DATA["user_display_name"]
        assert data["user_use_displayname"] == self.TEST_UPDATE_DATA["user_use_displayname"]

    def test_update_user_profile_invalid_last_name_422(self, client, auth_headers):
        """Try to update user profile with invalid data"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["user_lname"] = "A"*200

        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 422


    def test_update_user_name_preference_shown_in_pin(self, client, auth_headers):
        """Update user's display name preference, and create a pin owned by user and see if author is the correct name"""

        rp = client.put("/users", headers=auth_headers, json=self.TEST_UPDATE_DATA)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None

        PIN_DATA = {
            "pin_title": "Test Pin",
            "pin_latitude": 58.1,
            "pin_longitude": -1.08,
            "cat_id": 1,
            "pin_expire_at": "2026-05-20"
        }

        rp = client.post("/pins", headers=auth_headers, data=PIN_DATA)
        assert rp.status_code == 201

        pd = rp.json()
        assert pd is not None
        assert pd["pin_author_name"] == data["user_displayname"]

    def test_update_user_turn_on_dark_mode_200(self, client, auth_headers):
        """Turn on dark mode"""
        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = True
        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200
        data = rp.json()
        assert data is not None
        assert data["dark_mode"] is True

    def test_update_user_turn_off_dark_mode_200(self, client, auth_headers):
        """Turn off dark mode"""
        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = False
        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200
        data = rp.json()
        assert data is not None
        assert data["dark_mode"] is False


