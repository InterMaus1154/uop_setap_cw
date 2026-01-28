# Pin category model
from sqlalchemy import Column, SmallInteger, ForeignKey, String
from sqlalchemy.orm import relationship

from database.db import Base

class Category(Base):
    __tablename__ = 'categories'

    cat_id = Column(SmallInteger, primary_key=True, autoincrement=True, index=True)
    cat_level_id = Column(SmallInteger, ForeignKey('category_levels.cat_level_id'), nullable=False)
    cat_name = Column(String(60), nullable=False)

    category_level = relationship("CategoryLevel", back_populates="categories")
