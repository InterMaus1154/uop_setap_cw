import sys
import os
import pytest

from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(__file__))

from database.db import engine, get_db
from main import app
from models.user import User


# Fixture to create a second user and provide a valid token for alt_auth_headers
@pytest.fixture
def alt_user(db_session):
    user = db_session.query(User).filter(User.user_email == "altuser@test.com").first()
    if not user:
        user = User(
            user_fname="Alt",
            user_lname="User",
            user_email="altuser@test.com",
            user_token="altusertoken123"
        )
        db_session.add(user)
        db_session.flush()
    return user


@pytest.fixture
def alt_auth_headers(alt_user):
    return {"Authorization": f"Bearer {alt_user.user_token}"}


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
def main_user(db_session):
    user = db_session.query(User).filter(User.user_email == "test@test.app").first()
    if not user:
        user = User(
            user_fname="Test",
            user_lname="User",
            user_email="test@test.app",
            user_token="fbde5c7f68cdd28e9105cdbafa6556eb"
        )
        db_session.add(user)
        db_session.flush()
    else:
        user.user_token = "fbde5c7f68cdd28e9105cdbafa6556eb"
    return user


@pytest.fixture
def auth_headers(main_user):
    return {"Authorization": f"Bearer {main_user.user_token}"}
