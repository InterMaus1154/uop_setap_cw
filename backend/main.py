import asyncio
import os
from contextlib import asynccontextmanager
from datetime import datetime

from dotenv import load_dotenv
from fastapi import FastAPI, Path
from fastapi.middleware.cors import CORSMiddleware

from database.db import SessionLocal
from models.invitation_code import InvitationCode
from models.user import User
from routes.users import router as users_router
from routes.pins import router as pins_router
from routes.categories import router as categories_router
from routes.auth import router as auth_router
from routes.friends import router as friends_router
from routes.invitations import router as invitations_router
from routes.user_locations import router as user_locations_router, location_permissions_router

load_dotenv()


async def _deactivate_expired_guests():
    while True:
        await asyncio.sleep(3600)
        db = SessionLocal()
        try:
            now = datetime.utcnow()
            expired = db.query(InvitationCode).filter(
                InvitationCode.expires_at < now,
                InvitationCode.guest_user_id.isnot(None),
            ).all()
            for inv in expired:
                guest = db.query(User).filter(
                    User.user_id == inv.guest_user_id,
                    User.user_isactive == True,
                ).first()
                if guest:
                    guest.user_isactive = False
            db.commit()
        finally:
            db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    asyncio.create_task(_deactivate_expired_guests())
    yield


app = FastAPI(lifespan=lifespan)

# Allow any localhost port for development 
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost(:\d+)?",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(pins_router)
app.include_router(categories_router)
app.include_router(friends_router)
app.include_router(invitations_router)
app.include_router(user_locations_router)
app.include_router(location_permissions_router)



@app.get("/")
def test():
    return {"message": "test"}
