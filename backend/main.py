import os
from dotenv import load_dotenv
from fastapi import FastAPI, Path
from fastapi.middleware.cors import CORSMiddleware

from routes.users import router as users_router
from routes.pins import router as pins_router
from routes.categories import router as categories_router
from routes.auth import router as auth_router
from routes.friends import router as friends_router

load_dotenv()

app = FastAPI()

# Allow any localhost port for development 
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost(:\d+)?",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(pins_router)
app.include_router(categories_router)
app.include_router(friends_router)



@app.get("/")
def test():
    return {"message": "test"}
