import pytest

from models.invitation_code import InvitationCode

class TestUserInvitationUI1:
    """Test plan reference: UI1"""

    @pytest.fixture(autouse=True)
    def clean_codes(self, db_session, main_user):
        db_session.delete(InvitationCode).filter(InvitationCode)

    def test_create_non_empty_code_201(self, client, auth_headers):
        """Create a non-empty code, expect 201"""

        rp = client.post("/invitation-codes", headers=auth_headers)
        assert rp.status_code == 201

        data = rp.json()
        assert data is not None
        assert "code" in data
        assert len(data["code"]) > 0
