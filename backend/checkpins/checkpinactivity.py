from contextlib import asynccontextmanager
from fastapi import FastAPI
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from database.db import SessionLocal
from models.pin import Pin
from datetime import datetime, timedelta
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(cleanup, "cron", hour=2, minute=0, id="daily_cleanup")
    scheduler.add_job(check_pin_activity, "interval", seconds=60, id="pin_activity_check")
    scheduler.start()
    yield
    scheduler.shutdown()

