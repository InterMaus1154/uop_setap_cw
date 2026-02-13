from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional


class PinCreate(BaseModel):
    """Schema for creating a new pin"""
    pin_title: str = Field(..., max_length=30)
    pin_latitude: float
    pin_longitude: float
    user_id: int
    cat_id: int
    sub_cat_id: Optional[int] = None  
    pin_expire_at: datetime
    pin_description: Optional[str] = Field(None, max_length=300)

class PinResponse(BaseModel):
    """Schema for pin response"""
    pin_id: int
    cat_id: int
    sub_cat_id: Optional[int] = None
    user_id: int
    pin_title: str 
    pin_description: Optional[str] 
    pin_picture_path: Optional[str] = None
    pin_latitude: float
    pin_longitude: float
    pin_isactive: bool
    pin_expire_at: datetime
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class PinUpdate(BaseModel):
    """schema for updating pin details"""
    pin_title: Optional[str] = Field(None, max_length=30)
    pin_description: Optional[str] = Field(None, max_length=300)
    pin_latitude: Optional[float] = None
    pin_longitude: Optional[float] = None
    cat_id: Optional[int] = None
    sub_cat_id: Optional[int] = None
    pin_expire_at: Optional[datetime] = None