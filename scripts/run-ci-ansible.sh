#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CI_DIR="$REPO_ROOT/ci"
ANSIBLE_DIR="$REPO_ROOT/ansible"
CONFIG_FILE="$CI_DIR/config.yaml"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/ci-vm"
PLAYBOOK="$ANSIBLE_DIR/node-ci-opensuse-vm.yaml"

VM_IPS_JSON="$(terraform -chdir="$CI_DIR" output -json vm_ip_addresses)"

if [[ "$(echo "$VM_IPS_JSON" | jq 'length')" -eq 0 ]]; then
  echo "Error: 'vm_ip_addresses' output is empty. Is the VM created and does it have an IP yet?" >&2
  exit 1
fi

VM_NAME="$(yq -r '.vm_name' "$CONFIG_FILE")"
VM_USER="$(yq -r '.vm_user_name' "$CONFIG_FILE")"
SSH_KEY_NAME="$(yq -r '.ssh_pubkey_name' "$CONFIG_FILE")"

if [[ -z "$VM_USER" || "$VM_USER" == "null" ]]; then
  echo "Error: 'vm_user_name' is not set in $CONFIG_FILE" >&2
  exit 1
fi

SSH_KEY_PATH="$CI_DIR/$SSH_KEY_NAME"

{
  echo "[harvester_ci_vm]"
  index=0
  while read -r ip; do
    echo "${VM_NAME}-${index} ansible_ssh_host=${ip} ansible_user=${VM_USER} ansible_ssh_private_key_file=${SSH_KEY_PATH} ansible_python_interpreter=/usr/bin/python3.11"
    index=$((index + 1))
  done < <(echo "$VM_IPS_JSON" | jq -r '.[]')
} > "$INVENTORY_FILE"

echo "Generated inventory: $INVENTORY_FILE"
cat "$INVENTORY_FILE"

ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK" "$@"
