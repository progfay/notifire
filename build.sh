#!/bin/sh
# Usage: ./build.sh [output path] (default: ./notifire)
set -eu
out="${1:-notifire}"
mkdir -p "$(dirname "$out")"
swiftc -O "$(dirname "$0")/notifire.swift" -o "$out"
