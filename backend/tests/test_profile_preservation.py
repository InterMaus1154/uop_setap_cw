"""
Preservation property tests for profile-related behaviours.

These tests MUST PASS on unfixed code — they capture baseline behavior
that must remain unchanged after the bug fix is applied.
"""
import pytest
from hypothesis import given, settings, HealthCheck
from hypothesis.strategies import text

from base import client


class TestProfilePreservation:
    """
    Property 2: Preservation — Non-Save Profile Behaviours Unchanged

    These tests observe and lock-in the current (correct) behaviour of
    read-only endpoints and valid profile updates so that the bug fix
    does not introduce regressions.
    """

    @pytest.fixture(autouse=True)
    def setup(self, auth_headers):
        """Store auth headers for all tests."""
        self.headers = auth_headers

    # --- Requirement 3.5: GET /users/me returns correct profile data ---
    def test_get_me_returns_profile_data(self, auth_headers):
        """
        GET /users/me returns the authenticated user's profile with all
        expected fields: first name, last name, email, display name.

        """
        response = client.get("/users/me", headers=auth_headers)
        assert response.status_code == 200

        data = response.json()
        assert "user_fname" in data
        assert "user_lname" in data
        assert "user_email" in data
        assert "user_displayname" in data
        assert "user_use_displayname" in data
        # Values should be non-null strings for required fields
        assert isinstance(data["user_fname"], str)
        assert isinstance(data["user_lname"], str)
        assert isinstance(data["user_email"], str)

    # ---  GET /users/me/pin-count returns correct count ---
    def test_get_pin_count_returns_count(self, auth_headers):
        """
        GET /users/me/pin-count returns a JSON object with a pin_count field.

        **Validates: Requirement 3.4**
        """
        response = client.get("/users/me/pin-count", headers=auth_headers)
        assert response.status_code == 200

        data = response.json()
        assert "pin_count" in data
        assert isinstance(data["pin_count"], int)
        assert data["pin_count"] >= 0

    # --- PUT /users/ with non-empty fname/lname persists ---
    def test_put_users_with_valid_names_persists(self, auth_headers):
        """
        PUT /users/ with non-empty first name and last name persists the
        values and returns the updated user.

        **Validates: Requirement 3.6**
        """
        response = client.put(
            "/users/",
            json={"user_fname": "PreserveFirst", "user_lname": "PreserveLast"},
            headers=auth_headers,
        )
        assert response.status_code == 200

        data = response.json()
        assert data["user_fname"] == "PreserveFirst"
        assert data["user_lname"] == "PreserveLast"

        # Verify via GET /users/me
        me_response = client.get("/users/me", headers=auth_headers)
        me_data = me_response.json()
        assert me_data["user_fname"] == "PreserveFirst"
        assert me_data["user_lname"] == "PreserveLast"

    # --- Property-based round-trip test ---
    @given(
        fname=text(min_size=1, max_size=60),
        lname=text(min_size=1, max_size=60),
    )
    @settings(max_examples=5, deadline=5000, suppress_health_check=[HealthCheck.function_scoped_fixture])
    def test_put_then_get_roundtrip_preserves_names(self, fname, lname, auth_headers):
        """
        Property-based test: for all valid non-empty first name and last name
        strings, PUT /users/ persists the values and GET /users/me returns
        them unchanged.

        """
        put_response = client.put(
            "/users/",
            json={"user_fname": fname, "user_lname": lname},
            headers=auth_headers,
        )
        assert put_response.status_code == 200

        put_data = put_response.json()
        assert put_data["user_fname"] == fname
        assert put_data["user_lname"] == lname

        me_response = client.get("/users/me", headers=auth_headers)
        assert me_response.status_code == 200

        me_data = me_response.json()
        assert me_data["user_fname"] == fname
        assert me_data["user_lname"] == lname
