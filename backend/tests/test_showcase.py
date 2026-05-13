import pytest

def test_greater():
    assert 4 > 3

def test_fail_on_purpose():
    print("this will fail:(")
    assert 3 > 4