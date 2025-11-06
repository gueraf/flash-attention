#!/bin/bash
set -e

# This script deploys the GitHub runner pod to Kubernetes.
# It replaces the placeholder for the GitHub token in the YAML file
# with the value of the GITHUB_ACCESS_TOKEN environment variable.

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
  echo "Error: GITHUB_ACCESS_TOKEN environment variable is not set." >&2
  exit 1
fi

# Delete the pod if it exists to force a replacement.
echo "Deleting existing runner pod (if any)..."
kubectl delete pod gh-runner-flashattention --ignore-not-found=true

# Create a temporary file for the pod definition.
# The temporary file is automatically removed when the script exits.
TEMP_YAML=$(mktemp)
trap 'rm -f "$TEMP_YAML"' EXIT

# Use sed to replace the placeholder with the actual token.
# Note the use of a different delimiter (,) for sed to avoid issues with special characters in the token.
sed "s,YOUR_GITHUB_ACCESS_TOKEN,${GITHUB_ACCESS_TOKEN}," gh-runner-pod.yaml > "$TEMP_YAML"

# Apply the configuration to Kubernetes.
echo "Deploying runner pod to Kubernetes..."
kubectl apply -f "$TEMP_YAML"

echo "Runner pod deployed successfully."
