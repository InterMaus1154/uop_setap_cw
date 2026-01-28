from sqlalchemy import Column, BigInteger, ForeignKey, Boolean, DateTime, func, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship

from database.db import Base

class LocationSharing(Base):
    __tablename__ = "location_sharing"

    loc_share_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    target_user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    is_enabled = Column(Boolean, nullable=False, default=False, server_default="false")
    updated_at = Column(DateTime, nullable=False, onupdate=func.now(), default=func.now(), server_default=func.now())
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    user = relationship("User", foreign_keys="[LocationSharing.user_id]", back_populates="shared_locations")
    target_user = relationship("User", foreign_keys="[LocationSharing.target_user_id]", back_populates="received_locations")

    __table_args__ = (
        CheckConstraint("user_id <> target_user_id", name="check_no_self_location_share"),
        UniqueConstraint("user_id", "target_user_id", name="unique_location_sharing_pair")
    )
