#!/usr/bin/env bash


mkdir -p /app/vendor/stunnel/var/run/stunnel/

echo "$STUNNEL_PSK" > /app/vendor/stunnel/psk

cat > /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes
pid = /app/vendor/stunnel/stunnel4.pid
client = yes

ciphers = PSK
psksecrets = /app/vendor/stunnel/psk

delay = yes
socket = r:TCP_NODELAY=1
TIMEOUTidle = 172800

EOFEOF

for URL in $STUNNEL_URLS
do

  eval URL_VALUE=\$$URL
  PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/([^:]+):([^@]+)@(.*?):(.*?)(\/(.*?)(\\?.*))?$/')
  URI=( $PARTS )

  URI_SCHEME=${URI[0]}
  URI_USER=${URI[1]}
  URI_PASS=${URI[2]}
  URI_HOST=${URI[3]}
  URI_PORT=${URI[4]}
  URI_PATH=${URI[5]}

  echo "Setting ${URL}_STUNNEL config var"
  export ${URL}_STUNNEL=$URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:$URI_PORT$URI_PATH

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF

[$URL]
accept = 127.0.0.1:$URI_PORT
connect = $URI_HOST:$URI_PORT
retry = yes
EOFEOF

done

chmod go-rwx /app/vendor/stunnel/*
