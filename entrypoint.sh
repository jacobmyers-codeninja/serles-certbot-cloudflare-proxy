#!/bin/sh

set -e
export FORMATTED_ALLOWED_IPS=`echo -n ${ALLOWED_IPS} | sed 's/,/\n\t/g'`
export FORMATTED_DENIED_IPS=`echo -n ${DENIED_IPS} | sed 's/,/\n\t/g'`

cat /opt/serles/config.ini.tpl | envsubst > /data/serles/config.ini

cat /data/serles/config.ini

if [ -n "${RESOLV_CONF}" ]; then
    echo "${RESOLV_CONF}" > /etc/resolv.conf
fi

mkdir -p /data/certbot/config
mkdir -p /data/certbot/work
mkdir -p /data/certbot/log
chown -R nobody:nogroup /data/serles
chown -R nobody:nogroup /data/serles/*
chown -R nobody:nogroup /data/certbot
chown -R nobody:nogroup /data/certbot/*

runuser -u nobody -- /opt/serles/bin/gunicorn -c /opt/serles/gunicorn_config.py "serles:create_app()"