from sqlalchemy import Column, Integer, String, DateTime, func
from sqlalchemy.orm import relationship

from database.db import Base

class Admin(Base):
    __tablename__ = "admins"

    admin_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    admin_fname = Column(String(60), nullable=False)
    admin_lname = Column(String(60), nullable=False)
    admin_email = Column(String(250), nullable=False, unique=True)
    admin_password = Column(String(300), nullable=False)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    bans = relationship("UserBan", back_populates="admin")