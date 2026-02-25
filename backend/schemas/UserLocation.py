from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional


class UserLocationBase(BaseModel):
    user_id: int
    latitude: float
    longitude: float
    is_enabled: bool

    model_config = ConfigDict(from_attributes=True)


class CreateUserLocation(BaseModel):
    """Create schema for a user location creation."""
    # user_id is passed from the authenticated user, not from a request payload
    latitude: float
    longitude: float
    is_enabled: bool

    model_config = ConfigDict(from_attributes=True)


class UpdateUserLocation(BaseModel):
    """Update schema for UserLocation. All fields are optional"""
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_enabled: Optional[bool] = None

    model_config = ConfigDict(from_attributes=True)


class UserLocationResponse(UserLocationBase):
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
