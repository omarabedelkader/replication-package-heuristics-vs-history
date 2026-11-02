#!/usr/bin/env bash
# Fetch the pinned sources and build the benchmark image, once: everything lands in $STORE/base and
# later runs (and every resumed job) reuse it, so that all projects start from the very same image.
#
#   bin/prepare.sh            build what is missing
#   bin/prepare.sh --force    rebuild the base image (never do this while checkpoints exist:
#                             checkpoints of the old image would then resume next to a different one)
set -euo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PKG/config.sh"

FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1
BASE="$STORE/base"
SRC="$STORE/src"
VM_DIR="$BASE/vm-$(uname -s)-$(uname -m)"
mkdir -p "$BASE" "$SRC"

log() { echo "==> [$(date +%H:%M:%S)] $*"; }

checkout() { # url commit dir [branch]
  local url="$1" commit="$2" dir="$3" branch="${4:-}"
  if [ ! -d "$dir/.git" ]; then
    log "Cloning $url"
    git clone --quiet ${branch:+--branch "$branch"} "$url" "$dir"
  fi
  git -C "$dir" fetch --quiet origin
  if [ "$commit" = latest ]; then commit="origin/${branch:-HEAD}"; fi
  git -C "$dir" checkout --quiet --detach "$commit"
  log "$(basename "$dir") at $(git -C "$dir" rev-parse HEAD)"
}

# 1. Sources ---------------------------------------------------------------------------------------
if [ ! -f "$BASE/bench-base.image" ] || [ "$FORCE" = 1 ]; then
  checkout "$HCH_REPO" "$HCH_COMMIT" "$SRC/HeuristicCompletion-History" "$HCH_BRANCH"
  checkout "$HCB_REPO" "$HCB_COMMIT" "$SRC/HeuristicCompletion-Benchmarks"
fi

# 2. Pharo VM for this platform (the image is the same everywhere, the VM is not) -------------------
if [ ! -x "$VM_DIR/pharo" ]; then
  log "Downloading the Pharo 14 VM for $(uname -s)-$(uname -m)"
  rm -rf "$VM_DIR.tmp"; mkdir -p "$VM_DIR.tmp"
  (cd "$VM_DIR.tmp" && curl -fsSL "$PHARO_URL" | bash >/dev/null)
  rm -rf "$VM_DIR"; mv "$VM_DIR.tmp" "$VM_DIR"
fi

# 3. Base image: Pharo 14 + the benchmark (group Bench) + the replication additions -----------------
if [ -f "$BASE/bench-base.image" ] && [ "$FORCE" = 0 ]; then
  log "Base image already built: $BASE/bench-base.image"
  exit 0
fi
if [ "$FORCE" = 1 ] && ls "$STORE"/checkpoints/*.tar.* >/dev/null 2>&1; then
  echo "Refusing to rebuild the base image: checkpoints exist in $STORE/checkpoints." >&2
  exit 1
fi

BUILD="$(mktemp -d "${TMPDIR:-/tmp}/hvh-build.XXXXXX")"
trap 'rm -rf "$BUILD"' EXIT
cp -R "$VM_DIR"/. "$BUILD"/
cd "$BUILD"
mv Pharo.image build.image; mv Pharo.changes build.changes
sed -e "s|@HCH@|$SRC/HeuristicCompletion-History|g" -e "s|@HCB@|$SRC/HeuristicCompletion-Benchmarks|g" \
  -e "s|@PKG@|$PKG|g" "$PKG/pharo/install.st" > install.st

log "Loading the benchmark and the replication additions into a fresh Pharo 14 image"
if ! ./pharo build.image st --save --quit install.st > "$BASE/install.log" 2>&1 \
   || ! grep -q "BASE IMAGE OK" "$BASE/install.log"; then
  echo "Building the base image failed, see $BASE/install.log" >&2
  exit 1
fi

mv build.image "$BASE/bench-base.image"
mv build.changes "$BASE/bench-base.changes"
cp ./*.sources "$BASE/"
{
  echo "built:   $(date -Iseconds) on $(hostname)"
  echo "pharo:   $(ls ./*.sources)"
  echo "history: $(git -C "$SRC/HeuristicCompletion-History" rev-parse HEAD) ($HCH_REPO)"
  echo "bench:   $(git -C "$SRC/HeuristicCompletion-Benchmarks" rev-parse HEAD) ($HCB_REPO)"
} > "$BASE/versions.txt"
log "Base image ready: $BASE/bench-base.image"
cat "$BASE/versions.txt"
