from fastapi import APIRouter, HTTPException, Query
from fastapi.params import Depends
from sqlalchemy.orm import Session, Query as Q

from database.db import get_db
from middleware.auth import require_auth
from models.user import User
from schemas.User import UserResponse, UserCreate, UserUpdate

router = APIRouter(prefix="/users", tags=["users"])


# Below are some example routes for getting user and creating new user

@router.get("/", response_model=list[UserResponse])
def get_users(db: Session = Depends(get_db)):
    """List all users. Used for prototype only."""
    users = db.query(User).all()
    return users


@router.put("/", response_model=UserResponse, status_code=200)
def update_user(user_data: UserUpdate, user: User = Depends(require_auth), db: Session = Depends(get_db)):
    """Update the logged-in user's details"""

    # only update fields that are present
    if user_data.user_fname:
        user.user_fname = user_data.user_fname

    if user_data.user_lname:
        user.user_lname = user_data.user_lname

    if user_data.user_display_name:
        user.user_displayname = user_data.user_display_name

    db.commit()
    db.refresh(user)

    return user


@router.get('/me', response_model=UserResponse)
def get_me(user: User = Depends(require_auth)):
    """Return profile data for the logged-in user"""
    return user


@router.get('/{user_id}', response_model=UserResponse)
def get_user_by_id(user_id: int, db: Session = Depends(get_db)):
    """Get user by id"""
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user


@router.get('/search/{email}', response_model=UserResponse)
def get_user_by_email(email: str, db: Session = Depends(get_db)):
    """Get user by email address"""
    user = db.query(User).filter(User.user_email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user


@router.post('/', response_model=UserResponse, status_code=201)
def create_user(user_data: UserCreate, db: Session = Depends(get_db)):
    # check for email
    existing_user = db.query(User).filter(User.user_email == user_data.user_email).first()

    if existing_user:
        raise HTTPException(status_code=422, detail="User with email already exists")

    new_user = User(
        user_email=user_data.user_email,
        user_fname=user_data.user_fname,
        user_lname=user_data.user_lname,
        user_displayname=user_data.user_displayname
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user
