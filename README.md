Important note on security. The threat model used here is that this is an internal, protected, unexposed service within a private locked down network.

Aside from some primitive IP checks and PTR verification there is no security, no encryption, no protection provided. Ensure you properly protect the service so only authorized systems and applications can access it, protect its filesystem data from external access, etc. This is just a gunicorn flask app, it is not bulletproof. Good enough for experimenting, hobby work, testing, etc. I wouldn't protect a bank or launch codes with it.

Most of the setup is controlled via environment variables to make it easy to deploy and use. It comes pre-configured for cloudflare so you only need to provide the api key in a file in the certbot volume. This could be done via a secret file or other process as well if desired.

Environment Variables:

- EMAIL: Email for certbot account registration<br>
Default: 

- ALLOWED_IPS:  CSV list of allowed IP CIDRs<br>
Default: ::1/128,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/16

- DENIED_IPS: CSV list of denied IP CIDRs<br>
Default: 127.0.0.2/32

- VERIFY_PTR: true to require a valid PTR for request<br>
Default: true

- CONFIG: Path to fully custom config.ini for serles if not using ENV vars<br>
Default: /data/serles/config.ini

- RESOLV_CONF: Content to write to /etc/resolv.conf (ie: nameserver 1.1.1.1)<br>
Default:

- CERTBOT_CONF: Contents to append to the certbot config, default uses cloudflare simple config<br>
Default: preferred-challenges=dns\n\
dns-cloudflare\n\
dns-cloudflare-credentials=/data/certbot/config/cloudflare-credentials.ini

- FQDN: Fully qualified domain name for the server to enable HTTPS mode<br>
Default: 

- CERT_NAME: Certificate name to use for certbot when using automatic HTTPS, default should be fine<br>
Default: serles

- CERT_FILE: Path to a custom SSL certificate file (PEM). If not set, ACME will be used<br>
Default:

- KEY_FILE: Path to the private key for CERT_FILE<br>
Default:

If no CERT_FILE is provided, the system will use certbot to attempt to obtain a certificate automatically.

Load your cloudflare certbot credentials into the named certbot volume under config/cloudflare-credentials.ini

To deal with potential split horizon DNS you can override the dns servers through resolv.conf by setting the contents in RESOLV_CONF

Docker:
```
docker run  --name acme-proxy \
            -v certbot:/data/certbot \
            -v serles:/data/serles \
            -e EMAIL=my@email.com \
            -e RESOLV_CONF="nameserver 1.1.1.1" \
            -p 80:9000 \
            jacobmyers42/serles-certbot-cloudflare-proxy
```

Docker (with automatic https):
```
docker run  --name acme-proxy \
            -v certbot:/data/certbot \
            -v serles:/data/serles \
            -e EMAIL=my@email.com \
            -e RESOLV_CONF="nameserver 1.1.1.1" \
            -e FQDN="acme-proxy.your-domain.com" \
            -p 443:9000 \
            jacobmyers42/serles-certbot-cloudflare-proxy
```

With labels for traefik (if not using the built-in acme):
```
docker run  --name acme-proxy \
            -v certbot:/data/certbot \
            -v serles:/data/serles \
            -e EMAIL=my@email.com \
            -e RESOLV_CONF="nameserver 1.1.1.1" \
            -p 8080:9000 \
            -l "traefik.enable=true" \
            -l "traefik.http.routers.serles-web.entrypoints=web" \
            -l "traefik.http.routers.serles-web.rule=Host(`acme-proxy.your-domain.com`)" \
            -l "traefik.http.routers.serles.entrypoints=websecure" \
            -l "traefik.http.routers.serles.rule=Host(`acme-proxy.your-domain.com`)" \
            -l "traefik.http.routers.serles.tls.certresolver=leproxy" \
            jacobmyers42/serles-certbot-cloudflare-proxy
```

Traefik frontend to provide the tls support to self LE the proxy:
```
version: "3.3"

services:
  traefik:
    image: "traefik:v3.1"
    container_name: "traefik"
    command:
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entryPoints.web.address=:80"
      - "--entryPoints.websecure.address=:443"
      - "--certificatesresolvers.leproxy.acme.httpchallenge=true"
      - "--certificatesresolvers.leproxy.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.leproxy.acme.caserver=http://acme-proxy/directory"
      - "--certificatesresolvers.leproxy.acme.email=email@address.com"
      - "--certificatesresolvers.leproxy.acme.storage=/letsencrypt/acme.json"
    labels:
      - "traefik.enable=true"  
      - "traefik.http.routers.traefik_https.rule=Host(`traefik.your-domain.com`)"
      - "traefik.http.routers.traefik_https.entrypoints=websecure"
      - "traefik.http.routers.traefik_https.tls=true"
      - "traefik.http.routers.traefik_https.tls.certResolver=leproxy"
      - "traefik.http.routers.traefik_https.service=api@internal"
      - "traefik.http.routers.http_traefik.rule=Host(`traefik.your-domain.com`)"
      - "traefik.http.routers.http_traefik.entrypoints=web"
      - "traefik.http.routers.http_traefik.middlewares=https_redirect"
      - "traefik.http.middlewares.https_redirect.redirectscheme.scheme=https"
      - "traefik.http.middlewares.https_redirect.redirectscheme.permanent=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - letsencrypt:/letsencrypt
    network_mode: bridge

volumes:
  letsencrypt:

networks:
  default:
    external: true
    name: none
```
