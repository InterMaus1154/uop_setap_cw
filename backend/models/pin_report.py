# Pin report model
import enum

from sqlalchemy import Column, BigInteger, ForeignKey, Enum, DateTime, func
from sqlalchemy.orm import relationship

from database.db import Base

class PinReportType(enum.Enum):
    INACCURATE = "inaccurate"
    RESOLVED = "resolved"
    DUPLICATE = "duplicate"
    EXPIRED = "expired"
    MISLEADING = "misleading"
    SPAM = "spam"
    INAPPROPRIATE = "inappropriate"


class PinReport(Base):
    __tablename__ = "pin_reports"

    pin_report_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    pin_id = Column(BigInteger, ForeignKey("pins.pin_id"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    report_type = Column(Enum(PinReportType), nullable=False)
    created_at = Column(DateTime, nullable=False, default=func.now(), server_default=func.now())

    pin = relationship("Pin", back_populates="reports")
    user = relationship("User", back_populates="pin_reports")