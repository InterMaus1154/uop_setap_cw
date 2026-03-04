# category level model
from sqlalchemy import Column, SmallInteger, String
from sqlalchemy.orm import relationship

from database.db import Base


class CategoryLevel(Base):
    __tablename__ = 'category_levels'

    cat_level_id = Column(SmallInteger, primary_key=True, index=True, autoincrement=True)
    cat_level_name = Column(String(60), nullable=False, unique=True)
    cat_level_ttl_mins = Column(SmallInteger, nullable=False)
    cat_level_color = Column(String(10), nullable=False, unique=True)

    categories = relationship("Category", back_populates="category_level")
