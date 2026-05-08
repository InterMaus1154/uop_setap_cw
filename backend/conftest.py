import sys
import os
import pytest

from sqlalchemy.orm import Session
from fastapi.testclient import TestClient


sys.path.insert(0, os.path.dirname(__file__))

from database.db import engine, get_db
from main import app

@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer fbde5c7f68cdd28e9105cdbafa6556eb"}

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