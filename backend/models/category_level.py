# category level model
from sqlalchemy import Column, SmallInteger, String

from database.db import Base

class CategoryLevel(Base):
    __tablename__ = 'category_levels'

    cat_level_id = Column(SmallInteger, primary_key=True, index=True, autoincrement=True)
    cat_level_name = Column(String(60), nullable=False, unique=True)
    cat_level_ttl_mins = Column(SmallInteger, nullable=False)