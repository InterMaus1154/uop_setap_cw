from pydantic import BaseModel
from models.pin_report import PinReportType
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class PinReportRequest(BaseModel):
    """Data required when reporting a pin"""
    report_type: PinReportType

class PinReportResponse(BaseModel):
    pin_report_id: int
    user_id: int
    report_type: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)