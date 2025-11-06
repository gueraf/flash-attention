#!/bin/bash
set -e

# This script deploys the GitHub runner pod to Kubernetes.
# It replaces the placeholder for the GitHub token in the YAML file
# with the value of the GITHUB_ACCESS_TOKEN environment variable.

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
  echo "Error: GITHUB_ACCESS_TOKEN environment variable is not set." >&2
  exit 1
fi

# Default to x86 architecture
ARCH_NODE_SELECTOR="amd64"
ARCH_IMAGE_TAG="latest"
ARCH_RUNNER_LABELS="self-hosted,Linux,X64,gpu"

# Check for --arm flag
if [[ "$1" == "--arm" ]]; then
  echo "ARM architecture selected."
  ARCH_NODE_SELECTOR="arm64"
  ARCH_IMAGE_TAG="arm"
  ARCH_RUNNER_LABELS="self-hosted-arm,Linux,ARM64,gpu"
fi

# Delete the pod if it exists to force a replacement.
echo "Deleting existing runner pod (if any)..."
kubectl delete pod gh-runner-flashattention --ignore-not-found=true

# Create a temporary file for the pod definition.
# The temporary file is automatically removed when the script exits.
TEMP_YAML=$(mktemp)
trap 'rm -f "$TEMP_YAML"' EXIT

# Use sed to replace the placeholders with the actual values.
sed -e "s|YOUR_GITHUB_ACCESS_TOKEN|${GITHUB_ACCESS_TOKEN}|" \
    -e "s|ARCH_NODE_SELECTOR|${ARCH_NODE_SELECTOR}|" \
    -e "s|ARCH_IMAGE_TAG|${ARCH_IMAGE_TAG}|" \
    -e "s|ARCH_RUNNER_LABELS|${ARCH_RUNNER_LABELS}|" \
    gh-runner-pod.yaml > "$TEMP_YAML"

# Apply the configuration to Kubernetes.
echo "Deploying runner pod to Kubernetes..."
kubectl apply -f "$TEMP_YAML"

echo "Runner pod deployed successfully."
