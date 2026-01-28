import enum

from sqlalchemy.orm import relationship

from database.db import Base
from sqlalchemy import Column, Integer, BigInteger, ForeignKey, Enum, DateTime, Text, Boolean, func


class UserBanType(enum.Enum):
    PERMANENT = "permanent"
    TEMPORARY = "temporary"

class UserBan(Base):
    __tablename__ = "user_bans"

    ban_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    admin_id = Column(Integer, ForeignKey("admins.admin_id"), nullable=False)
    ban_type = Column(Enum(UserBanType), nullable=False)
    ban_expiry = Column(DateTime, nullable=True)
    ban_reason = Column(Text, nullable=False)
    ban_isactive = Column(Boolean, nullable=False, default=True, server_default="true")
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    user = relationship("User", back_populates="bans")
    admin = relationship("Admin", back_populates="bans")