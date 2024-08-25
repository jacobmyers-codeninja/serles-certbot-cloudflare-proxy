#!/usr/bin/env python3

"""Check if server is up"""

from sys import exit as sys_exit

from requests import get

if not get("http://127.0.0.1:8080/", timeout=3).ok:
    sys_exit(1)