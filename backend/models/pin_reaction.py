# Pin reactions model
from sqlalchemy import Column, BigInteger, ForeignKey, SmallInteger, CheckConstraint, func, DateTime
from sqlalchemy.orm import relationship
from database.db import Base


class PinReaction(Base):
    __tablename__ = 'pin_reactions'

    reaction_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    pin_id = Column(BigInteger, ForeignKey("pins.pin_id"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    reaction_value = Column(SmallInteger, nullable=False)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    pin = relationship("Pin", back_populates="reactions")
    user = relationship("User", back_populates="reactions")

    __table_args__ = (
        CheckConstraint('reaction_value IN (1, -1)', name="check_reaction_value"),
    )