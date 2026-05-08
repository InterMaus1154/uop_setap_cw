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
    user_use_displayname: bool 


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    user_display_name: Optional[str] = Field(None, max_length=30)
    user_fname: Optional[str] = Field(None, max_length=60)
    user_lname: Optional[str] = Field(None, max_length=60)
    user_use_displayname: Optional[bool] = None


class UserResponse(UserBase):
    """Schema for user response"""
    user_id: int
    user_fname: str
    user_lname: str
    user_email: str
    user_displayname: Optional[str] = None
    user_use_displayname: bool 
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
    user_use_displayname: bool
    user_isactive: bool
    last_login: Optional[datetime] = None
    created_at: datetime
    expires_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
