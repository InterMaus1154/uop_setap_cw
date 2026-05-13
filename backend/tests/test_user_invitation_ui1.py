import pytest

from models.invitation_code import InvitationCode


class TestUserInvitationUI1:
    """Test plan reference: UI1"""

    @pytest.fixture(autouse=True)
    def clean_codes(self, db_session, main_user):
        db_session.query(InvitationCode).filter(InvitationCode.creator_id == main_user.user_id).delete()
        db_session.flush()
        yield

    def test_create_non_empty_code_201(self, client, auth_headers):
        """Create a non-empty code, expect 201"""

        rp = client.post("/invitation-codes", headers=auth_headers)
        assert rp.status_code == 201

        data = rp.json()
        assert data is not None
        assert "code" in data
        assert len(data["code"]) > 0

    def test_create_code_has_creator_id_who_created_201(self, client, auth_headers, main_user):
        """The creator id should be the user who created it"""
        rp = client.post("/invitation-codes", headers=auth_headers)
        assert rp.status_code == 201

        data = rp.json()
        assert data is not None
        assert "creator_id" in data
        assert data["creator_id"] == main_user.user_id

    def test_created_code_unauthenticated_401(self, client):
        """Create code as unauthenticated user"""

        rp1 = client.post("/invitation-codes")
        assert rp1.status_code == 401

        rp2 = client.post("/invitation-codes", headers={"Authorization": "Bearer invalidtookensdgd"})
        assert rp2.status_code == 401

    def test_create_too_many_codes_by_user_429(self, client, auth_headers):
        """Create too many codes for the same user, should be 429"""

        last_code = None
        for i in range(10):
            last_code = client.post("/invitation-codes", headers=auth_headers).status_code

        assert last_code is not None
        assert last_code == 429

    def test_get_codes_created_by_user_200(self, client, auth_headers, main_user):
        """Create some codes, then check if it returns the codes"""

        for i in range(4):
            client.post("/invitation-codes", headers=auth_headers)

        rg = client.get("/invitation-codes", headers=auth_headers)
        assert rg.status_code == 200
        data = rg.json()
        assert data is not None
        assert len(data) > 0
        assert len(data) == 4
        invalid = 0  # track invalid ones
        for code in data:
            if code["creator_id"] == main_user.user_id and code["code"] is not None and len(code["code"]) > 0:
                continue
            else:
                invalid += 1

        assert invalid == 0
