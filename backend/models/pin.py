# Pin model
from sqlalchemy import Column, BigInteger, SmallInteger, ForeignKey, String, DOUBLE_PRECISION, Boolean, DateTime, func
from sqlalchemy.orm import relationship

from database.db import Base

class Pin(Base):
    __tablename__ = 'pins'

    pin_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    cat_id = Column(SmallInteger, ForeignKey("categories.cat_id"), nullable=False)
    sub_cat_id = Column(SmallInteger, ForeignKey("sub_categories.sub_cat_id"), nullable=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    pin_title = Column(String(30), nullable=False)
    pin_description = Column(String(300), nullable=True)
    pin_picture_path = Column(String(500), nullable=True)
    pin_latitude = Column(DOUBLE_PRECISION, nullable=False)
    pin_longitude = Column(DOUBLE_PRECISION, nullable=False)
    pin_isactive = Column(Boolean, nullable=False, default=True, server_default="true")
    pin_expire_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    category = relationship("Category", back_populates="pins")
    sub_category = relationship("SubCategory", back_populates="pins")
    user = relationship("User", back_populates="pins")
