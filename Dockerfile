FROM alpine

ENV EMAIL=
ENV ALLOWED_IPS=::1/128,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/16
ENV DENIED_IPS=127.0.0.2/32
ENV VERIFY_PTR=true
ENV CONFIG=/data/serles/config.ini
ENV FQDN=
ENV CERT_FILE=
ENV KEY_FILE=
ENV CERT_NAME=serles
ENV RESOLV_CONF=
ENV CERTBOT_CONF="preferred-challenges=dns\n\
dns-cloudflare\n\
dns-cloudflare-credentials=/data/certbot/config/cloudflare-credentials.ini"

EXPOSE 9000

VOLUME /data/certbot
VOLUME /data/serles

RUN apk add --update python3 py3-pip certbot certbot-dns envsubst runuser openssl
RUN python3 -m venv /opt/serles &&\
    . /opt/serles/bin/activate &&\
    python3 -m pip install --quiet --no-cache-dir --upgrade pip setuptools &&\
    python3 -m pip install --quiet --no-cache-dir serles-acme==1.1.0

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/healthcheck.sh /healthcheck.sh
COPY scripts/check-cert.sh /check-cert.sh
COPY configs/gunicorn_config.py.tpl /opt/serles/gunicorn_config.py.tpl
COPY configs/serles-config.ini.tpl /opt/serles/config.ini.tpl
COPY configs/serles-certbot.ini.tpl /opt/serles/certbot.ini.tpl

HEALTHCHECK --interval=5m --timeout=1m --retries=3 --start-period=2m CMD [ "/bin/sh", "/healthcheck.sh" ]

ENTRYPOINT [ "sh", "/entrypoint.sh" ]
