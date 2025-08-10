#!/bin/sh

set -e

# If CERT_FILE is empty default to /serles/self-cert.pem
if [ -z $CERT_FILE ]; then
  export AUTO_CERT_FILE=true
  export CERT_FILE=/data/certbot/config/live/$CERT_NAME/fullchain.pem
  export KEY_FILE=/data/certbot/config/live/$CERT_NAME/privkey.pem
  export GUNICORN_CERT_FILE="certfile = \"$CERT_FILE\""
  export GUNICORN_KEY_FILE="keyfile = \"$KEY_FILE\""
fi

# Generate gunicorn config if its missing
if [ ! -f /opt/serles/gunicorn_config.py ]; then
  cat /opt/serles/gunicorn_config.py.tpl | envsubst > /opt/serles/gunicorn_config.py
fi

# If no FQDN is provided we assume no cert is being used, so nothing more to do
if [ -z $FQDN ]; then
  exit
fi

echo "Validating certificate $CERT_FILE..."

EXIT_CODE=0

# If the cert file is missing, exit 11
if [ ! -f $CERT_FILE ]; then
  echo "Cert file doesn't exist!"

  EXIT_CODE=11
else
  # If the domain in $FQDN does not match the CN in the cert then exit 12
  CERT_FQDN=$(openssl x509 -in $CERT_FILE -noout -subject | sed -n 's/.*CN *= *\([^,]*\).*/\1/p')

  if [ "$FQDN" != "$CERT_FQDN" ]; then
    echo "FQDN on cert ($CERT_FQDN) does not match given FQDN ($FQDN)"

    EXIT_CODE=12
  else
    NOT_BEFORE=$(openssl x509 -in "$CERT_FILE" -noout -startdate | cut -d= -f2)
    NOT_AFTER=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
    NOT_BEFORE_EPOCH=$(date -uD "%b %e %H:%M:%S %Y" -d "$NOT_BEFORE" +%s)
    NOT_AFTER_EPOCH=$(date -uD "%b %e %H:%M:%S %Y" -d "$NOT_AFTER" +%s)
    NOW_EPOCH=$(date +%s)

    # If the current date is not between notBefore and notAfter then exit 13
    if [ "$NOW_EPOCH" -lt "$NOT_BEFORE_EPOCH" ] || [ "$NOW_EPOCH" -gt "$NOT_AFTER_EPOCH" ]; then
      echo "Certificate is not currently valid $NOT_BEFORE_EPOCH <= $NOW_EPOCH <= $NOT_AFTER_EPOCH"

      EXIT_CODE=13
    fi
  fi
fi

# If the exit code is 11, 12, or 13 we need to try to get one
if [ $EXIT_CODE -eq 11 ] || [ $EXIT_CODE -eq 12 ] || [ $EXIT_CODE -eq 13 ]; then
  # If they provided the cert we can't fix it
  if [ -z $AUTO_CERT_FILE ]; then
    echo "Cert failed validation and it was manually provided, stopping."
    echo "Please provide a cert with the proper FQDN ($FQDN) and not expired."

    exit 11
  fi

  echo "Cert is missing, expired, or invalid. Removing it and refreshing..."

  [ -f $CERT_FILE ] && "Removing $CERT_FILE" && rm $CERT_FILE 

  echo "Running certbot..."
  # Try to get a cert through certbot
  runuser -u nobody -- /usr/bin/certbot certonly \
                       --non-interactive \
                       --config /data/certbot/serles.ini \
                       --cert-name $CERT_NAME \
                       -d $FQDN
  echo "Certbot completed!"

  # Let them know we got or refreshed a cert
  exit 7
fi

exit 0