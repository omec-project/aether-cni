# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019-present Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

ARG CNI_PLUGINS_VERSION=v1.9.1

FROM golang:1.26.4-bookworm@sha256:5f68ec6805843bd3981a951ffada82a26a0bd2631045c8f7dba483fa868f5ec5 AS builder

ARG CNI_PLUGINS_VERSION

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    wget && \
    wget -q https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz \
    && wget -q https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz.sha256 \
    && sha256sum -c cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz.sha256 \
    && tar xvfz cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz \
    && cp ./static /bin/static \
    && cp ./dhcp /bin/dhcp

FROM ghcr.io/jqlang/jq:1.8.2@sha256:b9c68867e5766576263a222e91db3de422d802069c7af70440e667a95344e486 AS jq

FROM ghcr.io/k8snetworkplumbingwg/sriov-cni:v2.10.0@sha256:0f225c399f080445c70ff6ca5c8439c607f515688a24c7a65b733cf758e76376 AS sriov-cni

FROM ghcr.io/k8snetworkplumbingwg/sriov-network-device-plugin:v3.11.0@sha256:7c5901727d4500f103f038c178b41dc6450afa6f324306c1973495c9a7c4f5a5 AS sriov-device-plugin

FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS aether-cni

RUN apk add --no-cache \
    bash \
    coreutils \
    findutils \
    gawk \
    grep \
    hwdata-pci \
    iproute2

RUN mkdir -p /usr/share/misc && \
    ln -sf /usr/share/hwdata/pci.ids /usr/share/misc/pci.ids

# Build arguments for dynamic labels
ARG VERSION=dev
ARG VCS_URL=unknown
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.source="${VCS_URL}" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.url="${VCS_URL}" \
    org.opencontainers.image.title="aether-cni" \
    org.opencontainers.image.description="Aether 5G Core AETHER-CNI Network Function" \
    org.opencontainers.image.authors="Aether SD-Core <dev@lists.aetherproject.org>" \
    org.opencontainers.image.vendor="Aether Project" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.documentation="https://docs.sd-core.aetherproject.org/"

WORKDIR /tmp/cni/bin
COPY vfioveth .
COPY --from=sriov-cni /usr/bin/sriov .
COPY --from=sriov-device-plugin /entrypoint.sh /entrypoint.sh
COPY --from=sriov-device-plugin /usr/bin/sriovdp /usr/bin/sriovdp
COPY --from=builder /bin/static .
COPY --from=builder /bin/dhcp .
COPY --from=jq /jq ./jq

CMD ["/entrypoint.sh"]
