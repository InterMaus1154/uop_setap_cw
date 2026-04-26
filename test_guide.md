# Python test guide

In this guide I will explain how to test our API using `pytest`.

Useful resources:
- [https://docs.pytest.org/en/stable/how-to/assert.html](https://docs.pytest.org/en/stable/how-to/assert.html)
- [https://www.w3schools.com/python/ref_keyword_assert.asp](https://www.w3schools.com/python/ref_keyword_assert.asp)
- [https://fastapi.tiangolo.com/tutorial/testing/#extended-fastapi-app-file](https://fastapi.tiangolo.com/tutorial/testing/#extended-fastapi-app-file)

## Where are the test files located?

Tests are defined under `backend/tests`. Each test file starts with `test_*.py`, so pytest can discover them automatically.\
Tests that are under the same category are better under a class.\
The `base` is the base client we use to do HTTP requests to our own API.

## How to run tests?

In the backend folder (under the virtual environment) if you run `pytest` it will run all tests in the `tests/` folder. If you add the `-v` flag, it will give more details. Optionally, you can run an individual file, for example: `pytest -v tests/test_auth.py`.

## How to write tests

### How to write basic tests
A test is simply a function (or method in a class) that:
- sends a request to an endpoint
- checks the response using the `assert` keyword


Example (test_demo.py):
```python
import pytest
from base import client

class TestDemo:
    def test_index(self):
        response = client.get("/") # we call the {host}/ endpoint
        data = response.json() # we get the json, as our api uses json to send data

        assert response.status_code == 200 # we assert that status code is 200
        assert "message" in data # we assert that the data object contains a message key
        assert data["message"] == "test" # we assert that the message in data is equal to test
        # if all of the above passes, the test_index test will pass as well, otherwise fail

```

Basic example (using just functions without a class, `test_showcase.py`):

```python
def test_greater():
    assert 4 > 3
```

And to show what happens if a test fails:
```python

def test_fail_on_purpose():
    assert 3 > 4
```

With assert, we basically say "this xzy should be abc", we assume something, and the test will return pass if that is true, and failed if that is false. We can assert basically everything.

For debugging, you can use print as usually, for example `print(response.status_code)`. It is useful if you think your test should've passed, but it did not. 

**Note:** printing by default only works for failed tests, if you want to use it for passed tests for debugging, add the `-s` flag when running pytest.

### Tests with authentication

Some of our endpoints require authentication. For this, there is a `auth_headers` in `backend/conftest.py`, that uses a token of a test user (it lives in our database). Anything that lives in `conftest.py` can be passed as a parameter without manually importing it.

```python

from base import client
def test_logout_with_valid_token(auth_headers): # pytest will resolve the headers from our conftest.py file
    response = client.post("/auth/logout", headers=auth_headers) # we pass the headers to the request

    assert response.status_code == 200
```

For more example for authentication, consult the `test_auth.py`.

## Important notes for tests

Each of our test should have an entry in the testplan (on onedrive). Always test with invalid data as well.\
Each test should be independent, do not assume other test ran before it.