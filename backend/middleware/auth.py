from typing import Optional

from fastapi import Request, HTTPException, Header, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database.db import get_db
from models.user import User


security = HTTPBearer()

def require_auth(credentials: HTTPAuthorizationCredentials = Depends(security),db: Session = Depends(get_db)) -> User:
    """Validate token and return authenticated user"""

    token = credentials.credentials

    # find user with token
    user = db.query(User).filter(User.user_token == token).first()

    if not user:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    # reject inactive users
    if not user.user_isactive:
        raise HTTPException(status_code=403, detail="Your account has been disabled")

    return user