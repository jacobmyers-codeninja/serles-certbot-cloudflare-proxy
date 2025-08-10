#!/usr/bin/env python3

# pylint: disable=invalid-name

"""Gunicorn configuration"""

accesslog = "-"
disable_redirect_access_to_syslog = True
forwarded_allow_ips = "*"
workers = 1
bind = "0.0.0.0:9000"
$GUNICORN_CERT_FILE
$GUNICORN_KEY_FILE
