from models.pin import Pin


class TestCreatePins:
    """Test plan reference: TP1"""

    pin_valid_test_data = {
        "pin_title": "Test Pin",
        "pin_latitude": 50.7934840843502,
        "pin_longitude": -1.090784019921789,
        "cat_id": 1,
        "pin_expire_at": "2026-05-30",
        "pin_description": "Test Pin"
    }

    def test_create_pin_with_all_valid_data_201(self, auth_headers, client):
        """Test pin creation by providing only valid data for each field"""
        payload = self.pin_valid_test_data.copy()
        response = client.post("/pins", headers=auth_headers, data=payload)
        assert response.status_code == 201

        data = response.json()
        assert data is not None

    def test_create_pin_with_valid_title_as_single_char_201(self, auth_headers, client):
        """Test with a valid title, which is a single character"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_title"] = "A"
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 201

        data = response.json()
        assert data is not None
        assert data["pin_title"] == self.pin_valid_test_data["pin_title"]

    def test_create_pin_with_valid_title_as_max_length_201(self, auth_headers, client):
        """Test with a valid title, which is maximum length (100)"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_title"] = "A" * 100
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 201

        data = response.json()
        assert data is not None
        assert data["pin_title"] == payload["pin_title"]

    def test_create_pin_without_optional_description_201(self, auth_headers, client):
        """Create pin without an optional description, should not fail"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_description"] = None

        response = client.post("/pins", headers=auth_headers, data=payload)
        assert response.status_code == 201

        data = response.json()
        assert data is not None
        assert data["pin_description"] is None

    def test_create_pin_without_title_422(self, auth_headers, client):
        """Test creating pin without a title"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_title"] = None
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 422

    def test_create_pin_with_title_exceeding_max_length_422(self, auth_headers, client):
        """Test creating pin with a title that exceeds 100 chars"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_title"] = "a" * 101
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 422

    def test_create_pin_without_a_category_422(self, auth_headers, client):
        """Test creating a pin without a category id"""
        payload = self.pin_valid_test_data.copy()
        payload["cat_id"] = None
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 422

    def test_create_pin_with_an_invalid_category_negative_number_422(self, auth_headers, client):
        """Test creating a pin with a category id that is a negative integer"""
        payload = self.pin_valid_test_data.copy()
        payload["cat_id"] = -500
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 422

    def test_create_pin_with_an_invalid_category_not_in_db_422(self, auth_headers, client):
        """Test creating a pin with a category id that is not in the database (but positive integer)"""
        payload = self.pin_valid_test_data.copy()
        payload["cat_id"] = 50000
        response = client.post("/pins", headers=auth_headers, data=payload)

        assert response.status_code == 422
