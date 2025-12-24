#!/bin/bash

# Set the script to exit immediately if any command fails
set -e

# List all resources in the current Terraform state using Terragrunt
resources=$(terragrunt state list)

# Check if resources list is empty
if [ -z "$resources" ]; then
  echo "No resources found in the Terragrunt state."
  exit 0
fi

# Remove each resource found in the Terragrunt state
for resource in $resources; do
  echo "Removing ${resource} from Terragrunt state..."
  terragrunt state rm "$resource"
done

echo "All resources have been removed from the Terragrunt state."

