import pytest


class TestGetCategories:
    """Test plan reference: GC1, GC2, GC3, GC4"""
    
    def test_get_all_categories(self, client):
        """Test getting all categories returns 200"""
        response = client.get("/categories/")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_all_category_levels(self, client):
        """Test getting all category levels returns 200"""
        response = client.get("/categories/levels")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_all_sub_categories(self, client):
        """Test getting all sub categories returns 200"""
        response = client.get("/categories/sub-categories")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_sub_categories_for_existent_category(self, client):
        """Test getting sub categories for a valid category returns 200"""
        valid_cat_id = client.get("/categories/").json()[0]["cat_id"]
        response = client.get(f"/categories/{valid_cat_id}/sub-categories")
        assert response.status_code == 200

    def test_get_sub_categories_for_nonexistent_category(self, client):
        """Test getting sub categories for an invalid category returns 404"""
        response = client.get("/categories/999999/sub-categories")
        assert response.status_code == 404