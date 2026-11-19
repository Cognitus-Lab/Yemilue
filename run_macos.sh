#!/usr/bin/env bash
# � Yemilue macOS Terminal Runner
# Run from terminal on any Mac: ./run_macos.sh [-o dataset.jsonl] [--csv dataset.csv]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

chmod +x "$DIR/yemilue" "$DIR/yemilue_macos" 2>/dev/null
exec "$DIR/yemilue" "$@"
