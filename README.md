| Env Vars    | Default                                                     | Notes                                                            |
| ----------- | ----------------------------------------------------------- | ---------------------------------------------------------------- |
| EMAIL       | <none>                                                      | Email for certbot account registration                           |
| ALLOWED_IPS | ::1/128,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/16 | CSV list of allowed IP CIDRs                                     |
| DENIED_IPS  | 127.0.0.2/32                                                | CSV list of denied IP CIDRs                                      |
| VERIFY_PTR  | true                                                        | true to require a valid PTR for request                          |
| CONFIG      | /data/serles/config.ini                                     | path to fully custom config.ini for serles if not using ENV vars |

Load cloudflare certbot credentials into the named certbot volume under config/cloudflare-credentials.ini

Docker:
`docker run --name acme-proxy -v certbot:/data/certbot -v serles:/data/serles -p 8080:8080 jacobmyers42/serles-certbot-cloudflare-proxy`
