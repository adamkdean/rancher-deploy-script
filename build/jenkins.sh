#!/bin/bash

jsonq() { python -c "import sys,json; obj=json.load(sys.stdin); sys.stdout.write(json.dumps($1))"; }

RANCHER_PROTO="http"
RANCHER_HOST="192.168.1.48"
RANCHER_ACCESS="$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY@$RANCHER_HOST"
RANCHER_LOC="$RANCHER_PROTO://$RANCHER_ACCESS"

SERVICE_NAME="alpine-nginx"
SERVICE_URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"
SERVICE_JSON=$(curl $SERVICE_URL)

ACTIONS_UPGRADE=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["actions"]["upgrade"]' | sed -e 's/^"//'  -e 's/"$//')
# ACTIONS_FINISH_UPGRADE=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["actions"]["finishupgrade"]' | sed -e 's/^"//'  -e 's/"$//')

UPGRADE_BATCH_SIZE=1
UPGRADE_INTERVAL_MILLIS=2000
UPGRADE_START_FIRST="false"
UPGRADE_URL="$RANCHER_LOC/v1${ACTIONS_UPGRADE#*/v1}"
UPGRADE_LC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["launchConfig"]')
UPGRADE_SLC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["secondaryLaunchConfigs"]')

BODY="{ \"inServiceStrategy\": { \
  \"batchSize\": $UPGRADE_BATCH_SIZE, \
  \"intervalMillis\": $UPGRADE_INTERVAL_MILLIS, \
  \"startFirst\": $UPGRADE_START_FIRST, \
  \"launchConfig\": $UPGRADE_LC, \
  \"secondaryLaunchConfigs\": $UPGRADE_SLC } }"

echo "[BODY is]"
echo $BODY

echo "[Posting to $UPGRADE_URL]"
curl -H "Content-Type: application/json" -X POST -d "$BODY" $UPGRADE_URL
