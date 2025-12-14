#!/bin/bash

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
CONFIG_FILE="$ROOT_DIR/.git-hooks/conf.d/protected_branches.yml"

if ! command -v yq &> /dev/null; then
    echo "❌ Error: yq is required but not installed."
    exit 1
fi

protected_branches=$(yq -r '.protected_branches[]' "$CONFIG_FILE")

while read local_ref local_sha remote_ref remote_sha; do
    remote_branch=${remote_ref#refs/heads/}
    
    for protected in $protected_branches; do
        if [[ $remote_branch == $protected ]]; then
            echo "❌ Error: Pushing to $remote_branch is not allowed"
            exit 1
        fi
    done
done
