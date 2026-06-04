#!/bin/bash

tailscale --version
wg --version
ip route

tailscaled &
sleep 5
tailscale set --auto-update
tailscale up --authkey=$TS_AUTHKEY --advertise-exit-node --hostname=vprouter

if [ -z "$WIREGUARD_PRIVATEKEY" ]; then
    echo "WIREGUARD_PRIVATEKEY is not set"
    exit 1
fi

if [ -z "$WIREGUARD_ADDRESS" ]; then
    echo "WIREGUARD_ADDRESS is not set"
    exit 1
fi

if [ -z "$WIREGUARD_ALLOWEDIPS" ]; then
    echo "WIREGUARD_ALLOWEDIPS is not set"
    exit 1
fi

if [ -z "$WIREGUARD_ENDPOINT" ]; then
    echo "WIREGUARD_ENDPOINT is not set"
    exit 1
fi

if [ -z "$WIREGUARD_PEERKEY" ]; then
    echo "WIREGUARD_PEERKEY is not set"
    exit 1
fi

cat <<EOF > /etc/wireguard/wireguard.conf
[Interface]
PrivateKey = $WIREGUARD_PRIVATEKEY

[Peer]
PublicKey = $WIREGUARD_PEERKEY
AllowedIPs = $WIREGUARD_ALLOWEDIPS
Endpoint = $WIREGUARD_ENDPOINT
EOF

mkdir -p /etc/wireguard
ip link add wg0 type wireguard
wg setconf wg0 /etc/wireguard/wireguard.conf
ip addr add "$WIREGUARD_ADDRESS" dev wg0
ip link set wg0 up
wait
