#!/bin/sh

set -e

DARKLUA_CONFIG=$1
BUILD_OUTPUT=$2

if [ ! -d node_modules ]; then
    yarn install
    yarn prepare
fi

mkdir -p $BUILD_OUTPUT

darklua process --config $DARKLUA_CONFIG src/init.lua $BUILD_OUTPUT/data-handler.lua
