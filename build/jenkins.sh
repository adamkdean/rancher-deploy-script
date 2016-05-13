#!/bin/bash
#
# MAINTAINER: Adam K Dean

jsonq() { python -c "import sys,json; obj=json.load(sys.stdin); sys.stdout.write(json.dumps($1))"; }

CURL="curl --user $RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY"
RANCHER_PROTO="http"
RANCHER_LOC="$RANCHER_PROTO://$RANCHER_HOST"

SERVICE_URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"
SERVICE_JSON=$($CURL $SERVICE_URL)

STATE=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["state"]' | sed -e 's/^"//'  -e 's/"$//')
SELF=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["links"]["self"]' | sed -e 's/^"//'  -e 's/"$//')

if [[ $STATE != "active" ]]; then
  echo "[ERROR] Service $SERVICE_NAME state is '$STATE', must be set to 'active'"
  exit 1
fi

UPGRADE_TIMEOUT=60
UPGRADE_BATCH_SIZE=1
UPGRADE_INTERVAL_MILLIS=2000
UPGRADE_START_FIRST="true"
UPGRADE_URL=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["actions"]["upgrade"]' | sed -e 's/^"//'  -e 's/"$//')
UPGRADE_LC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["launchConfig"]')
UPGRADE_SLC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["secondaryLaunchConfigs"]')

BODY="{ \"inServiceStrategy\": { \
  \"batchSize\": $UPGRADE_BATCH_SIZE, \
  \"intervalMillis\": $UPGRADE_INTERVAL_MILLIS, \
  \"startFirst\": $UPGRADE_START_FIRST, \
  \"launchConfig\": $UPGRADE_LC, \
  \"secondaryLaunchConfigs\": $UPGRADE_SLC } }"

echo "[Upgrading $SERVICE_NAME]"
RESPONSE=$($CURL -H "Content-Type: application/json" -X POST -d "$BODY" $UPGRADE_URL)

echo "[Waiting for service $SERVICE_NAME to upgrade]"
wait4upgrade() {
  CNT=0
  STATE=""
  until [[ $STATE == "upgraded" ]]; do
    STATE=$($CURL --silent $SELF | jsonq 'obj["state"]' | sed -e 's/^"//'  -e 's/"$//')
    echo "Service state: $STATE"
    if [ $((CNT++)) -gt $UPGRADE_TIMEOUT ]; then
        echo "Upgrade timed out, state: $STATE"
        exit 1
    else
        sleep 1
    fi
  done
}
wait4upgrade

FINISH_UPGRADE_URL=$($CURL $SELF | jsonq 'obj["actions"]["finishupgrade"]' | sed -e 's/^"//'  -e 's/"$//')
echo "[Confirming upgrade via $FINISH_UPGRADE_URL]"
RESPONSE=$($CURL -X POST $FINISH_UPGRADE_URL)

echo "[Waiting for service $SERVICE_NAME to finish upgrade]"
wait4finishupgrade() {
  CNT=0
  STATE=""
  until [[ $STATE == "active" ]]; do
    STATE=$($CURL --silent $SELF | jsonq 'obj["state"]' | sed -e 's/^"//'  -e 's/"$//')
    echo "Service state: $STATE"
    if [ $((CNT++)) -gt $UPGRADE_TIMEOUT ]; then
        echo "Confirm Upgrade timed out, state: $STATE"
        exit 1
    else
        sleep 1
    fi
  done
}
wait4finishupgrade

echo "[ALL DONE]"
exit 0
