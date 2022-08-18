FROM ubuntu:20.04

ENV DOCKER_CHANNEL=stable \
    DOCKER_VERSION=20.10.9 \
    DOCKER_HOST=unix:///host/run/docker.sock

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt dist-upgrade -y \
    && apt install -y ca-certificates jq dnsutils wget curl iptables strace tcpdump gnupg stunnel \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && curl https://downloads.apache.org/cassandra/KEYS | apt-key add - \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC59E6B43FA6E3CA \
    && echo "deb https://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && echo "deb https://downloads.apache.org/cassandra/debian 311x main" > /etc/apt/sources.list.d/cassandra.sources.list \
    && echo "deb https://ppa.launchpadcontent.net/redislabs/redis/ubuntu focal main" > /etc/apt/sources.list.d/redis.sources.list \
    && apt update && apt install -y postgresql-client-12 cassandra-tools redis-tools \
    && rm -rf /var/lib/apt/list/*

RUN set -eux; \
    \
    arch="$(uname --m)"; \
    case "$arch" in \
        # amd64
        x86_64) dockerArch='x86_64' ;; \
        # arm32v6
        armhf) dockerArch='armel' ;; \
        # arm32v7
        armv7) dockerArch='armhf' ;; \
        # arm64v8
        aarch64) dockerArch='aarch64' ;; \
        *) echo >&2 "error: unsupported architecture ($arch)"; exit 1 ;;\
    esac; \
    \
    if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
        echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
        exit 1; \
    fi; \
    \
    tar --extract \
        --file docker.tgz \
        --strip-components 1 \
        --directory /usr/local/bin/ \
    ; \
    rm docker.tgz; \
    \
    dockerd --version; \
    docker --version
