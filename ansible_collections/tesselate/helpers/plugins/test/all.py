from __future__ import (
    absolute_import,
    division,
    print_function
)


__metaclass__ = type


def empty(value):
    return len(value) == 0


class TestModule:
    def tests(self):
        return {
            'empty': empty,
        }
