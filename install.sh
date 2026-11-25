#!/bin/sh
# Installs, updates or removes cleanpaste as a login agent for your user account.
#
#   curl -fsSL https://raw.githubusercontent.com/filip-pilar/cleanpaste/main/install.sh | sh
#       install the latest release, or update to it
#   curl -fsSL https://raw.githubusercontent.com/filip-pilar/cleanpaste/main/install.sh | sh -s -- --uninstall
#       remove it
#   ./install.sh    run inside a checkout: build from source instead (after editing rules)
set -eu

repo=filip-pilar/cleanpaste
asset=cleanpaste-macos-universal
label=local.cleanpaste
bin="$HOME/.local/bin/cleanpaste"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"

stop() {
  if launchctl print "$domain/$label" >/dev/null 2>&1; then
    launchctl bootout "$domain/$label" 2>/dev/null || true
    while launchctl print "$domain/$label" >/dev/null 2>&1; do sleep 0.1; done
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  stop
  for file in "$plist" "$bin"; do
    if [ -e "$file" ]; then rm "$file"; fi
  done
  echo "cleanpaste removed."
  exit 0
fi

for brew_label in sh.brew.cleanpaste homebrew.mxcl.cleanpaste; do
  if launchctl print "$domain/$brew_label" >/dev/null 2>&1; then
    echo "cleanpaste is already running from Homebrew. Update it with: brew upgrade cleanpaste" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$bin")" "$(dirname "$plist")"
here=$(cd "$(dirname "$0")" && pwd)
if [ -f "$here/Sources/main.swift" ]; then
  echo "Building from source in $here"
  swiftc -O -wmo -Xlinker -dead_strip "$here"/Sources/*.swift -o "$bin.new"
else
  echo "Downloading the latest release"
  curl -fsSL "https://github.com/$repo/releases/latest/download/$asset" -o "$bin.new"
  chmod 755 "$bin.new"
fi

stop
mv -f "$bin.new" "$bin"

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$bin</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

launchctl bootstrap "$domain" "$plist"
echo "cleanpaste is running and starts at every login."
echo "  update  run the same command again"
echo "  remove  add: sh -s -- --uninstall"
