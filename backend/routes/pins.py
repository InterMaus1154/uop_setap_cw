from fastapi import APIRouter, HTTPException, Query, UploadFile, File, Form
from fastapi.responses import JSONResponse
from fastapi.params import Depends
from sqlalchemy.orm import Session, Query as Q, joinedload
from sqlalchemy import or_
import uuid
import os

from typing import Optional, Type

from database.db import get_db
from models import SubCategory
from models.pin import Pin
from models.category import Category
from models.pin_reaction import PinReaction
from schemas.Pin import PinResponse, PinCreate, PinUpdate, PinReactionRequest
from middleware.auth import require_auth, optional_auth
from models.user import User
from models.pin_report import PinReport
from models.pin_report import PinReportType
from schemas.pin_reporting import PinReportRequest, PinReportResponse

from datetime import datetime

router = APIRouter(prefix="/pins", tags=["pins"])

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads", "pins")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.get("/", response_model=list[PinResponse])
def get_pins(cat_id: Optional[list[int]] = Query(default=None), cat_level_id: Optional[list[int]] = Query(default=None),
             pin_expire_at: Optional[datetime] = Query(default=None),
             db: Session = Depends(get_db), user: User | None = Depends(optional_auth)):
    """Get all active pins"""

    # build query
    query: Q[Type[Pin]] = (db.query(Pin)
                           .options(joinedload(Pin.category).joinedload(Category.category_level))
                           .options(joinedload(Pin.reactions))
                           .options(joinedload(Pin.user))
                           .filter(Pin.pin_isactive == True))

    # join category on pins if any id is present
    if cat_id or cat_level_id:
        query = query.join(Pin.category)

    category_conditions = []
    if cat_id:
        category_conditions.append(Category.cat_id.in_(cat_id))

    if cat_level_id:
        category_conditions.append(Category.cat_level_id.in_(cat_level_id))

    query = query.filter(or_(*category_conditions))

    if pin_expire_at:
        end_of_day = pin_expire_at.replace(hour=23, minute=59, second=50)
        query = query.filter(Pin.pin_expire_at <= end_of_day)

    pins = query.all()

    # loop through all pins and if user is logged in
    # set the status for the pins based on how the user already interacted with it
    # 1 = like, -1 = dislike, None = no reaction yet
    # value is set in user_reaction field
    for pin in pins:
        pin.user_reaction = None
        if user:
            for reaction in pin.reactions:
                if reaction.user_id == user.user_id:
                    pin.user_reaction = reaction.reaction_value
                    break

    return pins


@router.get("/{pin_id}", response_model=PinResponse)
def get_pin(pin_id: int, db: Session = Depends(get_db), user: User | None = Depends(optional_auth)):
    """Get a specific pin by ID"""
    pin = (db.query(Pin)
           .options(joinedload(Pin.category).joinedload(Category.category_level))
           .options(joinedload(Pin.reactions))
           .options(joinedload(Pin.user))
           .filter(Pin.pin_id == pin_id, Pin.pin_isactive == True).first())
    if not pin:
        raise HTTPException(status_code=404, detail="Pin not found")

    # if user is logged in
    # set the status for the pins based on how the user already interacted with it
    # 1 = like, -1 = dislike, None = no reaction yet
    # value is set in user_reaction field
    pin.user_reaction = None
    if user:
        for reaction in pin.reactions:
            if reaction.user_id == user.user_id:
                pin.user_reaction = reaction.reaction_value
                break

    return pin


@router.post("/", response_model=PinResponse, status_code=201)
def create_pin(pin_data: PinCreate, db: Session = Depends(get_db), user: User = Depends(require_auth)):
    """Create a new pin"""
    # Ensures category exists
    category = db.query(Category).filter(Category.cat_id == pin_data.cat_id).first()
    if not category:
        raise HTTPException(status_code=422, detail="Invalid category")

    # check if sub cat exists if provided
    if pin_data.sub_cat_id:
        sub_category = (db.query(SubCategory)
                        .filter(SubCategory.sub_cat_id == pin_data.sub_cat_id,
                                SubCategory.cat_id == pin_data.cat_id)  # it will return null, if the provided sub_category doesnt belong to the provided category
                        .first())

        if not sub_category:
            raise HTTPException(status_code=422, detail="Invalid subcategory")

    # Create new pin
    new_pin = Pin(
        pin_title=pin_data.pin_title,
        pin_latitude=pin_data.pin_latitude,
        pin_longitude=pin_data.pin_longitude,
        user_id=user.user_id,
        cat_id=pin_data.cat_id,
        sub_cat_id=pin_data.sub_cat_id,
        pin_expire_at=pin_data.pin_expire_at,
        pin_description=pin_data.pin_description
    )

    db.add(new_pin)
    db.commit()
    db.refresh(new_pin)

    return new_pin


