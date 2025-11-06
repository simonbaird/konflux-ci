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

# Show some vars
show-var SNAPSHOT_NAME
show-var IMG_REF
show-var IMG_DIGEST
nl

# Demo the freshly built component
show-then-run 'podman run --rm $IMG_REF'

#-----------------------------------------------------------------------------
h1 "Logs for the Conforma ITS pipeline run"

GET_PIPELINE_CMD='tkn pipelinerun list -n user-ns2'
show-then-run "$GET_PIPELINE_CMD --limit 1"
PIPELINE_RUN=$(eval "$GET_PIPELINE_CMD -o jsonpath='{.items[0].metadata.name}'")

pause-then-run 'tkn pipelinerun logs $PIPELINE_RUN -n user-ns2'


#-----------------------------------------------------------------------------
h1 "Cosign download attestation shows two attestations"

show-msg "Notice there are two atts, one for the build pipeline run and one for the ITS pipeline run"
nl

show-then-run 'cosign download attestation $IMG_REF | cut -c -120'
nl

show-then-run 'cosign download attestation $IMG_REF | jq ".payload = \"...\"|.signatures = \"...\""'
nl

show-then-run 'cosign tree $IMG_REF'

pause

# Show the tasks list to demonstrate they're different. Use -s to slurp the separate documents into an array.
# Not sure if the order is deterministic here, but hopefully it is..?
show-then-run 'cosign download attestation $IMG_REF | jq -s -r ".[1]|.payload|@base64d|fromjson|.predicate.buildConfig.tasks[]|.name"'
nl
show-then-run 'cosign download attestation $IMG_REF | jq -s -r ".[0]|.payload|@base64d|fromjson|.predicate.buildConfig.tasks[]|.name"'
nl

#-----------------------------------------------------------------------------
h1 "Extract VSA locations"

show-msg "We create a task result with a mapping of images to vsa refs. Let's extract it."

GET_VSA_MAP_CMD='cosign download attestation $IMG_REF |
    jq -s ".[0]|.payload|@base64d|fromjson" |
    jq .predicate.buildConfig |
    jq ".tasks[]|select(.name==\"verify\").results[]|select(.name==\"VSA_MAP\").value|fromjson"'

pause-then-run "$GET_VSA_MAP_CMD"

# Continuing the assumption that we have just one component
VSA_REF=$(eval "$GET_VSA_MAP_CMD | jq -r '.[\"$IMG_REF\"]'")
VSA_UUID=${VSA_REF##*=}

nl
show-var VSA_UUID

#-----------------------------------------------------------------------------
h1 "Looking up the VSA in Rekor"

# Show which Rekor instance we're using
REKOR_SERVER="https://rekor.sigstore.dev"
show-var REKOR_SERVER
nl

show-msg "Look at the full Rekor entry"
pause-then-run 'rekor-cli get --uuid $VSA_UUID --rekor_server $REKOR_SERVER --format json | yq -P'

show-msg "Look at just the attestation"
pause-then-run 'rekor-cli get --uuid $VSA_UUID --rekor_server $REKOR_SERVER --format json | jq ".Attestation|fromjson" | yq -P'

#-----------------------------------------------------------------------------
h1 "Running Conforma"

# This should be the same policy specified in the relevant RPA and used
# when the VSA was created
POLICY_YAML=test/resources/vsa-demo/enterprise-contract-policy.yaml
show-var POLICY_YAML
nl

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
  --vsa-public-key cosign.pub \
  --no-fallback \
  --policy $POLICY_YAML
'

pause

show-msg "Simulate a green VSA but mismatched ECP"

MODIFIED_POLICY_YAML=modified.yaml
yq '.spec.sources[0].config.exclude[0] |= "frobbed"' $POLICY_YAML > $MODIFIED_POLICY_YAML

show-then-run 'diff --color $POLICY_YAML $MODIFIED_POLICY_YAML'

pause

pause-then-run 'time ec validate vsa \
  --images <(echo "$SNAPSHOT_SPEC") \
  --vsa-public-key cosign.pub \
  --fallback-public-key k8s://openshift-pipelines/public-key \
  --policy $MODIFIED_POLICY_YAML
'
