from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional


class InvitationCodeResponse(BaseModel):
    id: int
    creator_id: int
    code: str
    guest_user_id: Optional[int] = None
    created_at: datetime
    expires_at: datetime
    is_used: bool

    model_config = ConfigDict(from_attributes=True)


class LoginWithCodeRequest(BaseModel):
    code: str