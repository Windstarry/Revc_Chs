#!/bin/bash
set -u
cd /src

DEFINES="-DAUDIO_OAL -DCMAKE_BUILD -DCMAKE_NO_AUTOLINK -DLIBRW -DLIBRW_SDL2 -DNDEBUG -DRW_GL3 -DUSE_OUR_VERSIONING"
INCLUDES="-I/src -I/src/src/animation -I/src/src/audio -I/src/src/audio/eax -I/src/src/audio/oal -I/src/src/buildings -I/src/src/collision -I/src/src/control -I/src/src/core -I/src/src/entities -I/src/src/extras -I/src/src/extras/shaders -I/src/src/fakerw -I/src/src/math -I/src/src/modelinfo -I/src/src/objects -I/src/src/peds -I/src/src/renderer -I/src/src/rw -I/src/src/save -I/src/src/skel -I/src/src/skel/glfw -I/src/src/skel/sdl2 -I/src/src/skel/win -I/src/src/text -I/src/src/vehicles -I/src/src/weapons -I/src/vendor/librw -isystem /usr/local/include/SDL2 -isystem /usr/include/AL"
FLAGS="-O3 -DNDEBUG -std=c++17 -fsyntax-only"

ERRFILE=/src/build_arm64/syntax_errors.txt
: > "$ERRFILE"

run_one() {
  f="$1"
  out=$(g++ $DEFINES $INCLUDES $FLAGS -c "$f" -o /dev/null 2>&1)
  if echo "$out" | grep -qE "error:"; then
    {
      echo "=== $f ==="
      echo "$out" | grep -E "error:"
    } >> "$ERRFILE"
  fi
}
export -f run_one
export DEFINES INCLUDES FLAGS ERRFILE

echo "[$(date +%H:%M:%S)] parallel syntax check start ($(nproc) procs) ..."
find src -name "*.cpp" -not -path "*/vendor/*" -print0 | xargs -0 -P"$(nproc)" -I{} bash -c 'run_one "$@"' _ {}
echo "[$(date +%H:%M:%S)] done"
echo "ERROR_FILES=$(grep -cE '^=== ' "$ERRFILE")"
