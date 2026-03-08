from sqlalchemy import Column, BigInteger, String, Boolean, DateTime, ForeignKey, text
from sqlalchemy.sql import func

from database.db import Base


class InvitationCode(Base):
    __tablename__ = 'invitation_codes'

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    creator_id = Column(BigInteger, ForeignKey('users.user_id'), nullable=False)
    code = Column(String(12), unique=True, nullable=False)
    guest_user_id = Column(BigInteger, ForeignKey('users.user_id'), nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now(), default=func.now())
    expires_at = Column(DateTime, nullable=False)
    is_used = Column(Boolean, nullable=False, server_default=text("false"), default=False)
