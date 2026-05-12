

class TestDeactivateUser:
    """Test plan reference: UP2"""

    def test_deactivate_user_200(self, client, auth_headers):
        """Deactivate user profile"""

        rp = client.patch("/users/deactivate", headers=auth_headers)
        assert rp.status_code == 200

    def test_deactivate_user_attempt_login_403(self, client, auth_headers, main_user):
        """Deactivate user and attempt to login"""

        rp = client.patch("/users/deactivate", headers=auth_headers)
        assert rp.status_code == 200

        rlog = client.post("/auth/login", json={"email": main_user.user_email})
        assert rlog.status_code == 403

    def test_deactivate_user_without_auth_401(self, client, auth_headers):
        """Deactivate user with invalid auth"""

        rp = client.patch("/users/deactivate")
        assert rp.status_code == 401