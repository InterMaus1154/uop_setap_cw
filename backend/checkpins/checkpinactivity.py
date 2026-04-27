from contextlib import asynccontextmanager
from fastapi import FastAPI
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from database.db import SessionLocal
from models.pin import Pin
from models.invitation_code import InvitationCode
from models.user import User
from datetime import datetime, timedelta, timezone
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(cleanup, "cron", hour=2, minute=0, id="daily_cleanup")
    scheduler.add_job(check_pin_activity, "interval", seconds=60, id="pin_activity_check")
    scheduler.add_job(deactivate_expired_guests, "interval", hours=1, id="guest_deactivation")
    scheduler.start()
    yield
    scheduler.shutdown()

