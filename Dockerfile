# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019-present Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

ARG CNI_PLUGINS_VERSION=v1.9.1

FROM golang:1.26.2-bookworm@sha256:4f4ab2c90005e7e63cb631f0b4427f05422f241622ee3ec4727cc5febbf83e34 AS builder

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

FROM ghcr.io/jqlang/jq:1.8.1@sha256:4f34c6d23f4b1372ac789752cc955dc67c2ae177eb1b5860b75cdc5091ce6f91 AS jq

FROM ghcr.io/k8snetworkplumbingwg/sriov-cni:v2.10.0@sha256:0f225c399f080445c70ff6ca5c8439c607f515688a24c7a65b733cf758e76376 AS sriov-cni

FROM ghcr.io/k8snetworkplumbingwg/sriov-network-device-plugin:v3.11.0@sha256:7c5901727d4500f103f038c178b41dc6450afa6f324306c1973495c9a7c4f5a5 AS sriov-device-plugin

FROM alpine:3.23@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS aether-cni

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
