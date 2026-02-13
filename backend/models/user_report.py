import enum

from sqlalchemy import Column, BigInteger, ForeignKey, Enum, DateTime, func
from sqlalchemy.orm import relationship

from database.db import Base

class UserReportType(enum.Enum):
    BOT = "bot"
    PROFANITY = "profanity"
    SPAM = "SPAM"
    INAPPROPRIATE_CONTENT = "inappropriate content"
    HARASSMENT = "harassment"
    SCAM = "scam"
    IMPERSONATION = "impersonation"
    HATE_SPEECH = "hate speech"

class UserReport(Base):
    __tablename__ = "user_reports"

    user_report_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    reported_user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    report_type = Column(Enum(UserReportType, name='userreporttype', create_type=True), nullable=False)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    user = relationship('User', back_populates='reports')
