import sys
import os
import pytest

from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(__file__))

from database.db import engine, get_db
from main import app
from models.user import User


@pytest.fixture
def db_session():
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer b841a343d433da77a23c662203d5e661"}


@pytest.fixture
def alt_auth_headers():
    return {"Authorization": "Bearer 42639eef50c0187f5ed8f6f8f0f7cfbe"}


@pytest.fixture
def main_user(db_session):
    return db_session.query(User).filter(
        User.user_token == "b841a343d433da77a23c662203d5e661"
    ).first()


@pytest.fixture
def alt_user(db_session):
    return db_session.query(User).filter(
        User.user_token == "42639eef50c0187f5ed8f6f8f0f7cfbe"
    ).first()