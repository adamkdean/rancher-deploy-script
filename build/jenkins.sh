#!/bin/bash

PATH=$PATH:$WORKSPACE/bin

RANCHER_LOC="http://$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY@192.168.1.48"
SERVICE_NAME="alpine-nginx"
URL="$RANCHER_LOC/v1/services?name=$SERVICE_NAME"

curl $URL | jsawk 'return this.data[0]' > test.txt
cat test.txt
