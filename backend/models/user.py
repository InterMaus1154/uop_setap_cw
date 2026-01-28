# User database model
from sqlalchemy import Column, BigInteger, String, Boolean, text, DateTime
from sqlalchemy.sql import func

from database.db import Base

class User(Base):
    __tablename__ = 'users'

    user_id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_fname = Column(String(60), nullable=False)
    user_lname = Column(String(60), nullable=False)
    user_email = Column(String(250), nullable=False, unique=True)
    user_displayname = Column(String(30), nullable=True)
    user_isactive = Column(Boolean, nullable=False, server_default=text("true"), default=True)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now(), default=func.now())