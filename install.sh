#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
mkdir -p ~/bin
ln -sf "$(pwd)/.build/release/nanoremind" ~/bin/nanoremind
echo "nanoremind installed to ~/bin/nanoremind"
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$HOME/bin"; then
    echo "Warning: ~/bin is not in your PATH. Add it to your shell profile."
fi
