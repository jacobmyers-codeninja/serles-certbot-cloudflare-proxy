#!/bin/sh

# Quick bootstrapping for testing
# Normally do something like: ./build.sh && ./test.sh

docker stop acme-proxy
docker rm acme-proxy

docker run -d --name acme-proxy \
           --restart=no \
           --env-file .env \
           -v ./certbot:/data/certbot \
           -v ./serles:/data/serles \
           -p 9000:9000 \
           sccp:test