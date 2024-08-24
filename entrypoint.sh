#!/bin/bash

set -e
#python3 /usr/local/sbin/configure.py
mkdir -p /data/certbot/config
mkdir -p /data/certbot/work
mkdir -p /data/certbot/log
chown -R nobody:nogroup /data/serles
chown -R nobody:nogroup /data/serles/*
chown -R nobody:nogroup /data/certbot
chown -R nobody:nogroup /data/certbot/*

runuser -u nobody -- /opt/serles/bin/gunicorn -c /opt/serles/gunicorn_config.py "serles:create_app()"