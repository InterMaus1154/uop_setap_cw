import enum

from sqlalchemy import Column, BigInteger, ForeignKey, Enum, DateTime, func, UniqueConstraint, CheckConstraint
from sqlalchemy.orm import relationship

from database.db import Base

class UserRelationshipType(enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    BLOCKED = "blocked"

class UserRelationship(Base):
    __tablename__ = "user_relationships"

    user_rel_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    target_user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    user_rel_status = Column(Enum(UserRelationshipType), nullable=False, default=UserRelationshipType.PENDING, server_default="pending")
    updated_at = Column(DateTime, nullable=False, onupdate=func.now(), default=func.now(), server_default=func.now())
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    requester = relationship("User", foreign_keys="[UserRelationship.user_id]", back_populates="sent_relationships")
    addressee = relationship("User", foreign_keys="[UserRelationship.target_user_id]", back_populates="received_relationships")

    __table_args__ = (
        UniqueConstraint("user_id", "target_user_id", name="unique_user_rel_pair"),
        CheckConstraint("user_id <> target_user_id", name="check_no_self_user_rel")
    )
