#!/bin/bash

jsonq() { python -c "import sys,json; obj=json.load(sys.stdin); sys.stdout.write(json.dumps($1))"; }

RANCHER_LOC="http://$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY@192.168.1.48"
SERVICE_NAME="alpine-nginx"
SERVICE_URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"
SERVICE_JSON=$(curl $SERVICE_URL)

ACTIONS_UPGRADE=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["actions"]["upgrade"]' | sed -e 's/^"//'  -e 's/"$//')
# ACTIONS_FINISH_UPGRADE=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["actions"]["finishupgrade"]' | sed -e 's/^"//'  -e 's/"$//')

UPGRADE_BATCH_SIZE=1
UPGRADE_INTERVAL_MILLIS=2000
UPGRADE_START_FIRST="false"
UPGRADE_LC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["launchConfig"]')
UPGRADE_SLC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["secondaryLaunchConfigs"]')

BODY="{ \"inServiceStrategy\": { \
  \"batchSize\": $UPGRADE_BATCH_SIZE, \
  \"intervalMillis\": $UPGRADE_INTERVAL_MILLIS, \
  \"startFirst\": $UPGRADE_START_FIRST, \
  \"launchConfig\": $UPGRADE_LC, \
  \"secondaryLaunchConfigs\": $UPGRADE_SLC } }"

# echo $ACTIONS_UPGRADE
echo $BODY

echo "[Posting to $ACTIONS_UPGRADE]"
#curl --data "$BODY" $ACTIONS_UPGRADE
