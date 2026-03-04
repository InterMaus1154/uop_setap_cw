import sys
import os
import pytest

sys.path.insert(0, os.path.dirname(__file__))

@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer fbde5c7f68cdd28e9105cdbafa6556eb"}