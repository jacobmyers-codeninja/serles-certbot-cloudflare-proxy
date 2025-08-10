#!/bin/sh

set -e
export FORMATTED_ALLOWED_IPS=`echo -n $ALLOWED_IPS | sed 's/,/\n\t/g'`
export FORMATTED_DENIED_IPS=`echo -n $DENIED_IPS | sed 's/,/\n\t/g'`

cat /opt/serles/config.ini.tpl | envsubst | sed 's/\\n/\n/g' > /data/serles/config.ini

echo "---------------------------"
echo "Serles Config: /data/serles/config.ini"
echo "---------------------------"
cat /data/serles/config.ini
echo "---------------------------"
echo

cat /opt/serles/certbot.ini.tpl | envsubst | sed 's/\\n/\n/g' > /data/certbot/serles.ini

echo "---------------------------"
echo "Certbot Config: /data/certbot/serles.ini"
echo "---------------------------"
cat /data/certbot/serles.ini
echo "---------------------------"
echo

if [ -n "$RESOLV_CONF" ]; then
    echo -e "$RESOLV_CONF" > /etc/resolv.conf
fi

mkdir -p /data/certbot/config
mkdir -p /data/certbot/work
mkdir -p /data/certbot/logs
chown -R nobody:nogroup /data/serles
chown -R nobody:nogroup /data/certbot
chmod -R 700 /data/serles
chmod -R 700 /data/certbot

# If we are in managed certificate mode
if [ ! -z $FQDN ]; then
  echo "Managed cert mode, initializing..."

  # Mark that we are currently initializing
  touch /initializing

  # If CERT_FILE is empty default to /data/serles/serles-cert.pem
  if [ ! -z $CERT_FILE ] && [ -z $KEY_FILE ]; then
    # Provided a cert without a key
    echo "CERT_FILE was provided, but missing necessary KEY_FILE"

    exit 1
  fi

  # Validate the cert, generate/refresh if needed
  set +e
  sh /check-cert.sh

  EXIT_CODE=$?
  set -e

  # Error 7 indicates a cert was fetched or renewed which is fine, 0 indicates no error
  # anything else is unknown
  if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 7 ]; then
    echo "Unknown error occured ($EXIT_CODE)"

    exit $EXIT_CODE
  fi

  # If we still don't have a cert something went wrong, sleep for 90 seconds
  if [ ! -f $CERT_FILE ]; then
    echo "Cert was not generated, sleeping 90 seconds and then failing..."
    echo "If this is happening more than once be careful or you may be using up requests!"

    sleep 90
    exit 1
  fi

  # Touch up the hosts file so attempting to connect to FQDN will point to local
  echo "127.0.0.3 $FQDN" >> /etc/hosts

  echo "Initializing complete!"
  
  # Done initializing
  rm /initializing
else
  # No cert mode, just do normal http
  export PORT=8080

  cat /opt/serles/gunicorn_config.py.tpl | envsubst > /opt/serles/gunicorn_config.py
fi

echo "---------------------------"
echo "Gunicorn Config: /opt/serles/gunicorn_config.py"
echo "---------------------------"
cat /opt/serles/gunicorn_config.py
echo "---------------------------"
echo

echo "Starting gunicorn server..."

runuser -u nobody -- /opt/serles/bin/gunicorn -p /data/serles/gunicorn.pid \
                                              -c /opt/serles/gunicorn_config.py \
                                              "serles:create_app()"