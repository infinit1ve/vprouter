#!/bin/bash

if [ -z "$TS_AUTHKEY" ]; then
    echo "TS_AUTHKEY is not set"
    exit 1
fi

tailscaled &
sleep 5
tailscale set --auto-update
tailscale up --authkey=$TS_AUTHKEY --advertise-exit-node --hostname=${TS_HOSTNAME:-vprouter}

if [ -z "$WIREGUARD_PRIVATEKEY" ]; then
    echo "WIREGUARD_PRIVATEKEY is not set"
    exit 1
fi

if [ -z "$WIREGUARD_ADDRESS" ]; then
    echo "WIREGUARD_ADDRESS is not set"
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

mkdir -p /etc/wireguard
cat <<EOF > /etc/wireguard/wireguard.conf
[Interface]
PrivateKey = $WIREGUARD_PRIVATEKEY

[Peer]
PublicKey = $WIREGUARD_PEERKEY
AllowedIPs = ${WIREGUARD_ALLOWEDIPS:-0.0.0.0/0}
Endpoint = $WIREGUARD_ENDPOINT
EOF

ip link add wg0 type wireguard
wg setconf wg0 /etc/wireguard/wireguard.conf
ip addr add "$WIREGUARD_ADDRESS" dev wg0
ip link set wg0 up

DEFAULT_GATEWAY=$(ip route | awk '/default/ {print $3}')
DEFAULT_DEVICE=$(ip route | awk '/default/ {print $5}')

ip route add "${WIREGUARD_ENDPOINT%:*}" via "$DEFAULT_GATEWAY" dev "$DEFAULT_DEVICE"
ip route add 100.64.0.0/10 dev tailscale0
ip route replace default dev wg0

iptables -N vprouter-forward
iptables -I FORWARD -j vprouter-forward
iptables -A vprouter-forward -m comment --comment "Allow return traffic from WireGuard to Tailscale" -j ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED -i wg0 -o tailscale0
iptables -A vprouter-forward -m comment --comment "Allow Tailscale traffic to WireGuard" -i tailscale0 -o wg0 -j ACCEPT
iptables -A vprouter-forward -m comment --comment "Drop unestablished traffic from WireGuard to Tailscale" -j DROP -i wg0 -o tailscale0

iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE -m comment --comment "Masquerade WireGuard traffic"

wait
