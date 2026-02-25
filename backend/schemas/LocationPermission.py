from pydantic import BaseModel, ConfigDict
from datetime import datetime


class LocationPermissionBase(BaseModel):
    user_loc_id: int
    user_id: int

    model_config = ConfigDict(from_attributes=True)


class CreateLocationPermission(LocationPermissionBase):
    model_config = ConfigDict(from_attributes=True)


class LocationPermissionResponse(LocationPermissionBase):
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
