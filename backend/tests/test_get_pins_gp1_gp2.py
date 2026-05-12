from http.client import responses


class TestGetPins:
    """Test plan reference: GP1, GP2 (for getting single pin)"""

    def test_get_pins_return_non_empty_list_200(self, client):
        """Expect a non-empty list and status 200"""
        rg = client.get("/pins")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        assert len(data) > 0

    def test_get_pins_when_authenticated_200(self, client, auth_headers):
        """Expect a non-empty list and status 200"""
        rg = client.get("/pins", headers=auth_headers)
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        assert len(data) > 0

    def test_pins_has_minimal_information_200(self, client):
        """Title, timestamp, category, location"""
        rg = client.get("/pins")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        assert len(data) > 0
        pin = data[0]
        assert pin["pin_title"] is not None
        assert pin["pin_latitude"] is not None
        assert pin["pin_longitude"] is not None
        assert pin["pin_city"] is not None
        assert pin["pin_street"] is not None
        assert pin["cat_id"] is not None
        assert pin["created_at"] is not None

    def test_pins_has_engagement_statistics_200(self, client):
        """Likes and dislikes"""
        rg = client.get("/pins")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        assert len(data) > 0
        pin = data[0]

        assert pin["pin_likes"] is not None
        assert pin["pin_likes"] >= 0

        assert pin["pin_dislikes"] is not None
        assert pin["pin_dislikes"] >= 0

    def test_pin_user_reaction_is_none_when_not_reacted_200(self, client, auth_headers):
        """User reaction should be null if user hasn't reacted"""
        rg = client.get("/pins", headers=auth_headers)
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        pin = data[0]

        assert pin["user_reaction"] is None

    def test_pin_user_reaction_set_after_reacting_200(self, client, auth_headers):
        """User reaction should be the user's id"""
        rg = client.get("/pins", headers=auth_headers)
        assert rg.status_code == 200

        data = rg.json()
        pin = data[0]

        # create a reaction for the pin
        rp = client.patch(f"/pins/{pin['pin_id']}/react", headers=auth_headers, json={"value": 1})  # like the pin
        assert rp.status_code in (200, 201)

        pin = client.get(f"/pins/{pin['pin_id']}", headers=auth_headers)
        assert pin.status_code == 200
        data = pin.json()
        assert data["user_reaction"] == 1

    def test_pin_filter_by_cat_id_only_returns_with_cat_id_200(self, client):
        """Pins should only return the given category id"""
        rg = client.get(f"/pins?cat_id=1")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        invalid_found = 0  # keep track if any is invalid
        for pin in data:
            if pin["cat_id"] == 1:
                continue
            else:
                invalid_found += 1

        assert invalid_found == 0

    def test_pin_filter_by_multiple_categories200(self, client):
        """Pins should only return the given category ids"""
        rg = client.get(f"/pins?cat_id=1&cat_id=2")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        invalid_found = 0  # keep track if any is invalid
        for pin in data:
            if pin["cat_id"] == 1 or pin["cat_id"] == 2:
                continue
            else:
                invalid_found += 1

        assert invalid_found == 0

    def test_pin_filter_by_expire_at_only_returns_less_than_or_equal_to_date_200(self, client):
        """Each pin's expire at should be less or equal to given date"""
        rg = client.get(f"/pins?pin_expire_at=2026-05-20")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        invalid_found = 0  # keep track if any is invalid
        for pin in data:
            if pin["pin_expire_at"] <= '2026-05-20T23:59:59':
                continue
            else:
                invalid_found += 1

        assert invalid_found == 0

    def test_pin_filter_by_invalid_cat_id_200(self, client):
        """Pin filter by non-existent cat id"""
        rg = client.get(f"/pins?cat_id=9999")
        assert rg.status_code == 200

        data = rg.json()
        assert data is not None
        assert len(data) == 0

    def test_get_valid_pin_by_id_200(self, client):
        """Get a single pin by id"""
        rg = client.get("/pins/2")
        assert rg.status_code == 200
        data = rg.json()
        assert data is not None
        assert data["pin_id"] == 2

    def test_get_invalid_pin_by_id_404(self, client):
        """Get a pin by invalid id"""
        rg = client.get("/pins/9999")
        assert rg.status_code == 404