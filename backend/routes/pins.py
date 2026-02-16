from fastapi import APIRouter, HTTPException
from fastapi.params import Depends
from sqlalchemy.orm import Session

from database.db import get_db
from models.pin import Pin
from models.category import Category
from schemas.Pin import PinResponse, PinCreate, PinUpdate
from middleware.auth import require_auth
from models.user import User

router = APIRouter(prefix="/pins", tags=["pins"])

@router.get("/", response_model=list[PinResponse])
def get_pins(db: Session = Depends(get_db)):
    """Get all active pins"""
    pins = db.query(Pin).filter(Pin.pin_isactive == True).all()
    return pins

@router.get("/{pin_id}", response_model=PinResponse)
def get_pin(pin_id: int, db: Session = Depends(get_db)):
    """Get a specific pin by ID"""
    pin = db.query(Pin).filter(Pin.pin_id == pin_id, Pin.pin_isactive == True).first()
    if not pin:
        raise HTTPException(status_code=404, detail="Pin not found")
    return pin

@router.post("/", response_model=PinResponse, status_code=201)
def create_pin(pin_data: PinCreate, db: Session = Depends(get_db)):
    """Create a new pin"""
    #Ensures category exists
    category = db.query(Category).filter(Category.cat_id == pin_data.cat_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    #Create new pin
    new_pin = Pin(
        pin_title = pin_data.pin_title,
        pin_latitude = pin_data.pin_latitude,
        pin_longitude = pin_data.pin_longitude,
        user_id = pin_data.user_id,
        cat_id = pin_data.cat_id,
        sub_cat_id = pin_data.sub_cat_id,
        pin_expire_at = pin_data.pin_expire_at,
        pin_description = pin_data.pin_description
    )

    db.add(new_pin)
    db.commit()
    db.refresh(new_pin)

    return new_pin

@router.put("/{pin_id}", response_model=PinResponse)
def update_pin(pin_id: int, pin_data: PinUpdate, db: Session = Depends(get_db)):
    """Update pin details"""
    pin = db.query(Pin).filter(Pin.pin_id == pin_id).first()

    if not pin: raise HTTPException(status_code=404, detail="Pin not found")

    #update only provided fields
    if pin_data.pin_title is not None:
        pin.pin_title = pin_data.pin_title
    if pin_data.pin_description is not None:
        pin.pin_description = pin_data.pin_description
    if pin_data.pin_latitude is not None:
        pin.pin_latitude = pin_data.pin_latitude
    if pin_data.pin_longitude is not None:
        pin.pin_longitude = pin_data.pin_longitude
    if pin_data.pin_expire_at is not None:
        pin.pin_expire_at = pin_data.pin_expire_at      

    db.commit()
    db.refresh(pin)               

    return pin