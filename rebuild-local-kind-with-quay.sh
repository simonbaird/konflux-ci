#!/bin/bash
set -euo pipefail

function slow-title() {
  sleep 2
  echo ""
  echo "************************************************************"
  echo " 🐢 $1"
  echo "************************************************************"
  echo ""
}

slow-title "Deleting old cluster"
kind delete cluster --name konflux

slow-title "Creating cluster"
kind create cluster --name konflux --config kind-config.yaml

slow-title "Deploying dependencies"
./deploy-deps.sh

slow-title "Deploying Konflux"
./deploy-konflux.sh

slow-title "Deploying demo users"
./deploy-test-resources.sh
sleep 2

slow-title "Deploying PAC secret"
./deploy-pac-github-secret.sh

slow-title "Deploying image controller"
(source .env && ./deploy-image-controller.sh "$QUAY_TOKEN" "$QUAY_ORG")

slow-title "Deploying Quay secret"
./deploy-quay-push-secret.sh

slow-title "Create VSA demo resources"
kubectl apply -k "test/resources/vsa-demo"

slow-title "Ready"
echo "https://localhost:9443/"
