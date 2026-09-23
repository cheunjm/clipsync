#!/bin/bash
# Installs a LaunchAgent that runs bin/clipsync on a short interval.
#
# Usage:
#   ./install.sh <remote-host> [--interval SECONDS]
#
# Requires: macOS (both ends), pngpaste (brew install pngpaste),
# passwordless SSH key auth to <remote-host>.
set -euo pipefail

REMOTE_HOST="${1:?Usage: install.sh <remote-host> [--interval SECONDS]}"
shift
INTERVAL=2
while [ $# -gt 0 ]; do
  case "$1" in
    --interval) INTERVAL="$2"; shift 2 ;;
    *) echo "install.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "clipsync only supports macOS (uses pngpaste + osascript)." >&2
  exit 1
fi

if ! command -v pngpaste >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing pngpaste via Homebrew..."
    brew install pngpaste
  else
    echo "pngpaste not found and Homebrew not available. Install pngpaste manually." >&2
    exit 1
  fi
fi

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/clipsync"
cp "$SCRIPT_SRC" "$INSTALL_DIR/clipsync"
chmod +x "$INSTALL_DIR/clipsync"

PLIST_LABEL="com.clipsync.poller"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

launchctl bootout "gui/$(id -u)/$PLIST_LABEL" 2>/dev/null || true

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/clipsync</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>CLIPSYNC_REMOTE_HOST</key>
        <string>$REMOTE_HOST</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
    <key>StartInterval</key>
    <integer>$INTERVAL</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/clipsync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/clipsync.log</string>
</dict>
</plist>
PLIST

launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
echo "clipsync installed: polling every ${INTERVAL}s, pushing to ${REMOTE_HOST}"
