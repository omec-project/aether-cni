# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019-present Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

FROM golang:1.26.0-bookworm@sha256:eae3cdfa040d0786510a5959d36a836978724d03b34a166ba2e0e198baac9196 AS builder

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    wget && \
    wget -q https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz \
    && tar xvfz cni-plugins-linux-amd64-v0.9.1.tgz \
    && cp ./static /bin/static \
    && cp ./dhcp /bin/dhcp

FROM ghcr.io/jqlang/jq:1.8.1@sha256:4f34c6d23f4b1372ac789752cc955dc67c2ae177eb1b5860b75cdc5091ce6f91 AS jq

FROM centos/systemd@sha256:09db0255d215ca33710cc42e1a91b9002637eeef71322ca641947e65b7d53b58 AS aether-cni

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
COPY --from=nfvpe/sriov-cni:v2.5 /usr/bin/sriov .
COPY --from=builder /bin/static .
COPY --from=builder /bin/dhcp .
COPY --from=jq /jq .
