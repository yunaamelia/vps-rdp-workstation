# =============================================================================
# Custom Molecule Test Image - Debian Trixie
# Pre-installs common dependencies to speed up molecule test runs
# Usage: Referenced by molecule.yml configs via Dockerfile.j2
# =============================================================================
FROM debian:trixie

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       systemd \
       systemd-sysv \
       python3 \
       python3-apt \
       sudo \
       bash \
       apt-utils \
       gnupg \
       ca-certificates \
       curl \
       wget \
       iproute2 \
       procps \
       lsb-release \
       dbus \
    && rm -rf /tmp/* /var/tmp/*

VOLUME ["/sys/fs/cgroup"]
CMD ["/lib/systemd/systemd"]
