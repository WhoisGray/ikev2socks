# 🐧 Alpine‑based production Dockerfile for IKEv2 → SOCKS5

FROM docker.arvancloud.ir/ghost:6.17.0-alpine

# Set env
ENV TIMEOUT=60
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install strongSwan + gost + basic utils
RUN apk update && \
    apk add --no-cache \
      strongswan \
      iproute2 \
      iptables && \
    rm -rf /var/cache/apk/*

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SOCKS port
EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]
