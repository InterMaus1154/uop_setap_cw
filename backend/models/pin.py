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
    pin_title = Column(String(100), nullable=False)
    pin_description = Column(String(300), nullable=True)
    pin_picture_path = Column(String(500), nullable=True)
    pin_latitude = Column(DOUBLE_PRECISION, nullable=False)
    pin_longitude = Column(DOUBLE_PRECISION, nullable=False)
    pin_isactive = Column(Boolean, nullable=False, default=True, server_default="true")
    pin_expire_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    # cat_id, user_id, pin_title, pin_latitude, pin_longitude, pin_expire_at
    category = relationship("Category", back_populates="pins")
    sub_category = relationship("SubCategory", back_populates="pins")
    user = relationship("User", back_populates="pins")
    reactions = relationship("PinReaction", back_populates="pin")
    reports = relationship("PinReport", back_populates="pin")

    @property
    def pin_author_name(self) -> str:
        """Return display name if set, otherwise first name only (privacy)"""
        if self.user.user_displayname:
            return self.user.user_displayname
        return self.user.user_fname

    @property
    def pin_color(self) -> str:
        return self.category.category_level.cat_level_color

    @property
    def pin_likes(self) -> int:
        _likes = 0
        for reaction in self.reactions:
            if reaction.reaction_value == 1:
                _likes += 1
        return _likes

    @property
    def pin_dislikes(self) -> int:
        _dislikes = 0
        for reaction in self.reactions:
            if reaction.reaction_value == -1:
                _dislikes += 1
        return _dislikes

    @property
    def user_reaction(self):
        return getattr(self, '_user_reaction', None)

    @user_reaction.setter
    def user_reaction(self, value):
        self._user_reaction = value
