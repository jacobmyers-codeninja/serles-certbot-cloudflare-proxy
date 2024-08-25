[serles]
database = sqlite://///data/serles/db.sqlite

backend = serles.backends.certbot

allowedServerIpRanges =
	${FORMATTED_ALLOWED_IPS}
excludeServerIpRanges =
	${FORMATTED_DENIED_IPS}

verifyPTR = ${VERIFY_PTR}

subjectNameTemplate = CN={SAN[0]}

forceTemplateDN = true

[certbot]

config =
    agree-tos
    email=${EMAIL}
    preferred-challenges=dns
    dns-cloudflare
    dns-cloudflare-credentials=/data/certbot/config/cloudflare-credentials.ini
    config-dir=/data/certbot/config
    work-dir=/data/certbot/work
    logs-dir=/data/certbot/logs