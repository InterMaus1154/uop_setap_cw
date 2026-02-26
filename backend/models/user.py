# User database model
from sqlalchemy import Column, BigInteger, String, Boolean, text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from database.db import Base
from models.user_relationship import UserRelationshipType


class User(Base):
    __tablename__ = 'users'

    user_id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_fname = Column(String(60), nullable=False)
    user_lname = Column(String(60), nullable=False)
    user_email = Column(String(250), nullable=False, unique=True)
    user_displayname = Column(String(30), nullable=True)
    user_use_displayname = Column(Boolean, nullable=False, server_default=text("false"), default=False)
    user_isactive = Column(Boolean, nullable=False, server_default=text("true"), default=True)
    user_token = Column(String(500), nullable=True)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now(), default=func.now())

    pins = relationship("Pin", back_populates="user")
    reactions = relationship("PinReaction", back_populates="user")
    pin_reports = relationship("PinReport", back_populates="user")
    reports = relationship("UserReport", back_populates="user")
    bans = relationship("UserBan", back_populates="user")
    sent_messages = relationship("Message", foreign_keys="[Message.sender_id]", back_populates="sender")
    received_messages = relationship("Message", foreign_keys="[Message.receiver_id]", back_populates="receiver")
    sent_relationships = relationship("UserRelationship", foreign_keys="[UserRelationship.user_id]",
                                      back_populates="requester")
    received_relationships = relationship("UserRelationship", foreign_keys="[UserRelationship.target_user_id]",
                                          back_populates="addressee")
    user_location = relationship('UserLocation', back_populates="user"
                                 , uselist=False)  # the sharing which this user initiated
    location_permissions = relationship("LocationPermission", foreign_keys="[LocationPermission.user_id]",
                                        back_populates="user")  # the locations which are shared with this user

    @property
    def friends(self) -> list["User"]:
        friends: list[User] = []

        for rel in self.sent_relationships:
            if rel.user_rel_status == UserRelationshipType.ACCEPTED:
                friends.append(rel.addressee)

        for rel in self.received_relationships:
            if rel.user_rel_status == UserRelationshipType.ACCEPTED:
                friends.append(rel.requester)
        return friends
