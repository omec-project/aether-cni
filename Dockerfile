# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019-present Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

FROM golang:1.24.6-bookworm AS builder

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    wget && \
    wget -q https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz \
    && tar xvfz cni-plugins-linux-amd64-v0.9.1.tgz \
    && cp ./static /bin/static \
    && cp ./dhcp /bin/dhcp

FROM ghcr.io/jqlang/jq:1.8.1 AS jq

FROM centos/systemd@sha256:09db0255d215ca33710cc42e1a91b9002637eeef71322ca641947e65b7d53b58 AS aether-cni
WORKDIR /tmp/cni/bin
COPY vfioveth .
COPY --from=nfvpe/sriov-cni:v2.5 /usr/bin/sriov .
COPY --from=builder /bin/static .
COPY --from=builder /bin/dhcp .
COPY --from=jq /jq .
