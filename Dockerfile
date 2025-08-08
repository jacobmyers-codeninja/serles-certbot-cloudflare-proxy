FROM alpine

ENV EMAIL=
ENV ALLOWED_IPS=::1/128,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/16
ENV DENIED_IPS=127.0.0.2/32
ENV VERIFY_PTR=true
ENV CONFIG=/data/serles/config.ini
ENV RESOLV_CONF=

EXPOSE 8080

VOLUME /data/certbot
VOLUME /data/serles

RUN apk add --update python3 py3-pip certbot certbot-dns-cloudflare envsubst runuser
RUN python3 -m venv /opt/serles &&\
    . /opt/serles/bin/activate &&\
    python3 -m pip install --quiet --no-cache-dir --upgrade pip setuptools &&\
    python3 -m pip install --quiet --no-cache-dir serles-acme==1.1.0

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.py /healthcheck.py
COPY gunicorn_config.py /opt/serles/gunicorn_config.py
COPY config.ini.tpl /opt/serles/config.ini.tpl

HEALTHCHECK --timeout=3s CMD [ "/opt/serles/bin/python3", "/healthcheck.py" ]

ENTRYPOINT [ "sh", "/entrypoint.sh" ]
