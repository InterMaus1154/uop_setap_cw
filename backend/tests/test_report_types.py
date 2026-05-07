

class TestReportTypes:
    def test_get_report_types(self, client):
        """Test getting the report types"""
        response = client.get("/pins/report-types")
        assert response.status_code == 200
        data = response.json()



