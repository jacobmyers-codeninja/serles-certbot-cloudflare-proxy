#!/bin/bash

set -e
#python3 /usr/local/sbin/configure.py
mkdir -p /data/serles/db/
chmod 775 /data/serles/db/
chown -R nobody:nogroup /data/serles/*
mkdir -p /data/certbot/{config,work,log}
chown -R nobody:nogroup /data/certbot/*

runuser -u nobody -- /opt/serles/bin/gunicorn -c /opt/serles/gunicorn_config.py "serles:create_app()"