@router.put("/{pin_id}", response_model=PinResponse)
def update_pin(pin_id: int, pin_data: PinUpdate, db: Session = Depends(get_db),
               user: User = Depends(require_auth)):
    """Update pin details"""
    pin: Pin = (db.query(Pin)
                .options(joinedload(Pin.category).joinedload(Category.category_level))
                .options(joinedload(Pin.reactions))
                .options(joinedload(Pin.user))
                .filter(Pin.pin_id == pin_id).first())

    if not pin: raise HTTPException(status_code=404, detail="Pin not found")

    if user.user_id != pin.user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    # update only provided fields
    if pin_data.pin_title is not None:
        pin.pin_title = pin_data.pin_title
    if pin_data.pin_description is not None:
        pin.pin_description = pin_data.pin_description
    if pin_data.pin_expire_at is not None:
        pin.pin_expire_at = pin_data.pin_expire_at

    pin.user_reaction = None

    for reaction in pin.reactions:
        if reaction.user_id == user.user_id:
            pin.user_reaction = reaction.reaction_value
            break

    db.commit()
    db.refresh(pin)

    return pin


@router.delete("/{pin_id}", status_code=200)
def delete_pin(pin_id: int, db: Session = Depends(get_db), user: User = Depends(require_auth)):
    # check if pin exists
    pin: Pin | None = db.query(Pin).filter(Pin.pin_id == pin_id, Pin.pin_isactive == True).first()

    if pin is None:
        raise HTTPException(status_code=404, detail="Pin not found")

    # check if pin belongs to user
    if pin.user_id != user.user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    # deactivate pin instead of fully deleting, to preserve relationships (many tables depend on pin)
    pin.pin_isactive = False
    db.commit()
    return {"message": "Pin deleted"}


@router.patch("/{pin_id}/react")
def react_to_pin(request: PinReactionRequest, pin_id: int, user: User = Depends(require_auth),
                 db: Session = Depends(get_db)):
    """React to a pin with like or dislike"""

    # check if pin exists
    pin: Pin | None = db.query(Pin).filter(Pin.pin_id == pin_id, Pin.pin_isactive == True).first()
    if pin is None:
        raise HTTPException(status_code=404, detail="Pin not found")

    # check if reaction already exists
    reaction: PinReaction | None = db.query(PinReaction).filter(PinReaction.pin_id == pin_id,
                                                                PinReaction.user_id == user.user_id).first()

    if reaction is not None:
        # update reaction if value is not the same
        if request.value != reaction.reaction_value:
            try:
                reaction.reaction_value = request.value
                db.commit()
                return JSONResponse(status_code=200, content={"message": "Reaction updated"})
            except Exception as e:
                db.rollback()
                raise HTTPException(status_code=500, detail=f"Error at updating reaction. Error: {e}")
        else:
            return JSONResponse(status_code=200, content={"message": "Reaction already set"})

    # create new reaction
    try:
        reaction = PinReaction(user_id=user.user_id, pin_id=pin_id, reaction_value=request.value)
        db.add(reaction)
        db.commit()
        return JSONResponse(status_code=201, content={"message": "Reaction successfully created"})
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error at creating reaction. Error: {e}")


@router.delete("/{pin_id}/react", status_code=200)
def delete_pin_reaction(pin_id: int, user: User = Depends(require_auth), db: Session = Depends(get_db)):
    """Delete pin reaction for logged-in user"""

    # check if pin exists
    pin: Pin | None = db.query(Pin).filter(Pin.pin_id == pin_id, Pin.pin_isactive == True).first()
    if pin is None:
        raise HTTPException(status_code=404, detail="Pin not found")

    # check for existing
    reaction: PinReaction | None = db.query(PinReaction).filter(PinReaction.pin_id == pin_id,
                                                                PinReaction.user_id == user.user_id).first()
    if reaction is not None:
        try:
            # delete if found
            db.delete(reaction)
            db.commit()
            return JSONResponse(status_code=200, content={"message": "Reaction removed"})
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Error at deleting reaction. Error: {e}")
    else:
        raise HTTPException(status_code=404, detail="Reaction not found")


@router.post("/{pin_id}/report", status_code=201)
def report_pin(
        request: PinReportRequest,
        pin_id: int,
        user: User = Depends(require_auth),
        db: Session = Depends(get_db)
):
    """Report a pin"""

    # check if the pin exists
    pin = db.query(Pin).filter(
        Pin.pin_id == pin_id,
        Pin.pin_isactive == True
    ).first()

    if not pin:
        raise HTTPException(status_code=404, detail="Pin not found")

    # stopping duplicate reports from happening by the same user on same pin
    existing_report = db.query(PinReport).filter(
        PinReport.pin_id == pin_id,
        PinReport.user_id == user.user_id
    ).first()

    if existing_report:
        raise HTTPException(
            status_code=400,
            detail="You already reported this pin"
        )

    # create the report
    report = PinReport(
        pin_id=pin_id,
        user_id=user.user_id,
        report_type=request.report_type
    )

    try:
        db.add(report)
        db.commit()
        return {"message": "Pin reported successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/report-types")
def get_report_types():
    """Return all valid pin report types"""

    return [report_type.value for report_type in PinReportType]


@router.get("/{pin_id}/reports", response_model=list[PinReportResponse])
def get_pin_reports(
        pin_id: int,
        user: User = Depends(require_auth),
        db: Session = Depends(get_db)
):
    """Return all reports for a given pin"""

    # Check pin exists
    pin = db.query(Pin).filter(
        Pin.pin_id == pin_id,
        Pin.pin_isactive == True
    ).first()

    if not pin:
        raise HTTPException(status_code=404, detail="Pin not found")

    reports = db.query(PinReport).filter(
        PinReport.pin_id == pin_id
    ).all()

    return reports
