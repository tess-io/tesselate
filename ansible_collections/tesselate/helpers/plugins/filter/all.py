from __future__ import (absolute_import, division, print_function)


__metaclass__ = type


from ansible.module_utils.common.text.converters import (
    to_text,
)


def extract(map, keys):
    return { key : value for key, value in map.items() if key in keys }


def format(map, str):
    return to_text(str.format(**map))


def to_dict(obj, key, attrs={}):
    return { key: obj } | attrs


class FilterModule:
    def filters(self):
        return {
            'extract': extract,
            'format': format,
            'to_dict': to_dict,
        }
