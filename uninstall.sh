#!/bin/zsh
# Stops clipclean and removes its login agent and binary.
set -euo pipefail

label=local.clipclean
bin="$HOME/.local/bin/clipclean"
plist="$HOME/Library/LaunchAgents/$label.plist"

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
for file in "$plist" "$bin"; do
  if [[ -e "$file" ]]; then rm "$file"; fi
done
echo "clipclean removed."
