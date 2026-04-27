import random
import string
import hashlib
from datetime import datetime, timedelta

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session

from database.db import get_db
from middleware.auth import require_auth
from models.invitation_code import InvitationCode
from models.user import User
from schemas.Invitation import InvitationCodeResponse, LoginWithCodeRequest
from schemas.User import UserLoginResponse


router = APIRouter(tags=["invitation-codes"])


def _generate_code(length: int = 12) -> str:
    """Generates a random 12 char code."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


def _generate_guest_email() -> str:
    """Generates a dummy email for email field."""
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=10))
    return f"guest_{suffix}@guest.app"
    


def _create_token(email: str) -> str:
    """creates secure token"""
    return hashlib.md5(email.encode()).hexdigest()

@router.post("/invitation-codes", status_code=201, response_model=InvitationCodeResponse)
def create_invitation_code(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """generate a new invitation code for the authenticated user."""
    one_week_ago = datetime.utcnow() - timedelta(weeks=1)
    recent_count = (
        db.query(InvitationCode)
        .filter(
            InvitationCode.creator_id == current_user.user_id,
            InvitationCode.created_at >= one_week_ago
        )
        .count()
    )

    if recent_count >= 5:
        raise HTTPException(
            status_code=429,
            detail="You have reached the limit of 5 invitation codes per week"
        )
    
    while True:
        code = _generate_code()
        if not db.query(InvitationCode).filter(InvitationCode.code == code).first():
            break

    
    # save code to the database
    now = datetime.utcnow()
    invitation = InvitationCode(
        creator_id=current_user.user_id,
        code=code,
        created_at=now,
        expires_at=now + timedelta(hours=24),
        is_used=False
    )
    db.add(invitation)
    db.commit()
    db.refresh(invitation)
    return invitation

@router.get("/invitation-codes", status_code=200, response_model=list[InvitationCodeResponse])
def get_active_invitation_codes(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Return all active invitation codes for the user"""

    now = datetime.utcnow()
    codes = (
        db.query(InvitationCode)
        .filter(
            InvitationCode.creator_id == current_user.user_id,
            InvitationCode.expires_at > now,
            InvitationCode.is_used == False
        )
        .all()
    )
    return codes

@router.post("/auth/login/code", status_code=200, response_model=UserLoginResponse, tags=['auth'])
def login_with_code(
    request: LoginWithCodeRequest,
    db: Session = Depends(get_db)
):
    """Log in or create a guest account using a valid invitation code."""
    invitation = db.query(InvitationCode).filter(InvitationCode.code == request.code).first()

    if not invitation:
        raise HTTPException(status_code=401, detail="Invalid invitation code")
    
    # expired - deactive linked guest
    if invitation.expires_at < datetime.utcnow():
        if invitation.guest_user_id:
            guest = db.query(User).filter(User.user_id == invitation.guest_user_id).first()
            if guest:
                guest.user_isactive = False
                db.commit()
        raise HTTPException(status_code=401, detail="Invitation code has expired")

    if not invitation.is_used:
        # first use — create guest user
        guest_email = _generate_guest_email()
        while db.query(User).filter(User.user_email == guest_email).first():
            guest_email = _generate_guest_email()

        guest = User(
            user_fname="Guest",
            user_lname="User",
            user_email=guest_email,
            user_isactive=True,
        )
        db.add(guest)
        db.flush()

        invitation.guest_user_id = guest.user_id
        invitation.is_used = True
        db.commit()
        db.refresh(guest)

    else:
        # already used - load existing guest
        guest = db.query(User).filter(User.user_id == invitation.guest_user_id).first()
        if not guest:
            raise HTTPException(status_code=404, detail ="Guest user not found")
        
    token = _create_token(guest.user_email)
    guest.user_token = token
    db.commit()
    db.refresh(guest)

    return UserLoginResponse(token=token, expires_at=invitation.expires_at, **guest.__dict__)
