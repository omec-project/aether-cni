# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019-present Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

FROM golang:1.25.6-bookworm@sha256:2f768d462dbffbb0f0b3a5171009f162945b086f326e0b2a8fd5d29c3219ff14 AS builder

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    wget && \
    wget -q https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz \
    && tar xvfz cni-plugins-linux-amd64-v0.9.1.tgz \
    && cp ./static /bin/static \
    && cp ./dhcp /bin/dhcp

FROM ghcr.io/jqlang/jq:1.8.1@sha256:4f34c6d23f4b1372ac789752cc955dc67c2ae177eb1b5860b75cdc5091ce6f91 AS jq

FROM centos/systemd@sha256:09db0255d215ca33710cc42e1a91b9002637eeef71322ca641947e65b7d53b58 AS aether-cni
WORKDIR /tmp/cni/bin
COPY vfioveth .
COPY --from=nfvpe/sriov-cni:v2.5 /usr/bin/sriov .
COPY --from=builder /bin/static .
COPY --from=builder /bin/dhcp .
COPY --from=jq /jq .
