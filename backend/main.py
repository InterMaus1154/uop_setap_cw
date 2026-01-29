import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from typing import Optional

load_dotenv()

app = FastAPI()


@app.get("/")
def test():
    return {"message": "test"}

@app.get("/users/{user_id}")
def get_user(user_id: int):
    return {"user": user_id}

