from fastapi import APIRouter, HTTPException
from fastapi.params import Depends
from sqlalchemy.orm import Session

from database.db import get_db
from schemas.Auth import LoginRequest

from models.user import User

import hashlib

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login")
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_email == credentials.email).first()

    # if email is missing or invalid
    if credentials.email is None or user is None:
        raise HTTPException(status_code=401, detail="Invalid email address")

    # create auth token

    encoded_email = credentials.email.__str__().encode()
    token = hashlib.md5(encoded_email).hexdigest()
    return {
        "token": token
    }
