#!/usr/bin/env bash
# Called by the Pharo image right after it saved itself (HVH_CHECKPOINT_HOOK). The image waits for
# this script, so its directory does not change meanwhile: the archive is a consistent state.
# The previous archive is replaced only once the new one is complete.
set -euo pipefail
unset LD_LIBRARY_PATH   # inherited from the VM launcher: use the system libraries
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"
p="$1"
mkdir -p "$STORE/checkpoints"

if command -v zstd >/dev/null; then ext=zst; compress=(zstd -q -T4 -3)
else ext=gz; compress=(gzip -1); fi

tmp="$STORE/checkpoints/.$p.tar.$ext.tmp"
# package-cache only holds copies of downloaded .mcz files; the VM links are made again at restore.
tar -C "$WORK/projects" --exclude="$p/pharo-local/package-cache" -cf - "$p" | "${compress[@]}" > "$tmp"
rm -f "$STORE/checkpoints/$p".tar.*
mv "$tmp" "$STORE/checkpoints/$p.tar.$ext"
echo "[hvh] archived $p: $(du -h "$STORE/checkpoints/$p.tar.$ext" | cut -f1)"
