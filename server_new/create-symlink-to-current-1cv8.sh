#!/bin/bash
set -e

platform_path=$(find / -type f -name "ragent" -exec dirname {} \; 2>/dev/null | head -n 1)

mkdir -p /opt/1cv8 \
    && ln -s $platform_path /opt/1cv8/current
