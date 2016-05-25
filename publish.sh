#!/bin/bash

CURRENT_BRANCH=$(echo $GIT_BRANCH | cut -d "/" -f 2)
VALID_BRANCHES=("master" "staging" "dev")

# make sure we restrict our builds to one of the valid branches above
if [[ " ${VALID_BRANCHES[@]} " =~ " ${CURRENT_BRANCH} " ]]; then
    IMAGE_VERSION=$CURRENT_BRANCH
else
    IMAGE_VERSION="dev"
fi

IMAGE_NAME=$SERVICE_NAME
IMAGE_TAG="$REGISTRY_HOST/$REGISTRY_ORG/$IMAGE_NAME:$IMAGE_VERSION"

# Login to the registry...
# N.B. it is essential that the docker client (guest container)
# and docker server (host machine) point to the same io location
# exposed in the HOME environment variable
#
# Warning: '--email' is deprecated, it will be removed soon. See usage.
# --email="."
#
echo "Logging in to $REGISTRY_HOST..."
export HOME=/home/ubuntu
time docker login \
  --username="$REGISTRY_USER" \
  --password="$REGISTRY_PASS" \
  $REGISTRY_HOST

# Generate npm auth token
echo "Generating npm auth token..."
time docker run \
  --env NPM_USER=$NPM_USER \
  --env NPM_PASS=$NPM_PASS \
  --env NPM_EMAIL=$NPM_EMAIL \
  bravissimolabs/generate-npm-authtoken \
  > .npmrc

# Build container and push to registry
echo "Building docker image: $IMAGE_TAG..."
time docker build --tag $IMAGE_TAG .

# Make sure the jenkins build fails if the docker build fails
OUT=$?

# Tidy up npm config to avoid auth info lying around
rm .npmrc

if [ $OUT -eq 0 ]; then
  echo "Pushing docker image: $IMAGE_TAG..."
  time docker push $IMAGE_TAG
else
  echo "Fatal error! Build failed"
  exit 1
fi
