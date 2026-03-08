"""
Bug condition exploration tests for profile update.

"""
import pytest
from base import client


class TestProfileUpdateBugConditions:
    """
    Property 1: Fault Condition — Profile Save Fails Due to API Mismatches

    Each test targets a specific bug in the profile save flow.
    On unfixed code these tests MUST FAIL, proving the bug exists.
    """

    @pytest.fixture(autouse=True)
    def setup(self, auth_headers):
        """Store auth headers for all tests."""
        self.headers = auth_headers

    # --- Bug: Correct endpoint PUT /users/ works ---
    def test_put_users_updates_profile(self, auth_headers):
        """
        The fix changes the frontend from PATCH /users/me to PUT /users/.
        Verify PUT /users/ correctly persists profile changes.

        **Validates: Requirement 1.1 (fix verification)**
        """
        response = client.put(
            "/users/",
            json={
                "user_fname": "Joshua",
                "user_lname": "Smith",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200

        me_response = client.get("/users/me", headers=auth_headers)
        user_data = me_response.json()
        assert user_data["user_fname"] == "Joshua"
        assert user_data["user_lname"] == "Smith"

    # --- Bug: Correct field name user_display_name works ---
    def test_put_users_with_correct_displayname_field_persists(self, auth_headers):
        """
        The fix changes the frontend from 'user_displayname' to 'user_display_name'.
        Verify the correct field name persists the display name.

        **Validates: Requirement 1.2 (fix verification)**
        """
        response = client.put(
            "/users/",
            json={"user_display_name": "NewDisplayName"},
            headers=auth_headers,
        )
        assert response.status_code == 200

        me_response = client.get("/users/me", headers=auth_headers)
        user_data = me_response.json()
        assert user_data["user_displayname"] == "NewDisplayName", (
            f"Display name is '{user_data['user_displayname']}' instead of 'NewDisplayName'. "
            "user_display_name field should persist correctly."
        )

    # --- Bug: Missing user_use_displayname in UserUpdate schema ---
    def test_put_users_with_use_displayname_field_is_stripped(self, auth_headers):
        """
        The UserUpdate schema does not include user_use_displayname, so Pydantic
        strips it from the payload. The preference cannot be persisted.

        **Validates: Requirement 1.3**
        """
        # Send user_use_displayname in the update payload
        response = client.put(
            "/users/",
            json={"user_use_displayname": True},
            headers=auth_headers,
        )
        assert response.status_code == 200

        # Check if the preference was persisted
        me_response = client.get("/users/me", headers=auth_headers)
        user_data = me_response.json()

        # The correct behaviour: user_use_displayname should be True.
        assert user_data["user_use_displayname"] is True, (
            f"user_use_displayname is {user_data['user_use_displayname']}. "
            "Bug confirmed: UserUpdate schema lacks user_use_displayname field, "
            "so the value is stripped by Pydantic."
        )

    # --- Bug: Truthy check skips empty string ---
    def test_put_users_with_empty_fname_is_silently_skipped(self, auth_headers):
        """
        The backend uses `if user_data.user_fname:` which treats empty string as
        falsy, silently skipping the update instead of applying it.

        """
        # First set a known first name
        client.put(
            "/users/",
            json={"user_fname": "OriginalFirst"},
            headers=auth_headers,
        )

        # Now try to set first name to empty string
        response = client.put(
            "/users/",
            json={"user_fname": ""},
            headers=auth_headers,
        )

        # Check what happened
        me_response = client.get("/users/me", headers=auth_headers)
        user_data = me_response.json()

        # The correct behaviour: empty string should either be applied or rejected
        # with a validation error. It should NOT silently keep the old value.
        # On unfixed code: truthy check skips the update, fname stays "OriginalFirst".
        assert user_data["user_fname"] != "OriginalFirst", (
            f"user_fname is still '{user_data['user_fname']}'. "
            "Bug confirmed: empty string is silently skipped due to "
            "`if user_data.user_fname:` truthy check."
        )
