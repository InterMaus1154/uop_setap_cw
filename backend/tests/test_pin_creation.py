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

    def test_create_pin_with_all_valid_data(self, auth_headers, client):
        """Test pin creation by providing only valid data for each field"""
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)
        assert response.status_code == 201

        data = response.json()
        assert data is not None

    def test_create_pin_with_valid_title_as_single_char(self, auth_headers, client):
        """Test with a valid title, which is a single character"""
        self.pin_valid_test_data["pin_title"] = "A"
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        assert response.status_code == 201

        data = response.json()
        assert data is not None
        assert data["pin_title"] == self.pin_valid_test_data["pin_title"]

    def test_create_pin_with_valid_title_as_max_length(self, auth_headers, client):
        """Test with a valid title, which is maximum length (100)"""
        self.pin_valid_test_data["pin_title"] = "A" * 100
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        assert response.status_code == 201

        data = response.json()
        assert data is not None
        assert data["pin_title"] == self.pin_valid_test_data["pin_title"]

    def test_create_pin_without_title(self, auth_headers, client):
        """Test creating pin without a title"""
        self.pin_valid_test_data["pin_title"] = None
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        assert response.status_code == 422

        self.pin_valid_test_data["pin_title"] = "Test Pin"

    def test_create_pin_with_title_exceeding_max_length(self, auth_headers, client):
        """Test creating pin with a title that exceeds 100 chars"""
        self.pin_valid_test_data["pin_title"] = "a" * 101
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        print(response.json())

        assert response.status_code == 422

        self.pin_valid_test_data["pin_title"] = "Test Pin"

    def test_create_pin_without_a_category(self, auth_headers, client):
        """Test creating a pin without a category id"""
        self.pin_valid_test_data["cat_id"] = None
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        assert response.status_code == 422

    def test_create_pin_with_an_invalid_category_negative_number(self, auth_headers, client):
        """Test creating a pin with a category id that is a negative integer"""
        self.pin_valid_test_data["cat_id"] = -500
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        assert response.status_code == 422

    def test_create_pin_with_an_invalid_category_not_in_db(self, auth_headers, client):
        """Test creating a pin with a category id that is not in the database (but positive integer)"""
        self.pin_valid_test_data["cat_id"] = 50000
        response = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)

        assert response.status_code == 422

