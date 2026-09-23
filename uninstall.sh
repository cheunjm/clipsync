#!/bin/bash
# Removes the clipsync LaunchAgent and installed script.
set -euo pipefail

PLIST_LABEL="com.clipsync.poller"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

launchctl bootout "gui/$(id -u)/$PLIST_LABEL" 2>/dev/null || true
rm -f "$PLIST_PATH"
rm -f "$HOME/.local/bin/clipsync"

echo "clipsync uninstalled."
