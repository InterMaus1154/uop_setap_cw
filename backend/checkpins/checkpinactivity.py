from contextlib import asynccontextmanager
from fastapi import FastAPI
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from database.db import SessionLocal
from models.pin import Pin
from models.pin_reaction import PinReaction
from models.pin_report import PinReport, PinReportType
from models.invitation_code import InvitationCode
from models.user import User
from datetime import datetime, timedelta, timezone
from sqlalchemy import func
scheduler = AsyncIOScheduler()

def cleanup():
    print("cleanup task")

def check_pin_activity():
    db = SessionLocal()
    try:
        pins = db.query(Pin).filter(Pin.pin_isactive == True).all()
        print(f"Found {len(pins)} active pins")
        changed = False
        for pin in pins:
            if datetime.now() > pin.pin_expire_at:
                pin.pin_isactive = False
                changed = True

        try:
            if changed:
                db.commit()
        except Exception as e:
            print(f"Error committing changes: {e}")
            db.rollback()
        
        pins = db.query(Pin).filter(Pin.pin_isactive == False).all()
        print(f"Found {len(pins)} inactive pins")
        pins = db.query(Pin).all()
        print(f"Found {len(pins)} total pins")

    finally:
        db.close()

def deactivate_disliked_pins(dislike_threshold: int = 15, db=None):
    owned = db is None
    if owned:
        db = SessionLocal()
    try:
        window = datetime.now() - timedelta(minutes=30)
        disliked_pin_ids = (
            db.query(PinReaction.pin_id)
            .filter(
                PinReaction.reaction_value == -1,
                PinReaction.created_at >= window,
            )
            .group_by(PinReaction.pin_id)
            .having(func.count(PinReaction.reaction_id) >= dislike_threshold)
            .scalar_subquery()
        )
        changed = (
            db.query(Pin)
            .filter(Pin.pin_isactive == True, Pin.pin_id.in_(disliked_pin_ids))
            .update({Pin.pin_isactive: False}, synchronize_session=False)
        )
        if changed and owned:
            db.commit()
    except Exception as e:
        print(f"Error deactivating disliked pins: {e}")
        if owned:
            db.rollback()
    finally:
        if owned:
            db.close()


def deactivate_resolved_pins(resolved_threshold: int = 5, db=None):
    """Deactivate pins that have received enough resolved reports within 30 minutes."""
    owned = db is None
    if owned:
        db = SessionLocal()
    try:
        window = datetime.now() - timedelta(minutes=30)
        resolved_pin_ids = (
            db.query(PinReport.pin_id)
            .filter(
                PinReport.report_type == PinReportType.RESOLVED,
                PinReport.created_at >= window,
            )
            .group_by(PinReport.pin_id)
            .having(func.count(PinReport.pin_report_id) >= resolved_threshold)
            .scalar_subquery()
        )
        changed = (
            db.query(Pin)
            .filter(Pin.pin_isactive == True, Pin.pin_id.in_(resolved_pin_ids))
            .update({Pin.pin_isactive: False}, synchronize_session=False)
        )
        if changed and owned:
            db.commit()
        print(f"Deactivated {changed} pins due to resolved reports threshold")
    except Exception as e:
        print(f"Error deactivating resolved pins: {e}")
        if owned:
            db.rollback()
    finally:
        if owned:
            db.close()


def deactivate_expired_guests():
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        expired = db.query(InvitationCode).filter(
            InvitationCode.expires_at < now,
            InvitationCode.guest_user_id.isnot(None),
        ).all()
        changed = False
        for inv in expired:
            guest = db.query(User).filter(
                User.user_id == inv.guest_user_id,
                User.user_isactive == True,
            ).first()
            if guest:
                guest.user_isactive = False
                changed = True
        if changed:
            db.commit()
    except Exception as e:
        print(f"Error deactivating guests: {e}")
        db.rollback()
    finally:
        db.close()


def deactivate_expired_location_sharing():
    """Disable location sharing for users whose sharing_expires_at has passed."""
    from models.user_location import UserLocation
    db = SessionLocal()
    try:
        now = datetime.now()
        expired = (
            db.query(UserLocation)
            .filter(
                UserLocation.is_enabled == True,
                UserLocation.sharing_expires_at.isnot(None),
                UserLocation.sharing_expires_at <= now,
            )
            .all()
        )
        for location in expired:
            location.is_enabled = False
            location.sharing_expires_at = None
        if expired:
            db.commit()
            print(f"Disabled location sharing for {len(expired)} users due to expiry")
    except Exception as e:
        print(f"Error deactivating expired location sharing: {e}")
        db.rollback()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(cleanup, "cron", hour=2, minute=0, id="daily_cleanup")
    scheduler.add_job(check_pin_activity, "interval", seconds=60, id="pin_activity_check")
    scheduler.add_job(deactivate_disliked_pins, "interval", seconds=60, id="dislike_pin_deactivation")
    scheduler.add_job(deactivate_resolved_pins, "interval", seconds=60, id="resolved_pin_deactivation")
    scheduler.add_job(deactivate_expired_guests, "interval", hours=1, id="guest_deactivation")
    scheduler.add_job(deactivate_expired_location_sharing, "interval", seconds=30, id="location_sharing_expiry")
    scheduler.start()
    yield
    scheduler.shutdown()