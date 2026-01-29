from fastapi import APIRouter
from fastapi.params import Depends
from sqlalchemy.orm import Session

from database.db import get_db
from models.user import User

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/")
def get_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return users