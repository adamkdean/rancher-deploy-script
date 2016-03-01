#!/bin/bash

jsonq() { python -c "import sys,json; obj=json.load(sys.stdin); sys.stdout.write(json.dumps($1))"; }

RANCHER_LOC="http://$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY@192.168.1.48"
SERVICE_NAME="alpine-nginx"
SERVICE_URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"
SERVICE_JSON=$(curl $SERVICE_URL)



LC=$(echo $SERVICE_JSON | python -c 'import json,sys;obj=json.load(sys.stdin);sys.stdout.write(json.dumps(obj["data"][0]["launchConfig"]))')
SLC=$(echo $SERVICE_JSON | python -c 'import json,sys;obj=json.load(sys.stdin);sys.stdout.write(json.dumps(obj["data"][0]["secondaryLaunchConfigs"]))')

echo '-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-'
echo $LC
echo '-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-'
echo $SLC
echo '-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-'
