#!/usr/bin/env sh

export SRC_DIR=./proto
export DST_DIR=./lib/data/models

protoc -I=$SRC_DIR --dart_out=$DST_DIR $SRC_DIR/vector_tile.proto
