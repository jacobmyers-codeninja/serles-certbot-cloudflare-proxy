[serles]
database = sqlite://///data/serles/db.sqlite

backend = serles.backends.certbot

allowedServerIpRanges =
	$FORMATTED_ALLOWED_IPS
excludeServerIpRanges =
	$FORMATTED_DENIED_IPS

verifyPTR = $VERIFY_PTR

subjectNameTemplate = CN={SAN[0]}

forceTemplateDN = true

[certbot]

config-file = /data/certbot/serles.ini
