from sqlalchemy import Column, BigInteger, ForeignKey, Float, Boolean, DateTime, func
from sqlalchemy.orm import relationship

from database.db import Base


class UserLocation(Base):
    __tablename__ = "user_locations"

    user_loc_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False, unique=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    is_enabled = Column(Boolean, nullable=False, default=True, server_default="true")
    updated_at = Column(DateTime, nullable=False, onupdate=func.now(), default=func.now(), server_default=func.now())
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    user = relationship("User", back_populates="user_location")
    location_permissions = relationship("LocationPermission", back_populates="user_location")
