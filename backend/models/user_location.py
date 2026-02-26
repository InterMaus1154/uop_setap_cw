
from database.db import Base

from sqlalchemy import Column, BigInteger, ForeignKey, DOUBLE_PRECISION, Boolean, DateTime, func
from sqlalchemy.orm import relationship


class UserLocation(Base):
    __tablename__ = 'user_locations'

    user_loc_id = Column(BigInteger, autoincrement=True, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey('users.user_id'), nullable=False) # the person who is sharing the location
    latitude = Column(DOUBLE_PRECISION, nullable=False)
    longitude = Column(DOUBLE_PRECISION, nullable=False)
    is_enabled = Column(Boolean, nullable=False, default=True, server_default="true")
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())
    updated_at = Column(DateTime, nullable=False, onupdate=func.now(), default=func.now(), server_default=func.now())

    user = relationship("User", back_populates="user_location")
    location_permissions = relationship("LocationPermission", back_populates="user_location")


