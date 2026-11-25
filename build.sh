#!/bin/zsh
# Compiles clipclean into build/clipclean.
set -euo pipefail
cd "${0:A:h}"
mkdir -p build
swiftc -O -wmo -Xlinker -dead_strip Sources/*.swift -o build/clipclean
echo "built build/clipclean ($(stat -f %z build/clipclean) bytes)"
