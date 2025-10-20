#!/bin/bash
set -euo pipefail

# Assume this sets the env vars mentioned below.
# See example.env for an example.
source .env

kubectl create -n "$NS" secret generic regcred \
        --from-file=.dockerconfigjson="$QUAY_CREDENTIAL_FILE" \
        --type=kubernetes.io/dockerconfigjson

kubectl patch -n "$NS" serviceaccount appstudio-pipeline \
        --patch '{"secrets": [{"name": "regcred"}]}'
