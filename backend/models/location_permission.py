from database.db import Base

from sqlalchemy import Column, BigInteger, ForeignKey, func, DateTime
from sqlalchemy.orm import relationship


class LocationPermission(Base):
    __tablename__ = 'location_permissions'

    loc_perm_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    user_loc_id = Column(BigInteger, ForeignKey('user_locations.user_loc_id'), nullable=False)
    user_id = Column(BigInteger, ForeignKey('users.user_id'), nullable=False) # the permission the location is shared with
    updated_at = Column(DateTime, nullable=False, onupdate=func.now(), default=func.now(), server_default=func.now())
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    user_location = relationship("UserLocation", back_populates="location_permissions")
    user = relationship("User", back_populates="location_permissions")