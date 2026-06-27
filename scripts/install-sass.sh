#!/usr/bin/env bash
#
# Build & install `sass` (SirCmpwn's Assembler, github.com/KnightOS/sass) — the
# assembler the KnightOS asm packages require. The KnightOS homebrew tap is gone
# (404), so we build from source. sass is a C# app; we build it with whatever
# .NET toolchain is available (dotnet or mono+msbuild), installing mono if needed.
#
# Result: /usr/local/bin/sass (a wrapper that runs the built sass.exe/.dll).
# Re-runnable. Verbose; ends with a line beginning "SASS-STATUS:".

set -u
SRC=/tmp/sass-src
# pick a PATH dir we can actually write to (/usr/local/bin is root-only on Apple Silicon)
if [ -w /opt/homebrew/bin ]; then PREFIX=/opt/homebrew/bin
elif [ -w /usr/local/bin ]; then PREFIX=/usr/local/bin
else PREFIX="$HOME/.local/bin"; mkdir -p "$PREFIX"; fi
LIB="$(dirname "$PREFIX")/lib/sass"
log() { echo ">> $*"; }
status() { echo "SASS-STATUS: $*"; }

# --- 0. already installed? ---
if command -v sass >/dev/null 2>&1; then
  status "already installed at $(command -v sass)"; sass --version 2>&1 | head -1; exit 0
fi

# --- 1. clone ---
log "cloning KnightOS/sass"
rm -rf "$SRC"
if ! git clone --depth 1 https://github.com/KnightOS/sass "$SRC" >/tmp/install-sass-clone.log 2>&1; then
  cat /tmp/install-sass-clone.log; status "FAILED clone"; exit 1
fi
log "repo contents:"; ls -la "$SRC"

# --- 2. pick / install a build tool ---
BUILDER=""
if command -v dotnet >/dev/null 2>&1; then BUILDER=dotnet
elif command -v msbuild >/dev/null 2>&1; then BUILDER=msbuild
elif command -v xbuild >/dev/null 2>&1; then BUILDER=xbuild
fi

if [ -z "$BUILDER" ]; then
  log "no .NET build tool found; installing mono via brew (this can take several minutes)"
  if command -v brew >/dev/null 2>&1; then
    brew install mono 2>&1 | tail -15 || true
  fi
  if command -v msbuild >/dev/null 2>&1; then BUILDER=msbuild
  elif command -v xbuild >/dev/null 2>&1; then BUILDER=xbuild
  elif command -v dotnet >/dev/null 2>&1; then BUILDER=dotnet
  fi
fi
[ -z "$BUILDER" ] && { status "FAILED — no dotnet/mono/msbuild available and could not install mono"; exit 1; }
log "using builder: $BUILDER"

# --- 3. build ---
cd "$SRC" || { status "FAILED cd"; exit 1; }
sln="$(find . -maxdepth 2 -name '*.sln' | head -1)"
proj="$(find . -maxdepth 2 -name 'sass.csproj' -o -maxdepth 2 -name '*.csproj' | head -1)"
target="${sln:-$proj}"
log "build target: ${target:-<Makefile?>}"

build_log=/tmp/install-sass-build.log
: > "$build_log"
if [ -f Makefile ]; then
  log "trying make"; make >>"$build_log" 2>&1 || true
fi
if [ -n "$target" ]; then
  case "$BUILDER" in
    dotnet)  dotnet build "$target" -c Release >>"$build_log" 2>&1 || dotnet build "$target" >>"$build_log" 2>&1 || true ;;
    msbuild) msbuild "$target" /p:Configuration=Release >>"$build_log" 2>&1 || msbuild "$target" >>"$build_log" 2>&1 || true ;;
    xbuild)  xbuild "$target" /p:Configuration=Release >>"$build_log" 2>&1 || xbuild "$target" >>"$build_log" 2>&1 || true ;;
  esac
fi

# --- 4. locate artifact ---
exe="$(find "$SRC" -name 'sass.exe' -type f 2>/dev/null | head -1)"
dll="$(find "$SRC" -name 'sass.dll' -type f 2>/dev/null | head -1)"
log "built exe: ${exe:-none}; dll: ${dll:-none}"

if [ -z "$exe" ] && [ -z "$dll" ]; then
  echo "---- last 40 lines of build log ----"; tail -40 "$build_log"
  status "FAILED — no sass.exe/.dll produced (see $build_log)"; exit 1
fi

# --- 5. install to a stable lib dir + wrapper on PATH ---
# copy the exe and ALL its sibling DLLs so dependencies travel with it
mkdir -p "$PREFIX" "$LIB"
artdir="$(dirname "${exe:-$dll}")"
# copy explicitly — an unquoted *.dll glob aborts the whole cp when there are no DLLs
[ -n "$exe" ] && cp "$exe" "$LIB"/ 2>/dev/null
[ -n "$dll" ] && cp "$dll" "$LIB"/ 2>/dev/null
cp "$artdir"/sass.exe.config "$LIB"/ 2>/dev/null || true
find "$artdir" -maxdepth 1 -name '*.dll' -exec cp {} "$LIB"/ \; 2>/dev/null || true
if [ -f "$LIB/sass.exe" ]; then
  printf '#!/bin/sh\nexec mono "%s/sass.exe" "$@"\n' "$LIB" > "$PREFIX/sass"
else
  printf '#!/bin/sh\nexec dotnet "%s/sass.dll" "$@"\n' "$LIB" > "$PREFIX/sass"
fi
chmod +x "$PREFIX/sass"
log "installed -> $PREFIX/sass (runtime in $LIB)"

# --- 6. verify ---
if "$PREFIX/sass" --version >/tmp/install-sass-verify.log 2>&1 || "$PREFIX/sass" --help >/tmp/install-sass-verify.log 2>&1; then
  status "OK -> $PREFIX/sass"; head -3 /tmp/install-sass-verify.log
else
  echo "---- verify output ----"; cat /tmp/install-sass-verify.log
  status "INSTALLED but verification command failed (binary may still work for assembling)"
fi
