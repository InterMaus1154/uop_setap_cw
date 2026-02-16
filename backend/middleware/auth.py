from typing import Optional

from fastapi import Request, HTTPException, Header, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database.db import get_db
from models.user import User
from models.admin import Admin

security = HTTPBearer()

def require_auth(credentials: HTTPAuthorizationCredentials = Depends(security),db: Session = Depends(get_db)) -> User | Admin:
    """Validate token and return authenticated user"""

    token = credentials.credentials

    # find user or admin with token
    user: User = db.query(User).filter(User.user_token == token).first()
    admin: Admin = db.query(Admin).filter(Admin.admin_token == token).first()

    if admin: return admin

    # reject inactive users
    if user and not user.user_isactive:
        raise HTTPException(status_code=403, detail="Your account has been disabled")

    # if neither admin or user token is passed
    if not user and not admin:
        raise HTTPException(status_code=401, detail="Unauthenticated")

    return user