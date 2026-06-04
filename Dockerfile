FROM alpine:latest
RUN apk add --no-cache \
    bash \
    iptables \
    wireguard-tools \
    tailscale \
    dnsmasq \
    jq

COPY ./bootstrap.sh /usr/local/bin/bootstrap.sh
RUN chmod +x /usr/local/bin/bootstrap.sh

CMD ["/usr/local/bin/bootstrap.sh"]
