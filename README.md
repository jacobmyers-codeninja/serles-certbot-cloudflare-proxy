| Env Vars    | Default                                                     | Notes                                                            |
| ----------- | ----------------------------------------------------------- | ---------------------------------------------------------------- |
| EMAIL       | <none>                                                      | Email for certbot account registration                           |
| ALLOWED_IPS | ::1/128,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/16 | CSV list of allowed IP CIDRs                                     |
| DENIED_IPS  | 127.0.0.2/32                                                | CSV list of denied IP CIDRs                                      |
| VERIFY_PTR  | true                                                        | true to require a valid PTR for request                          |
| CONFIG      | /data/serles/config.ini                                     | path to fully custom config.ini for serles if not using ENV vars |

Load cloudflare certbot credentials into the named certbot volume under config/cloudflare-credentials.ini

Docker:
```
docker run  --name acme-proxy \
            -v certbot:/data/certbot \
            -v serles:/data/serles \
            -p 8080:8080 \
            jacobmyers42/serles-certbot-cloudflare-proxy
```
With labels for traefik:
```
docker run  --name acme-proxy \
            -v certbot:/data/certbot \
            -v serles:/data/serles \
            -p 8080:8080 \
            -l "traefik.enable=true" \
            -l "traefik.http.routers.serles-web.entrypoints=web" \
            -l "traefik.http.routers.serles-web.rule=Host(`acme-proxy.your-domain.com`)" \
            -l "traefik.http.routers.serles.entrypoints=websecure" \
            -l "traefik.http.routers.serles.rule=Host(`acme-proxy.your-domain.com`)" \
            -l "traefik.http.routers.serles.tls.certresolver=leproxy" \
            jacobmyers42/serles-certbot-cloudflare-proxy-l
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
