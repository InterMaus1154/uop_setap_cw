"""
Pydantic schema for UserLocation for response and request validation
"""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class CreateUserLocation(BaseModel):
    """Schema for creating a user location"""
    latitude: float
    longitude: float


class UpdateUserLocation(BaseModel):
    """Schema for updating a user location"""
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_enabled: Optional[bool] = None


class UserLocationResponse(BaseModel):
    """Schema for user location response"""
    user_loc_id: int
    user_id: int
    latitude: float
    longitude: float
    is_enabled: bool
    created_at: datetime
    updated_at: datetime
    city: Optional[str] = None
    street: Optional[str] = None

    model_config = {"from_attributes": True}
