from pytest import mark

from ansible_collections.tesselate.helpers.plugins.filter import (
    extract,
    format,
    to_dict,
)


@mark.parametrize(['map', 'keys'],
    [
        ({'first_key': 'first_value', 'second_key': 'second_value', 'third_key': 'third_value'}, ['first_key', 'second_key']),
    ])
def test_extract(map, keys):
    rt = extract(map, keys)
    for key in keys:
        assert key in rt
        assert map[key] == rt[key]


@mark.parametrize(['str', 'map', 'expected'],
    [
        ('{first_key}:{second_key}', {'first_key': 'first_value', 'second_key': 'second_value'}, 'first_value:second_value')
    ])
def test_format(str, map, expected):
    actual = format(map, str)
    assert actual == expected


@mark.parametrize(['obj', 'key', 'attrs', 'expected'],
    [
        (1, "pos", { "prop_1" : "prop_1_v" }, { "pos" : 1, "prop_1" : "prop_1_v" }),
        ("str", "name", {}, { "name" : "str" } ),
    ])
def test_to_dict(obj, key, attrs, expected):
    assert to_dict(obj, key, attrs) == expected
