"""
Pydantic schema for User for response and request validation
"""

from pydantic import BaseModel, EmailStr, Field, ConfigDict
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    """Base schema"""
    user_email: EmailStr
    user_fname: str = Field(..., min_length=1, max_length=60)
    user_lname: str = Field(..., min_length=1, max_length=60)
    user_displayname: Optional[str] = Field(None, max_length=30)

class UserCreate(UserBase):
    pass


class UserUpdateDisplayName(BaseModel):
    user_display_name : str = Field(..., max_length=30)

class UserResponse(UserBase):
    """Schema for user response"""
    user_id: int
    user_fname: str
    user_lname: str
    user_email: str
    user_displayname: Optional[str] = None
    user_isactive: bool
    last_login: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class UserLoginResponse(BaseModel):
    token: str
    user_id: int
    user_fname: str
    user_lname: str
    user_email: EmailStr
    user_displayname: Optional[str] = None
    user_isactive: bool
    last_login: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
