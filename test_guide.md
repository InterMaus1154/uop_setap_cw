# Python test guide

In this guide I will explain how to test our API using `pytest`.

Useful resources:

* [Pytest Assertions Guide](https://docs.pytest.org/en/stable/how-to/assert.html?utm_source=chatgpt.com)
* [Python assert keyword (W3Schools)](https://www.w3schools.com/python/ref_keyword_assert.asp?utm_source=chatgpt.com)
* [FastAPI Testing Guide](https://fastapi.tiangolo.com/tutorial/testing/?utm_source=chatgpt.com#extended-fastapi-app-file)
* [Pytest Fixtures Documentation](https://docs.pytest.org/en/stable/explanation/fixtures.html?utm_source=chatgpt.com)

## Where are the test files located?

Tests are defined under `backend/tests`. Each test file starts with `test_*.py`, so pytest can discover them automatically.

Tests that are under the same category are better grouped under a class.

We use a shared `client` fixture to send HTTP requests to our API.

---

# How to run tests?

In the backend folder (under the virtual environment), running:

```bash
pytest
```

will run all tests inside the `tests/` folder.

Useful flags:

```bash
pytest -v
```

Verbose output.

```bash
pytest -s
```

Allows `print()` output even for passing tests.

```bash
pytest -v tests/test_auth.py
```

Runs a single file.

```bash
pytest -v tests/test_auth.py::TestAuth
```

Runs a single class.

```bash
pytest -v tests/test_auth.py::TestAuth::test_login
```

Runs a single test.

---

# How to write tests

## How to write basic tests

A test is simply a function (or a method inside a class) that:

* sends a request to an endpoint
* checks the response using `assert`

Example (`test_demo.py`):

```python
class TestDemo:
    def test_index(self, client):
        response = client.get("/")
        data = response.json()

        assert response.status_code == 200
        assert "message" in data
        assert data["message"] == "test"
```

Basic example using just functions (`test_showcase.py`):

```python
def test_greater():
    assert 4 > 3
```

Example of a failing test:

```python
def test_fail_on_purpose():
    assert 3 > 4
```

With `assert`, we basically say:

> "this should equal/be something"

If the assertion is true, the test passes. Otherwise, it fails.

You can assert almost anything:

* status codes
* JSON fields
* list lengths
* database values
* object types
* boolean values

Example:

```python
assert isinstance(data, list)
assert len(data) == 0
assert user.email == "test@test.com"
```

---

# Using fixtures

Fixtures are one of the most important concepts in pytest.

A fixture is reusable setup code that pytest automatically provides to tests.

Fixtures are defined in `conftest.py`.

You do **not** import fixtures manually.
Instead, you add them as parameters to your test function.

Example:

```python
def test_example(client, auth_headers):
    response = client.get("/users/me", headers=auth_headers)

    assert response.status_code == 200
```

Pytest automatically detects:

* `client`
* `auth_headers`

and injects them into the test.

---

# Our current fixtures

## `client`

Creates a FastAPI `TestClient`.

It also overrides the database dependency so tests use the test transaction/session.

```python
def test_index(client):
    response = client.get("/")

    assert response.status_code == 200
```

---

## `db_session`

Provides a database session for direct database operations inside tests.

Each test gets its own transaction, and changes are rolled back afterwards.

This means tests stay isolated from each other.

Example:

```python
def test_create_user(db_session):
    user = User(
        user_fname="Test",
        user_lname="User",
        user_email="test@test.com",
        user_token="token123"
    )

    db_session.add(user)
    db_session.flush()

    assert user.user_id is not None
```

---

## `auth_headers`

Provides authentication headers for the main test user.

```python
def test_protected_route(client, auth_headers):
    response = client.get(
        "/protected",
        headers=auth_headers
    )

    assert response.status_code == 200
```

Internally, it returns:

```python
{
    "Authorization": "Bearer <token>"
}
```

---

## `main_user`

Returns the main test user object from the database.

Useful if you need the user's ID or other fields.

```python
def test_user(main_user):
    assert main_user.user_email is not None
```

---

## `alt_user` and `alt_auth_headers`

Used when tests require a second authenticated user.

Example:

```python
def test_two_users(client, auth_headers, alt_auth_headers):
    response1 = client.get("/users/me", headers=auth_headers)
    response2 = client.get("/users/me", headers=alt_auth_headers)

    assert response1.status_code == 200
    assert response2.status_code == 200
```

---

# Fixture scopes and cleanup

Fixtures can also handle setup and cleanup automatically using `yield`.

Example from our `db_session` fixture:

```python
@pytest.fixture
def db_session():
    connection = engine.connect()
    transaction = connection.begin()

    session = Session(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()
```

Code before `yield`:

* setup

Code after `yield`:

* cleanup

This is extremely useful for:

* database transactions
* temporary files
* mock servers
* patching external services

---

# Autouse fixtures

Some fixtures should run automatically without being passed into every test.

Example:

```python
@pytest.fixture(autouse=True)
def mock_externals():
    yield
```

`autouse=True` means pytest runs it automatically for every test in that scope.

Example from our project:

```python
@pytest.fixture(autouse=True)
def mock_externals(self):
    with patch(
        "routes.user_locations._reverse_geocode",
        return_value={"city": "Portsmouth", "street": "Commercial Road"},
    ), patch("routes.user_locations.redis_client") as mock_redis:

        mock_redis.hgetall.return_value = {}

        yield mock_redis
```

This automatically:

* mocks reverse geocoding
* mocks Redis
* prevents real external calls during tests

without repeating the patching code in every test.

---

# Example: helper methods inside test classes

You can create helper methods inside test classes to avoid duplicate code.

Example:

```python
class TestLocationPermissions:
    def _create_friend(self, db_session, main_user):
        friend = User(
            user_fname="Friend",
            user_lname="User",
            user_email="friend@test.com",
            user_token="friendtoken"
        )

        db_session.add(friend)
        db_session.flush()

        return friend
```

This is useful for:

* creating test users
* creating relationships
* creating reusable test data

---

# Example: authenticated endpoint test

```python
class TestLocationPermissions:
    def test_location_permissions(self, client, auth_headers):
        response = client.get(
            "/location-permissions/",
            headers=auth_headers
        )

        assert response.status_code == 200
        assert isinstance(response.json(), list)
```

---

# Example: testing invalid authentication

Always test invalid and unauthorized access as well.

```python
def test_invalid_auth(client):
    response = client.get("/location-permissions/")
    assert response.status_code == 401

    response = client.get(
        "/location-permissions/",
        headers={"Authorization": "Bearer invalid"}
    )

    assert response.status_code == 401
```

---

# Example: validating returned JSON

```python
data = response.json()

assert "user_id" in data
assert "created_at" in data
assert isinstance(data["user_id"], int)
```

---

# Database validation after requests

Sometimes we should verify the database state directly.

Example:

```python
permission = db_session.query(LocationPermission)\
    .filter_by(loc_perm_id=permission_id)\
    .first()

assert permission is None
```

This verifies that the API actually deleted the database record.

---

# Mocking external services

We often mock:

* Redis
* geocoding
* external APIs
* email sending

This keeps tests:

* fast
* deterministic
* independent of internet/services

Example:

```python
with patch("routes.user_locations.redis_client") as mock_redis:
    mock_redis.hgetall.return_value = {}
```

---

# Important notes for tests

Each test should:

* have a matching entry in the test plan
* test both valid and invalid data
* be independent from other tests

Do not assume:

* another test already ran
* database state exists
* records already exist unless your test creates them

Good tests are:

* isolated
* repeatable
* deterministic
* easy to understand
