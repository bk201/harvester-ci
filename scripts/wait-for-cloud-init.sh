#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CI_DIR="$REPO_ROOT/ci"
CONFIG_FILE="$CI_DIR/config.yaml"

SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-5}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-600}"
RETRY_INTERVAL="${RETRY_INTERVAL:-5}"

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

SSH_OPTS=(
  -i "$CI_DIR/$SSH_KEY_NAME"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout="$SSH_CONNECT_TIMEOUT"
  -o BatchMode=yes
)

echo "Waiting for SSH to become available on ${VM_USER}@${VM_IP}..."

deadline=$((SECONDS + WAIT_TIMEOUT))
until ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_IP}" true 2>/dev/null; do
  if (( SECONDS >= deadline )); then
    echo "Error: timed out after ${WAIT_TIMEOUT}s waiting for SSH on ${VM_IP}" >&2
    exit 1
  fi
  sleep "$RETRY_INTERVAL"
done

echo "SSH is up. Waiting for cloud-init to finish on ${VM_IP}..."

if ! ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_IP}" \
  "sudo cloud-init status --wait --long"; then
  echo "Error: cloud-init did not finish successfully on ${VM_IP}" >&2
  exit 1
fi

echo "cloud-init finished successfully on ${VM_IP}."
