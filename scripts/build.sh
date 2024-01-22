#!/bin/sh

set -e

./scripts/build-roblox-asset.sh .darklua.json build
./scripts/build-single-file.sh .darklua-bundle.json build
