#!/bin/bash
set -euo pipefail

source hack/demo-helpers.sh

h1 "Background"

pause "$(show-msg "Running Conforma and performing all policy checks is an expensive operation")"

echo "- Fetching policies from quay or from git"
echo "- Fetching policy data from quay or from git"
echo "- Fetching attestations"
echo "- Fetching SBOMs"
echo "- Fetching Clair report artifacts"
echo "- Fetching manifests (sometimes)"
echo "- Fetching image data (sometimes)"

nl
show-msg "Some of those scale up proportional to the size of the snapshot"

nl
show-msg "If your snapshot has several hundred components, each built for say four different arches..."

pause

show-msg "(These parts are actually pretty fast, the bottleneck is the all fetching I think)"

echo "- Verifying signatures"
echo "- Evalulating policy rego"
echo "- Collating results and producing reports"

nl
h1 "What is a VSA?"

show-msg "In simple terms, think of it like a formal way to represent a verification result"

show-msg "In our case, the result is a Conforma validation"

show-msg "https://slsa.dev/spec/v1.2/verification_summary"

h1 "So, why VSAs?"

show-msg "If we performed a full Conforma check already, the VSA is a record of the result"

show-msg "At release time, instead of always redoing all the Conforma checks we can instead look first for a current, green VSA."

show-msg "If..."

echo "- a VSA is found"
echo "- the VSA's signature can be verified"
echo "- the VSA is fresh enough"
echo "- the policy used when creating the VSA matches the currently required policy"

nl

show-msg "If all that is true then we don't have to redo the Conforma validation at release time"

h1 "How/when will the VSAs be created?"

show-msg "Integration Tests?"

echo "This is problematic because:"

echo "- The policy may not match the release-time policy"
echo "- We don't trust Konflux users"

nl
pause
show-msg "A new service?"

echo "Queue demo..."
