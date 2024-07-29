#!/usr/bin/env bash

set -euo pipefail

SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cd $SCRIPT_RELATIVE_DIR

roc build --optimize --profiling merge.roc --output roc-mergesort

roc build --optimize --profiling builtin.roc --output roc-builtinsort

zig build-exe -OReleaseFast -fno-strip raw-builtin.zig
mv raw-builtin zig-raw-builtinsort

clang++ -O3 -g quadsort.cc -o cc-quadsort

clang++ -O3 -g fluxsort.cc -o cc-fluxsort

if command -v poop &> /dev/null; then
    poop ./roc-mergesort ./roc-builtinsort ./zig-raw-builtinsort ./cc-quadsort ./cc-fluxsort
elif command -v hyperfine &> /dev/null; then
    hyperfine -w 10 -r 100 ./roc-mergesort ./roc-builtinsort ./zig-raw-builtinsort ./cc-quadsort ./cc-fluxsort
else
  echo "Warning: Could not find a benchmarking tool. Just running once direct...\n"
  echo "roc-mergesort"
  ./roc-mergesort
  echo "roc-builtinsort"
  ./roc-builtinsort
  echo "zig-raw-builtinsort"
  ./zig-raw-builtinsort
  echo "cc-quadsort"
  ./cc-quadsort
  echo "cc-fluxsort"
  ./cc-fluxsort
fi
