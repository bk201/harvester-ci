#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CI_DIR="$REPO_ROOT/ci"
CONFIG_FILE="$CI_DIR/config.yaml"

SSH_KEY_NAME="$(yq -r '.ssh_pubkey_name' "$CONFIG_FILE")"

if [[ -z "$SSH_KEY_NAME" || "$SSH_KEY_NAME" == "null" ]]; then
  echo "Error: 'ssh_pubkey_name' is not set in $CONFIG_FILE" >&2
  exit 1
fi

KEY_PATH="$CI_DIR/$SSH_KEY_NAME"

if [[ -f "$KEY_PATH" && -f "$KEY_PATH.pub" ]]; then
  echo "SSH key pair already exists at $KEY_PATH, skipping generation."
  exit 0
fi

ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$SSH_KEY_NAME"

echo "Generated SSH key pair: $KEY_PATH / $KEY_PATH.pub"
