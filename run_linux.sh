#!/usr/bin/env bash
# ============================================================================
# � Yemilue Linux Launcher
# Run on any Linux PC from flash drive
# ============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ -f "$DIR/yemilue_linux" ]; then
    chmod +x "$DIR/yemilue_linux"
    exec "$DIR/yemilue_linux" "$@"
fi

if command -v cargo >/dev/null 2>&1; then
    echo "[yemilue] Running via Cargo using offline vendored crates..."
    exec cargo run --release -- "$@"
fi

echo "[ERROR] Neither yemilue_linux nor cargo found."
exit 1
