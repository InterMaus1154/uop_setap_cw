"""
Pydantic schema for LocationPermission for response and request validation
"""

from pydantic import BaseModel
from datetime import datetime


class CreateLocationPermission(BaseModel):
    """Schema for creating a location permission"""
    user_id: int


class LocationPermissionResponse(BaseModel):
    """Schema for location permission response"""
    loc_perm_id: int
    user_loc_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
