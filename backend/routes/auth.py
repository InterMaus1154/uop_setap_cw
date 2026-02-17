from fastapi import APIRouter, HTTPException
from fastapi.params import Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from database.db import get_db
from middleware.auth import require_auth
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

    # if user is inactive, reject login
    if not user.user_isactive:
        raise HTTPException(status_code=403, detail="Your account has been disabled!")

    # create auth token
    encoded_email = credentials.email.__str__().encode()
    token = hashlib.md5(encoded_email).hexdigest()

    # save token to database
    user.user_token = token

    # update login timestamp
    user.last_login = func.now()

    db.commit()
    db.refresh(user)

    return UserLoginResponse(
        token=token,
        **user.__dict__
    )


@router.post("/logout", status_code=200)
def logout(db: Session = Depends(get_db), user: User = Depends(require_auth)):
    # delete user token from db
    user.user_token = None
    db.commit()
    db.refresh(user)
    return {
        "message": "Successfully logged out"
    }
