from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import Response, JSONResponse
from fastapi.params import Depends
from sqlalchemy.orm import Session, Query as Q, joinedload

from typing import Optional

from database.db import get_db
from models import CategoryLevel, SubCategory
from models.admin import Admin
from models.pin import Pin
from models.category import Category
from models.pin_reaction import PinReaction
from schemas.Pin import PinResponse, PinCreate, PinUpdate, PinReactionRequest
from middleware.auth import require_auth
from models.user import User

router = APIRouter(prefix="/pins", tags=["pins"])


@router.get("/", response_model=list[PinResponse])
def get_pins(cat_id: Optional[list[int]] = Query(default=None), cat_level_id: Optional[list[int]] = Query(default=None),
             db: Session = Depends(get_db)):
    """Get all active pins"""

    # build query
    query: Q[Pin] = (db.query(Pin)
                     .options(joinedload(Pin.category).joinedload(Category.category_level))
                     .options(joinedload(Pin.reactions))
                     .filter(Pin.pin_isactive == True))

    # join category on pins if any id is present
    if cat_id or cat_level_id:
        query = query.join(Pin.category)

    if cat_id:
        query = query.filter(Category.cat_id.in_(cat_id))

    if cat_level_id:
        query = query.filter(Category.cat_level_id.in_(cat_level_id))

    pins = query.all()
    return pins


@router.get("/{pin_id}", response_model=PinResponse)
def get_pin(pin_id: int, db: Session = Depends(get_db)):
    """Get a specific pin by ID"""
    pin = (db.query(Pin)
           .options(joinedload(Pin.category).joinedload(Category.category_level))
           .options(joinedload(Pin.reactions))
           .filter(Pin.pin_id == pin_id, Pin.pin_isactive == True).first())
    if not pin:
        raise HTTPException(status_code=404, detail="Pin not found")
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
               authenticated: User | Admin = Depends(require_auth)):
    """Update pin details"""
    pin: Pin = (db.query(Pin)
                .options(joinedload(Pin.category).joinedload(Category.category_level))
                .options(joinedload(Pin.reactions))
                .filter(Pin.pin_id == pin_id).first())

    if not pin: raise HTTPException(status_code=404, detail="Pin not found")

    # check if user is updating who created or it is an admin
    if isinstance(authenticated, User) and pin.user_id != authenticated.user_id or not isinstance(authenticated, Admin):
        raise HTTPException(status_code=403, detail="Forbidden")

    # update only provided fields
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


@router.patch("/{pin_id}/react")
def react_to_pin(request: PinReactionRequest, pin_id: int, user: User = Depends(require_auth),
                 db: Session = Depends(get_db)):
    """React to a pin with like or dislike"""

    # validate value
    if request.value not in [1, -1]:
        raise HTTPException(status_code=422, detail="Invalid reaction value. Must be -1 or 1")

    # check if reaction already exists
    reaction: PinReaction | None = db.query(PinReaction).filter(PinReaction.pin_id == pin_id,
                                                                PinReaction.user_id == user.user_id).first()

    if reaction is not None:
        # update reaction if value is not the same
        if request.value != reaction.reaction_value:
            reaction.reaction_value = request.value
            db.commit()
            db.refresh(reaction)
            return JSONResponse(status_code=200, content={"message": "Reaction updated"})
        else:
            return Response(status_code=204)

    # create new reaction
    try:
        reaction = PinReaction(user_id=user.user_id, pin_id=pin_id, reaction_value=request.value)
        db.add(reaction)
        db.commit()
        return JSONResponse(status_code=201, content={"message": "Reaction successfully created"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error at creating reaction. Error: {e}")


@router.delete("/{pin_id}/react", status_code=200)
def delete_pin_reaction(pin_id: int, user: User = Depends(require_auth), db: Session = Depends(get_db)):
    """Delete pin reaction for logged-in user"""

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
            raise HTTPException(status_code=500, detail=f"Error at deleting reaction. Error: {e}")
    else:
        return Response(status_code=204)
