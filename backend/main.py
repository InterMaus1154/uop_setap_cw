import os
from dotenv import load_dotenv
from fastapi import FastAPI, Path
from fastapi.middleware.cors import CORSMiddleware

from typing import Optional
from routes import users

load_dotenv()

app = FastAPI()

@app.get('api/health')
def health():
    return {"message": "Api is running!:)"}

@app.get('/test')
def test():
    return "test"

app.include_router(users.router)