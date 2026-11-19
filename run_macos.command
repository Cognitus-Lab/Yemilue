#!/bin/bash
# � Yemilue macOS Double-Clickable Launcher
# Double-click this file from Finder on ANY Mac (Intel or Apple Silicon)

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

chmod +x "$DIR/yemilue" "$DIR/yemilue_macos" 2>/dev/null

echo "================================================================================"
echo "� Starting Yemilue from flash drive..."
echo "� Working Directory: $DIR"
echo "================================================================================"

"$DIR/yemilue" "$@"
