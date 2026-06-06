# IKEv2 (strongSwan) -> SOCKS5 (gost)
#
# Debian slim is used (not Alpine) because Alpine's strongSwan build does NOT
# ship the `eap-gtc` plugin, which ipsec.conf relies on (leftauth=eap-gtc).
# Debian's libcharon-extra-plugins provides eap-gtc and friends.

ARG BASE_IMAGE=docker.arvancloud.ir/debian:bookworm-slim
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="ikev2socks" \
      org.opencontainers.image.description="Turn an IKEv2 VPN into a local SOCKS5 proxy"

ENV TIMEOUT=60 \
    SOCKS5_PORT=1080 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Optional Debian apt mirror override (e.g. if deb.debian.org is blocked on your
# network): --build-arg APT_MIRROR=http://mirror.arvancloud.ir/debian
# Left empty by default to use the image's stock (consistent) deb.debian.org sources.
# http:// is fine: apt verifies packages via GPG signatures.
ARG APT_MIRROR=

# gost release to install: https://github.com/go-gost/gost/releases
ARG GOST_VERSION=3.2.6
ARG GOST_BASE_URL=https://github.com/go-gost/gost/releases/download

RUN set -eux; \
    if [ -n "$APT_MIRROR" ]; then \
        printf 'Types: deb\nURIs: %s\nSuites: bookworm\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n' "$APT_MIRROR" \
            > /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        strongswan \
        strongswan-starter \
        libcharon-extra-plugins \
        iproute2 \
        iptables \
        ca-certificates \
        curl; \
    update-ca-certificates; \
    # Fetch the gost binary (no distro package exists for it); match the image arch
    case "$(dpkg --print-architecture)" in \
        amd64) GOST_ARCH=amd64 ;; \
        arm64) GOST_ARCH=arm64 ;; \
        armhf) GOST_ARCH=armv7 ;; \
        i386)  GOST_ARCH=386 ;; \
        *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "${GOST_BASE_URL}/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${GOST_ARCH}.tar.gz" -o /tmp/gost.tgz; \
    tar -xzf /tmp/gost.tgz -C /usr/local/bin gost; \
    chmod +x /usr/local/bin/gost; \
    gost -V; \
    rm -rf /tmp/gost.tgz /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# SOCKS5 port (informational; ignored when the container runs with host networking)
EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]
