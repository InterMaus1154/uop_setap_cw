import pytest
from database.db import SessionLocal

from models.pin import Pin
from models.category import Category
from models.category_level import CategoryLevel


class TestPinColour:
    PIN_BASE = {
        "pin_title": "Test Pin",
        "pin_latitude": 50.7934840843502,
        "pin_longitude": -1.090784019921789,
        "pin_expire_at": "2026-05-30",
        "pin_description": "Test Pin"
    }

    @pytest.mark.parametrize("cat_id", [1, 2, 6])
    def test_pin_has_valid_level_colour(self, auth_headers, client, db_session, cat_id):
        """Test pin has valid colour with different categories. It should have the same colour as the category level"""
        response = client.post("/pins", data={**self.PIN_BASE, "cat_id": cat_id}, headers=auth_headers)

        assert response.status_code == 201
        data = response.json()
        cat_id = data["cat_id"]

        category = db_session.query(Category).filter(Category.cat_id == cat_id).first()
        category_level = db_session.query(CategoryLevel).filter(
            CategoryLevel.cat_level_id == category.cat_level_id).first()

        assert category_level.cat_level_color == data["pin_color"]
