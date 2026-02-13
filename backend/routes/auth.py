from fastapi import APIRouter, HTTPException
from fastapi.params import Depends
from sqlalchemy.orm import Session

from database.db import get_db
from schemas.Auth import LoginRequest

from models.user import User

import hashlib

from schemas.User import UserLoginResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", status_code=200, response_model=UserLoginResponse)
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_email == credentials.email).first()

    # if email is missing or invalid
    if credentials.email is None or user is None:
        raise HTTPException(status_code=401, detail="Invalid email address")

    # create auth token
    encoded_email = credentials.email.__str__().encode()
    token = hashlib.md5(encoded_email).hexdigest()

    # save token to database
    user.user_token = token
    db.commit()
    db.refresh(user)

    return UserLoginResponse(
        token=token,
        **user.__dict__
    )
