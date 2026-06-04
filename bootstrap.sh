#!/bin/bash

tailscale --version
wg --version
ip route

tailscaled &
sleep 5
tailscale set --auto-update
tailscale up --authkey=$TS_AUTHKEY --advertise-exit-node --hostname=vprouter
wait
