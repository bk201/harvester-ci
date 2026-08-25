#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CI_DIR="$REPO_ROOT/ci"
CONFIG_FILE="$CI_DIR/config.yaml"

VM_IP="$(terraform -chdir="$CI_DIR" output -json vm_ip_addresses | jq -r '.[0] // empty')"

if [[ -z "$VM_IP" ]]; then
  echo "Error: 'vm_ip_addresses' output is empty. Is the VM created and does it have an IP yet?" >&2
  exit 1
fi

VM_USER="$(yq -r '.vm_user_name' "$CONFIG_FILE")"
SSH_KEY_NAME="$(yq -r '.ssh_pubkey_name' "$CONFIG_FILE")"

if [[ -z "$VM_USER" || "$VM_USER" == "null" ]]; then
  echo "Error: 'vm_user_name' is not set in $CONFIG_FILE" >&2
  exit 1
fi
set -x

exec ssh -i "$CI_DIR/$SSH_KEY_NAME" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "${VM_USER}@${VM_IP}"
