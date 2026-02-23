from fastapi import APIRouter, HTTPException, Depends, Response
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from database.db import get_db
from middleware.auth import require_auth
from models.user import User
from models.user_relationship import UserRelationship, UserRelationshipType
from schemas.Friend import FriendCreate, FriendResponse, FriendUpdate
from schemas.User import UserResponse


router = APIRouter(prefix="/friends", tags=["friends"])


@router.post("/", response_model=FriendResponse, status_code=201)
def send_friend_request(payload: FriendCreate, db: Session = Depends(get_db), user: User = Depends(require_auth)):
    """Send a friend request to another user."""
    if payload.target_user_id == user.user_id:
        raise HTTPException(status_code=422, detail="Cannot send request to yourself")

    target = db.query(User).filter(User.user_id == payload.target_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    # prevent duplicate or reversed relationships 
    existing = db.query(UserRelationship).filter(
        or_(
            and_(UserRelationship.user_id == user.user_id, UserRelationship.target_user_id == payload.target_user_id),
            and_(UserRelationship.user_id == payload.target_user_id, UserRelationship.target_user_id == user.user_id),
        )
    ).first()
    if existing:
        if existing.user_rel_status == UserRelationshipType.BLOCKED:
            raise HTTPException(status_code=403, detail ="Relationship is blocked")
        if existing.user_rel_status == UserRelationshipType.ACCEPTED:
            return Response(status_code=204)
        raise HTTPException(status_code=422, detail="Relationship already exists")
    

    rel = UserRelationship(
        user_id=user.user_id,
        target_user_id=payload.target_user_id,
        user_rel_status=UserRelationshipType.PENDING
    )
    db.add(rel)
    db.commit()
    db.refresh(rel)
    return rel


@router.get("/", response_model=list[UserResponse])
def list_friends(db: Session = Depends(get_db), user: User = Depends(require_auth)):
    """List all friends for the authenticated user."""
    return user.friends


@router.get("/requests", response_model=list[FriendResponse])
def incoming_requests(db: Session = Depends(get_db), user: User = Depends(require_auth)):
    """List incoming (pending) friend requests."""
    rels = db.query(UserRelationship).filter(
        UserRelationship.target_user_id == user.user_id,
        UserRelationship.user_rel_status == UserRelationshipType.PENDING
    ).all()
    return rels


@router.patch("/{rel_id}", response_model=FriendResponse)
def update_relationship(rel_id: int, payload: FriendUpdate, db: Session = Depends(get_db), user: User = Depends(require_auth)):
    """Update relationship status (accept / reject / block)."""

    rel = db.query(UserRelationship).filter(UserRelationship.user_rel_id == rel_id).first()
    if not rel:
        raise HTTPException(status_code=404, detail="Relationship not found")
    
    # only authorised users can change the relationship
    if rel.user_id != user.user_id and rel.target_user_id != user.user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    
    # assign provided status
    rel.user_rel_status = UserRelationshipType(payload.response)
    db.commit()
    db.refresh(rel)
    return rel

@router.delete("/{rel_id}", status_code=204)
def delete_relationship(rel_id: int, db: Session = Depends(get_db), user: User = Depends(require_auth)):
    """Delete a user relationship (only participants may delete)."""
    rel = db.query(UserRelationship).filter(UserRelationship.user_rel_id == rel_id).first() 
    if not rel:
        raise HTTPException(status_code=404, detail="Relationship not found")
    if rel.user_id != user.user_id and rel.target_user_id != user.user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    db.delete(rel)
    db.commit()
    return
    
    
    


