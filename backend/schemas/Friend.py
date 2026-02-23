from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Literal


class FriendBase(BaseModel):
    """Base schema for friend request payloads."""
    target_user_id: int


class FriendCreate(FriendBase):
    """Payload to create a friend request."""
    pass


class FriendUpdate(BaseModel):
    """Payload for updating a relationship status."""
    response: Literal["accepted", "rejected", "blocked"]


class FriendResponse(BaseModel):
    """Response schema for a user relationship."""
    user_rel_id: int
    user_id: int
    target_user_id: int
    user_rel_status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
