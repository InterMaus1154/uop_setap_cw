# Sub category model for pins subcats
from sqlalchemy import Column, SmallInteger, ForeignKey, String
from sqlalchemy.orm import relationship

from database.db import Base

class SubCategory(Base):
    __tablename__ = 'sub_categories'

    sub_cat_id = Column(SmallInteger, primary_key=True, autoincrement=True, index=True)
    cat_id = Column(SmallInteger, ForeignKey("categories.cat_id"), nullable=False)
    sub_cat_name = Column(String(60), nullable=False)

    category = relationship("Category", back_populates="sub_categories")