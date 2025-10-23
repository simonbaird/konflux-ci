#!/bin/bash
set -euo pipefail

# Get the newest snapshot
SNAPSHOT=$(kubectl get -n user-ns2 snapshot --sort-by=.metadata.creationTimestamp --output=json | jq -r '.items[-1]')

echo "Snapshot name: $(echo "$SNAPSHOT" | jq -r .metadata.name)"

# Get the first image from the snapsho
IMG_REF=$(echo "$SNAPSHOT" | jq -r '.spec.components[0].containerImage')
echo IMG_REF=$IMG_REF

# Extract the digest from the image ref
IMG_DIGEST=${IMG_REF##*:}
echo IMG_DIGEST=$IMG_DIGEST

# See what we can find in rekor for that digest
REKOR_UUIDS=$(rekor-cli search --sha $IMG_DIGEST --format json | jq -r '.UUIDs[]')
printf "REKOR_UUIDS:\n$REKOR_UUIDS\n"

read -p "Press Enter to continue"

# Fetch the VSA from Rekor
for uuid in $REKOR_UUIDS; do
  rekor-cli get --uuid $uuid --format json | jq '.Attestation|fromjson'
done

read -p "Press Enter to continue"

ec validate image \
  --images <(echo "$SNAPSHOT" | jq .spec) \
  --policy test/resources/vsa-demo/enterprise-contract-policy.yaml \
  --public-key k8s://openshift-pipelines/public-key \
  --ignore-rekor \
  --show-warnings=false \
  --info

read -p "Press Enter to continue"

ec validate vsa \
  --images <(echo "$SNAPSHOT" | jq .spec) \
  --public-key cosign.pub \
  --policy test/resources/vsa-demo/enterprise-contract-policy.yaml
