FROM alpine

ENV CONFIG=/data/serles/config.ini

EXPOSE 8080

VOLUME [ "/data/certbot" "/data/serles" ]

RUN apk add --update python3 py3-pip certbot certbot-dns-cloudflare runuser
RUN python3 -m venv /opt/serles &&\
    . /opt/serles/bin/activate &&\
    python3 -m pip install --quiet --no-cache-dir --upgrade pip setuptools &&\
    python3 -m pip install --quiet --no-cache-dir serles-acme==1.1.0

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.py /healthcheck.py
COPY gunicorn_config.py /opt/serles/gunicorn_config.py
COPY config.ini /data/serles/config.ini
ENTRYPOINT [ "sh", "/entrypoint.sh" ]
HEALTHCHECK --timeout=3s CMD [ "/opt/serles/bin/python3", "/healthcheck.py" ]
