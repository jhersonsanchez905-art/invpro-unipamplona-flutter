#!/usr/bin/env python
"""
InvPro management script.
"""

import sys


def main():
    """Run administrative tasks."""
    from django.core.management import execute_from_command_line

    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
