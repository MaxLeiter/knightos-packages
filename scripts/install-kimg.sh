#!/usr/bin/env bash
#
# Build & install `kimg` (github.com/KnightOS/kimg) — KnightOS's PNG/image to
# KIMG converter, needed by package builds that ship icons (progcalc, rubik, ...).
# The KnightOS brew tap is gone, so build from source (it's a small C tool).
#
# Result: /opt/homebrew/bin/kimg. Re-runnable. Ends with a line "KIMG-STATUS:".

set -u
SRC=/tmp/kimg-src
# /usr/local/bin is root-only on Apple Silicon; prefer the writable brew bin
if [ -w /opt/homebrew/bin ]; then PREFIX=/opt/homebrew/bin
elif [ -w /usr/local/bin ]; then PREFIX=/usr/local/bin
else PREFIX="$HOME/.local/bin"; mkdir -p "$PREFIX"; fi
status(){ echo "KIMG-STATUS: $*"; }

if command -v kimg >/dev/null 2>&1; then status "already installed at $(command -v kimg)"; exit 0; fi

rm -rf "$SRC"
git clone --depth 1 https://github.com/KnightOS/kimg "$SRC" >/tmp/kimg-clone.log 2>&1 \
  || { echo "clone failed:"; tail -3 /tmp/kimg-clone.log; status "FAIL clone"; exit 1; }
cd "$SRC" || { status "FAIL cd"; exit 1; }
echo "repo files: $(ls)"

# build: CMake project preferred, else Makefile
log=/tmp/kimg-build.log
if [ -f CMakeLists.txt ]; then
  command -v cmake >/dev/null 2>&1 || brew install cmake >/tmp/kimg-cmake.log 2>&1
  ( cmake -DCMAKE_BUILD_TYPE=Release . && make ) >"$log" 2>&1
elif [ -f Makefile ]; then
  make >"$log" 2>&1
else
  status "FAIL: no CMakeLists.txt or Makefile"; exit 1
fi

bin="$(find "$SRC" -maxdepth 3 -type f -name kimg -perm -u+x 2>/dev/null | head -1)"
if [ -z "$bin" ]; then
  echo "--- build log tail ---"; tail -20 "$log"
  status "FAIL: no kimg binary (see $log)"; exit 1
fi
cp "$bin" "$PREFIX/kimg" && chmod +x "$PREFIX/kimg"
status "OK -> $PREFIX/kimg (from $bin)"
