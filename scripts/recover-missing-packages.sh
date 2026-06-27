#!/usr/bin/env bash
#
# Recover the community packages that were on the original packages.knightos.org
# but are missing from this mirror, by BUILDING each from source with the
# KnightOS SDK and importing the resulting .pkg + manifest.json into packages/.
#
# Safe to re-run. Requires: git, make, and the KnightOS SDK (knightos/scas/kpack/genkfs).
#
# The SDK fetches build-time dependencies (corelib, kernel-headers, ...) from a
# package repository. Since the official one is down, we point it at this mirror
# by default. Override with KNIGHTOS_REPOSITORY_URL.
#
# REQUIREMENTS / GOTCHAS (learned the hard way):
#   1. The ASSEMBLY packages (fx3dlib, progcalc, rubik, ztetris, demos) assemble
#      with `sass` (SirCmpwn's Assembler). `scas` is NOT a flag-compatible
#      substitute (it rejects sass's --encoding). Install sass first:
#          brew install knightos/knightos/sass
#      (or build github.com/KnightOS/sass; it needs mono).
#   2. DEPENDENCY PUBLISH ORDER. The SDK resolves deps from the LIVE mirror, not
#      this local packages/ dir. The C template depends on extra/libc, and
#      extra/demos depends on extra/fx3dlib. So this is a TWO-STAGE process:
#        Stage 1:  ... libc fx3dlib progcalc rubik ztetris   # only core deps
#                  -> commit & DEPLOY to the mirror
#        Stage 2:  ... pong tunnel demos                     # need libc/fx3dlib live
#                  -> commit & deploy
#
# Usage: scripts/recover-missing-packages.sh [package-name ...]
#   No args = all (in dependency order). Args = only those names.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"
BUILD_DIR="${KO_BUILD_DIR:-/tmp/ko-build}"
export KNIGHTOS_REPOSITORY_URL="${KNIGHTOS_REPOSITORY_URL:-https://knightos-packages.vercel.app}"

# Built in this order so deps (libc, fx3dlib) exist before their dependents.
# namespace  name      git-url
TARGETS="
extra     libc     https://github.com/KnightOS/libc
extra     fx3dlib  https://github.com/matrefeytontias/fx3dlib
community pong     https://github.com/MaxLeiter/pong
community progcalc https://github.com/boos1993/progcalc
community tunnel   https://github.com/Axenntio/KOS-TunnelGame
extra     demos    https://github.com/KnightOS/demos
ports     rubik    https://github.com/Ivoah/rubik
ports     ztetris  https://github.com/unlimitedbacon/ztetris
"

ONLY="$*"
mkdir -p "$BUILD_DIR"
echo "Using KNIGHTOS_REPOSITORY_URL=$KNIGHTOS_REPOSITORY_URL"
echo

want() {
  [ -z "$ONLY" ] && return 0
  for w in $ONLY; do [ "$w" = "$1" ] && return 0; done
  return 1
}
cfg() { grep "^$1=" "$2" 2>/dev/null | head -1 | cut -d= -f2- | sed 's/^"//; s/"$//'; }

printf '%s\n' "$TARGETS" | while read -r ns name url; do
  [ -z "${ns:-}" ] && continue
  want "$name" || continue
  echo "==================================================================="
  echo ">>> $ns/$name  ($url)"
  src="$BUILD_DIR/$name"

  # --- fresh clone every time (avoids stale committed artifacts) ---
  rm -rf "$src"
  if ! git clone --depth 1 "$url" "$src" >"$BUILD_DIR/clone-$name.log" 2>&1; then
    echo "    CLONE FAILED:"; tail -5 "$BUILD_DIR/clone-$name.log" | sed 's/^/      /'; continue
  fi

  # never trust a .pkg that shipped in the repo; we build our own
  find "$src" -maxdepth 2 -name '*.pkg' -delete 2>/dev/null

  conf="$src/package.config"
  version="$(cfg version "$conf")"

  # --- build ---
  # A fresh clone lacks the generated .knightos/ scaffolding (variables.make,
  # sdk.make) and build deps; `knightos init --reinit-missing` regenerates them
  # and installs dependencies from KNIGHTOS_REPOSITORY_URL, then `make` builds.
  echo "    building (v${version:-?})..."
  (
    cd "$src" &&
    knightos init --reinit-missing &&
    # Workaround: some packages (e.g. libc) cp headers into include/ subdirs
    # without mkdir -p'ing them first. Pre-create the subdir tree mirroring include/.
    { [ -d include ] && find include -type d -exec mkdir -p "bin/root/{}" \; 2>/dev/null; true; } &&
    make package
  ) >"$BUILD_DIR/build-$name.log" 2>&1
  pkg="$(find "$src" -maxdepth 2 -name '*.pkg' -type f 2>/dev/null | head -1)"

  if [ -z "$pkg" ]; then
    echo "    BUILD FAILED — last lines of build-$name.log:"
    tail -15 "$BUILD_DIR/build-$name.log" | sed 's/^/      /'
    continue
  fi
  echo "    built: $(basename "$pkg")"

  # --- metadata (force canonical namespace + name) ---
  description="$(cfg description "$conf" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  copyright="$(cfg copyright "$conf")"; [ -z "$copyright" ] && copyright="$(cfg license "$conf")"
  deps="$(cfg dependencies "$conf")"
  [ -z "$version" ] && version="$(basename "$pkg" .pkg | sed "s/^$name-//")"

  deps_json="[]"
  if [ -n "$deps" ]; then
    deps_json="["; first=1
    for dep in $deps; do
      if [ $first -eq 1 ]; then deps_json="$deps_json\"$dep\""; first=0; else deps_json="$deps_json, \"$dep\""; fi
    done
    deps_json="$deps_json]"
  fi

  target="$PACKAGES_DIR/$ns/$name"
  mkdir -p "$target"
  rm -f "$target"/*.pkg
  cp "$pkg" "$target/"
  cat > "$target/manifest.json" <<EOF
{
  "name": "$name",
  "repo": "$ns",
  "full_name": "$ns/$name",
  "version": "$version",
  "description": "$description",
  "copyright": "$copyright",
  "dependencies": $deps_json
}
EOF
  echo "    installed -> packages/$ns/$name/ ($(basename "$pkg"))"
done

echo "==================================================================="
echo "Done. Build logs: $BUILD_DIR/build-*.log"
