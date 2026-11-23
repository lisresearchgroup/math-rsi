#!/bin/sh
# Build verify_a (static, portable x86-64-v2 so it runs on any Cluster node).
set -e
cd "$(dirname "$0")"
gcc -O3 -march=x86-64-v2 -mpopcnt -Wall -Wextra -static -pthread -o verify_a verify_a.c
ldd verify_a 2>&1 | head -1
