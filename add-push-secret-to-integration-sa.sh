#
# For this POC we need to let the integration test have access to the
# push secret otherwise Chains is unable to create an attestation for
# the integration test pipeline run.
#
kubectl patch -n user-ns2 serviceaccount konflux-integration-runner \
  --patch '{"secrets": [{"name": "imagerepository-for-vsa-demo-app-vsa-demo-cmp-image-push"}, {"name": "vsa-demo-cmp-repo-image-push"}]}'
# Todo: Not sure if I really need both of those, or if just one would be enough

# Have to remove this I think otherwise it takes precedent??
kubectl patch -n user-ns2 serviceaccount konflux-integration-runner \
  --type='json' --patch='[{"op": "remove", "path": "/imagePullSecrets"}]'

# I think we need to restart chains so it can see the new secret
kubectl delete pod --selector app=tekton-chains-controller -n tekton-pipelines
kubectl wait --for=condition=Ready --timeout=120s -l app=tekton-chains-controller -n tekton-pipelines pod
