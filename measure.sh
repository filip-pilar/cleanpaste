#!/bin/zsh
# Reports what clipclean costs over a window (default 30 s): ./measure.sh [seconds]
# Measures the installed agent if it is running, otherwise a temporary copy on a
# private pasteboard.
set -euo pipefail
cd "${0:A:h}"
window=${1:-30}
[[ -x build/usage ]] || swiftc -O Tests/usage.swift -o build/usage

if pid=$(pgrep -x clipclean | head -1) && [[ -n "$pid" ]]; then
  echo "measuring the running clipclean (pid $pid)"
else
  [[ -x build/clipclean ]] || ./build.sh
  CLIPCLEAN_PASTEBOARD="clipclean-measure-$$" build/clipclean &
  pid=$!
  trap 'kill $pid 2>/dev/null || true' EXIT
  echo "measuring a temporary clipclean (pid $pid)"
fi
build/usage $pid $window
