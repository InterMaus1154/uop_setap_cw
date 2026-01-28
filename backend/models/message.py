from sqlalchemy import Column, BigInteger, ForeignKey, Text, DateTime, func
from sqlalchemy.orm import relationship

from database.db import Base


class Message(Base):
    __tablename__ = "messages"

    message_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    sender_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False, index=True)
    receiver_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False, index=True)
    message_body = Column(Text, nullable=False)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    sender = relationship("User", foreign_keys="[Message.sender_id]", back_populates="sent_messages")
    receiver = relationship("User", foreign_keys="[Message.receiver_id]", back_populates="received_messages")
