from pytest import mark

from ansible_collections.tesselate.helpers.plugins.test import (
    empty,
)


@mark.parametrize(['value', 'expected'],
    [
        ("text", False),
        ("", True),
        ([1, 2], False),
        ([], True),
    ])
def test_empty(value, expected):
    assert empty(value) == expected
