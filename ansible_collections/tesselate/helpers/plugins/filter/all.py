from __future__ import (absolute_import, division, print_function)


__metaclass__ = type


from ansible.module_utils.common.text.converters import (
    to_text,
)


def extract(map, keys):
    return { key : value for key, value in map.items() if key in keys }


def format(str, map):
    return to_text(str.format(**map))


class FilterModule:
    def filters(self):
        return {
            'extract': extract,
            'format': format,
        }
