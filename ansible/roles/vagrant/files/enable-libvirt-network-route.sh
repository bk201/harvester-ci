#!/bin/bash -e

network=$1

get_bridge_name() {
    xml=$(virsh net-dumpxml --network $1)
    echo "$xml" | grep -o "<bridge[^>]*>" | awk -F'[ ="]' '/<bridge / {for (i=1; i<=NF; i++) if ($i == "name") print $(i+1)}' | tr -d "'"
}


active=$(virsh net-info --network $network | grep '^Active' | awk '{print $2}')

if [ "$active" != "yes" ]; then
    echo "Network $network is not active."
    exit 0
fi

bridge=$(get_bridge_name $network)
if [[ $bridge != virbr* ]]; then
    echo "Bridge of network $network doesn't start with 'virbr'"
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
else
	SUDO=""
fi

set -x

"$SUDO" iptables -D LIBVIRT_FWI -o $bridge -j REJECT --reject-with icmp-port-unreachable || true
"$SUDO" iptables -D LIBVIRT_FWO -i $bridge -j REJECT --reject-with icmp-port-unreachable || true
