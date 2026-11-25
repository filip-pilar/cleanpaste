#!/bin/zsh
# Builds clipclean and installs it as a login agent for your user account.
# Safe to run again after editing Sources/Rules.swift: it rebuilds and reloads.
set -euo pipefail
cd "${0:A:h}"

label=local.clipclean
bin="$HOME/.local/bin/clipclean"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"

mkdir -p build "${bin:h}" "${plist:h}"
swiftc -O -wmo -Xlinker -dead_strip Sources/*.swift -o build/clipclean

# Stop a running copy before replacing it.
if launchctl print "$domain/$label" &>/dev/null; then
  launchctl bootout "$domain/$label" || true
  while launchctl print "$domain/$label" &>/dev/null; do sleep 0.1; done
fi

# Copy under a temporary name, then rename, so the binary is swapped in one step.
cp build/clipclean "$bin.new"
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
echo "clipclean is running and will start at every login."
echo "  binary  $bin"
echo "  agent   $plist"
echo "Remove it with ./uninstall.sh"
