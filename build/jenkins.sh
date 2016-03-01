#!/bin/bash

jsonq() { python -c "import sys,json; obj=json.load(sys.stdin); sys.stdout.write(json.dumps($1))"; }

RANCHER_PROTO="http"
RANCHER_HOST="192.168.1.48"
RANCHER_ACCESS="$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY@$RANCHER_HOST"
RANCHER_LOC="$RANCHER_PROTO://$RANCHER_ACCESS"

SERVICE_NAME="alpine-nginx"
SERVICE_URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"
SERVICE_JSON=$(curl $SERVICE_URL)

STATE=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["state"]' | sed -e 's/^"//'  -e 's/"$//')
SELF=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["links"]["self"]' | sed -e 's/^"//'  -e 's/"$//')

if [[ $STATE != "active" ]]; then
  echo "[ERROR] Service $SERVICE_NAME state is '$STATE', must be set to 'active'"
  exit 1
fi


UPGRADE_BATCH_SIZE=1
UPGRADE_INTERVAL_MILLIS=2000
UPGRADE_START_FIRST="false"
UPGRADE_URL=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["actions"]["upgrade"]' | sed -e 's/^"//'  -e 's/"$//')
#UPGRADE_URL="$RANCHER_LOC/v1${UPGRADE_URL#*/v1}"
UPGRADE_LC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["launchConfig"]')
UPGRADE_SLC=$(echo $SERVICE_JSON | jsonq 'obj["data"][0]["secondaryLaunchConfigs"]')

BODY="{ \"inServiceStrategy\": { \
  \"batchSize\": $UPGRADE_BATCH_SIZE, \
  \"intervalMillis\": $UPGRADE_INTERVAL_MILLIS, \
  \"startFirst\": $UPGRADE_START_FIRST, \
  \"launchConfig\": $UPGRADE_LC, \
  \"secondaryLaunchConfigs\": $UPGRADE_SLC } }"

echo "[Upgrading $SERVICE_NAME]"
curl -H "Content-Type: application/json" -X POST -d "$BODY" $UPGRADE_URL

echo "[Waiting for service $SERVICE_NAME to upgrade]"
wait4upgrade() {
    CNT=0
    STATE=""
    until [[ $STATE -eq "upgraded" ]]; do
        STATE=$(curl $SELF | jsonq 'obj["state"]' | sed -e 's/^"//'  -e 's/"$//')
        echo -n "."
        [ $((CNT++)) -gt 60 ] && exit 1 || sleep 1
    done
    sleep 1
}
wait4upgrade

curl $SELF | jsonq 'obj["actions"]["finishupgrade"]' | sed -e 's/^"//'  -e 's/"$//'

#ACTIONS_FINISH_UPGRADE=$(curl $LINKS_SELF | jsonq 'obj["actions"]["finishupgrade"]' | sed -e 's/^"//'  -e 's/"$//')
#echo "DONE, ACTIONS_FINISH_UPGRADE is $ACTIONS_FINISH_UPGRADE"
