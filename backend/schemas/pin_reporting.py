from pydantic import BaseModel
from models.pin_report import PinReportType


class PinReportRequest(BaseModel):
    """Data required when reporting a pin"""
    report_type: PinReportType
