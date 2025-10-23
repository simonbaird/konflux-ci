#!/bin/bash
set -euo pipefail

source hack/demo-helpers.sh

#-----------------------------------------------------------------------------
h1 "A single component snapshot"

# Find the newest snapshot
SNAPSHOT=$(kubectl get -n user-ns2 snapshot --sort-by=.metadata.creationTimestamp --output=json | jq -r '.items[-1]')

# Extract useful details from the snapshot
SNAPSHOT_NAME=$(jq -r '.metadata.name' <<< "$SNAPSHOT")
SNAPSHOT_SPEC=$(jq -r '.spec' <<< "$SNAPSHOT")
IMG_REF=$(jq -r '.components[0].containerImage' <<< "$SNAPSHOT_SPEC")
IMG_DIGEST=${IMG_REF##*:}

# Show some relevant details
show-vars SNAPSHOT_NAME IMG_REF IMG_DIGEST

# Show that in runs
show-then-run 'podman run --rm $IMG_REF'

# Show that it was recently built
show-then-run 'skopeo inspect --no-tags docker://$IMG_REF | jq -r .Created'
show-then-run 'date -uIs'

#-----------------------------------------------------------------------------
h1 "Pod logs for the VSA service"

# Find the pod
GET_SERVICE_POD='kubectl get pods --selector app=conforma-knative-service -n conforma'
show-then-run "$GET_SERVICE_POD"
SERVICE_POD=$(eval "$GET_SERVICE_POD -o json | jq -r .items[0].metadata.name")

# Show the pod logs
pause-then-run "kubectl logs $SERVICE_POD -n conforma"

#-----------------------------------------------------------------------------
h1 "Pod logs for the job created by VSA service"

# Find the pod
GET_JOB_POD='kubectl get pods --selector app.kubernetes.io/name=vsa-generator -n conforma'
show-then-run "$GET_JOB_POD"
JOB_POD=$(eval "$GET_JOB_POD -o json | jq -r .items[0].metadata.name")

# Show the pod logs
pause-then-run "kubectl logs $JOB_POD -n conforma"

#-----------------------------------------------------------------------------
h1 "Looking up the VSA in Rekor"

show-msg "We can use the image digest to look up the Rekor entry"

# Show which Rekor instance we're using
REKOR_SERVER="https://rekor.sigstore.dev"
show-vars REKOR_SERVER

pause-then-run 'rekor-cli search --sha $IMG_DIGEST --rekor_server $REKOR_SERVER'

# See what we can find in rekor for that digest
REKOR_UUIDS=$(rekor-cli search --sha $IMG_DIGEST --format json | jq -r '.UUIDs[]')
for uuid in $REKOR_UUIDS; do
  nl
  show-msg "Look at the full Rekor entry"
  pause-then-run 'rekor-cli get --uuid $uuid --rekor_server $REKOR_SERVER --format json | yq -P'

  nl
  show-msg "Look at just the attestation"
  pause-then-run 'rekor-cli get --uuid $uuid --rekor_server $REKOR_SERVER --format json | jq ".Attestation|fromjson" | yq -P'
done

#-----------------------------------------------------------------------------
h1 "Running Conforma"

# This should be the same policy specified in the relevant RPA and used
# when the VSA was created
POLICY_YAML=test/resources/vsa-demo/enterprise-contract-policy.yaml
show-vars POLICY_YAML

show-msg 'First do a "normal" Conforma policy check (no VSA)'

pause-then-run 'time ec validate image \
  --images <(echo "$SNAPSHOT_SPEC") \
  --policy $POLICY_YAML \
  --public-key k8s://openshift-pipelines/public-key \
  --ignore-rekor \
  --show-warnings=false \
  --info
'

pause

show-msg "Now do a Conforma VSA check"

pause-then-run 'time ec validate vsa \
  --images <(echo "$SNAPSHOT_SPEC") \
  --vsa-public-key k8s://conforma/vsa-public-key \
  --no-fallback \
  --policy $POLICY_YAML
'

pause

show-msg "Simulate a green VSA but mismatched ECP"

MODIFIED_POLICY_YAML=modified.yaml
yq 'del(.spec.sources[0].config.exclude[0])' $POLICY_YAML > $MODIFIED_POLICY_YAML

show-then-run 'diff --color $POLICY_YAML $MODIFIED_POLICY_YAML'

pause

pause-then-run 'time ec validate vsa \
  --images <(echo "$SNAPSHOT_SPEC") \
  --vsa-public-key k8s://conforma/vsa-public-key \
  --fallback-public-key k8s://openshift-pipelines/public-key \
  --policy $MODIFIED_POLICY_YAML
'
