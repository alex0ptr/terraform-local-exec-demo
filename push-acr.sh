#!/bin/bash
set -euo pipefail

image=$1
registry=$2

echo "pulling image: $image"
docker pull "$image"

echo "logging in to registry: $registry"
az acr login --name "$(echo "$registry" | cut -d '.' -f 1)" 

registryImage="$registry/$image"
echo "pushing $image to registry: $registryImage"
docker tag "$image" "$registryImage"
docker push "$registryImage"



