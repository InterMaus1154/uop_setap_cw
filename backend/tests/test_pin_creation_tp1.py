import io


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
        assert data["pin_title"] == payload["pin_title"]

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

    def test_create_pin_without_image_201(self, client, auth_headers):
        """Create a pin without an image, image path should be null"""

        rp = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data)
        assert rp.status_code == 201
        data = rp.json()
        assert data["pin_picture_url"] is None

    def test_create_pin_with_valid_image_201(self, client, auth_headers):
        """Create a pin with valid image"""
        fake_image = io.BytesIO(b"fake image content")
        rp = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data,
                         files={"image": ("test.jpg", fake_image, "image/jpeg")})
        assert rp.status_code == 201
        assert rp.json()["pin_picture_url"] is not None

    def test_create_pin_with_invalid_image_422(self, client, auth_headers):
        """Create a pin with an invalid image (pdf instead of image)"""
        fake_file = io.BytesIO(b"Not an actual image")
        rp = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data,
                         files={"image": ("test.pdf", fake_file, "application/pdf")})
        assert rp.status_code == 422

    def test_create_pin_with_invalid_image_size_422(self, client, auth_headers):
        """Create a pin with an invalid image size (bigger than 5mb)"""
        large_image = io.BytesIO(b"x" * (5 * 1024 * 1024 + 1))
        rp = client.post("/pins", headers=auth_headers, data=self.pin_valid_test_data,
                         files={"image": ("test.jpg", large_image, "image/jpeg")})
        assert rp.status_code == 422

    def test_create_pin_with_custom_expiry_201(self, client, auth_headers):
        """Add custom expiry field for a pin"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_expire_at"] = "2026-05-17T17:30:00"
        rp = client.post("/pins", data=payload, headers=auth_headers)
        assert rp.status_code == 201

        data = rp.json()
        assert data is not None
        assert "pin_expire_at" in data
        assert data["pin_expire_at"] == payload["pin_expire_at"]

    def test_create_pin_fails_with_invalid_expire_data_422(self, client, auth_headers):
        """Invalid date fails creation, expects 422"""
        payload = self.pin_valid_test_data.copy()
        payload["pin_expire_at"] = "2026 06 12 17 00"
        rp = client.post("/pins", data=payload, headers=auth_headers)
        assert rp.status_code == 422
