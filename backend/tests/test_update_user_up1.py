
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
    
    def test_dark_mode_preference(self, client, auth_headers):
        """Update user's dark mode preference and see if it is updated in the response"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = True

        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True
    
    def test_dark_mode_preference_invalid_value(self, client, auth_headers):
        """Try to update user's dark mode preference with invalid value"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = "not_a_boolean"

        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 422
    
    def test_default_dark_mode_preference(self, client, auth_headers):
        """Create a new user without specifying dark mode preference and see if it defaults to false"""

        USER_DATA = {
            "user_email": "test@example.com",
            "user_fname": "Test",
            "user_lname": "User",
            "user_use_displayname": False
        }

        rp = client.post("/users", json=USER_DATA)
        assert rp.status_code == 201

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == False
    
    def test_persist_dark_mode_preference(self, client, auth_headers):
        """Update user's dark mode preference to true, then update it again without specifying dark mode and see if it persists"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = True

        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True

        # Update again without specifying dark mode
        payload.pop("dark_mode")
        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True
    
    def test_create_user_dark_mode_preference(self, client):
        """Create a new user with dark mode preference set to true and see if it is set correctly"""

        USER_DATA = {
            "user_email": "test@example.com",
            "user_fname": "Test",
            "user_lname": "User",
            "user_use_displayname": False,
            "dark_mode": True
        }

        rp = client.post("/users", json=USER_DATA)
        assert rp.status_code == 201

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True
    
    def test_create_user_dark_mode_preference_invalid_value(self, client):
        """Try to create a new user with dark mode preference set to invalid value"""

        USER_DATA = {
            "user_email": "test@example.com",
            "user_fname": "Test",
            "user_lname": "User",
            "user_use_displayname": False,
            "dark_mode": "not_a_boolean"
        }

        rp = client.post("/users", json=USER_DATA)
        assert rp.status_code == 422
    
    def test_dark_mode_login_response(self, client, auth_headers):
        """Update user's dark mode preference to true, then login again and see if dark mode is included in the login response"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["user_use_displayname"] = False
        payload["dark_mode"] = True

        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200

        # Login again
        LOGIN_DATA = {
            "email": "test@test.app",
        }
        rp = client.post("/auth/login", json=LOGIN_DATA)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True
    
    def test_dark_mode_idompotence(self, client, auth_headers):
        """Update user's dark mode preference to true, then update it again to true and see if it remains true"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = True

        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True

        # Update again to true
        rp = client.put("/users", headers=auth_headers, json=payload)
        assert rp.status_code == 200

        data = rp.json()
        assert data is not None
        assert data["dark_mode"] == True
    
    def test_dark_mode_concurrent_updates(self, client, auth_headers):
        """Simulate concurrent updates to user's dark mode preference and see if the final value is consistent"""

        payload = self.TEST_UPDATE_DATA.copy()
        payload["dark_mode"] = True

        # Simulate two concurrent updates
        rp1 = client.put("/users", headers=auth_headers, json=payload)
        rp2 = client.put("/users", headers=auth_headers, json=payload)

        assert rp1.status_code == 200
        assert rp2.status_code == 200

        data1 = rp1.json()
        data2 = rp2.json()

        assert data1 is not None
        assert data2 is not None
        assert data1["dark_mode"] == True
        assert data2["dark_mode"] == True
    
    

