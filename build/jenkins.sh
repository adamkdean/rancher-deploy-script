#!/bin/bash

RANCHER_LOC="http://$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY@192.168.1.48"
SERVICE_NAME="alpine-nginx"
URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"

curl $URL | python -c 'import json,sys;obj=json.load(sys.stdin);sys.stdout.write(json.dumps(obj["data"][0]))'

cat dump.txt
