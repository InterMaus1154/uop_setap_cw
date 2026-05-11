import pytest
from base import client
from database.db import SessionLocal

class TestGetCategories:
    
    def test_get_all_categories(self):
        """Test getting all categories returns 200"""
        response = client.get("/categories/")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_all_category_levels(self):
        """Test getting all category levels returns 200"""
        response = client.get("/categories/levels")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_all_sub_categories(self):
        """Test getting all sub categories returns 200"""
        response = client.get("/categories/sub-categories")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_sub_categories_for_existent_category(self):
        """Test getting sub categories for a valid category returns 200"""
        valid_cat_id = client.get("/categories/").json()[0]["cat_id"]
        response = client.get(f"/categories/{valid_cat_id}/sub-categories")
        assert response.status_code == 200

    def test_get_sub_categories_for_nonexistent_category(self):
        """Test getting sub categories for an invalid category returns 404"""
        response = client.get("/categories/999999/sub-categories")
        assert response.status_code == 404