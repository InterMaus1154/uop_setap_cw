from pydantic import BaseModel, Field, ConfigDict, computed_field
from datetime import datetime
from typing import Optional, Literal


class PinCreate(BaseModel):
    """Schema for creating a new pin"""
    pin_title: str = Field(..., max_length=100)
    pin_latitude: float
    pin_longitude: float
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
    pin_color: str
    pin_author_name: str
    pin_likes: int
    pin_dislikes: int
    user_reaction: Literal[1, -1] | None = None

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


class PinReactionRequest(BaseModel):
    """Schema for pin reaction request, with a single field for the value"""
    value: Literal[1, -1]
