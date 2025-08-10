#!/bin/bsh

set -e

# If previous health check is running due to slow certbot give it some time
if [ -f /healthcheck ]; then
  # If last modified on /healthcheck is > 60 seconds exit 21
  if find /healthcheck -mmin +1 | grep -q .; then
    echo "Previous healthcheck taking too long, failing."

    exit 21
  fi

  echo "Still running previous healthcheck, waiting up to 60 seconds before erroring..."
  exit
fi

touch /healthcheck

# If we are starting up give 90 seconds before checking anything
if [ -f /initializing ]; then
  # If last modified on /initializing is > 90 seconds exit 21
  if find /initializing -mmin +1.5 | grep -q .; then
    echo "Initilization taking too long, failing."

    exit 21
  fi

  echo "Still initializing, waiting up to 90 seconds before erroring..."
  exit
fi

# Validate the cert if necessary
set +e
sh /check-cert.sh

EXIT_CODE=$?
set -e

# If the error is 7 it has gotten a new cert
if [ $EXIT_CODE -eq 7 ]; then
  GUNICORN_PID=$(cat /tmp/gunicorn.pid)

  # Send HUP to gunicorn to make it restart
  echo "Sending HUP to $GUNICORN_PID"
  kill -HUP $GUNICORN_PID

  # The server might need a bit before restarting so sleep for a bit
  sleep 30
fi

if [ ! -z $FQDN ]; then
  PROTO=https
else
  PROTO=http
fi
SERVER=$PROTO://$FQDN:9000/

echo "Testing $SERVER"

if wget -qO- $SERVER | grep "Serles ACME Server is running"; then
  # All good
  rm /healthcheck

  exit
else
  echo "Unexpected/invalid server response, failing."
  exit 22
fi
