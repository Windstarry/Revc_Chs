#!/bin/bash
set -eo pipefail

echo "[$(date +%H:%M:%S)] 安装 arm64 构建依赖 ..."
apt-get update -qq 2>&1 | tail -1
apt-get install -y --no-install-recommends \
  cmake make git \
  libgl1-mesa-dev:arm64 libsdl2-dev:arm64 libglu1-mesa-dev:arm64 \
  libopenal-dev:arm64 libmpg123-dev:arm64 \
  libx11-dev:arm64 libxrandr-dev:arm64 libxinerama-dev:arm64 libxcursor-dev:arm64 \
  libxi-dev:arm64 libxkbcommon-dev:arm64 libasound2-dev:arm64 2>&1 | tail -1

cd /src
rm -rf build_real
mkdir -p build_real
cd build_real

echo "[$(date +%H:%M:%S)] 配置 cmake (GL3 + SDL2 + OAL) ..."
cmake .. -DLIBRW_PLATFORM=GL3 -DLIBRW_GL3_GFXLIB=SDL2 -DREVC_AUDIO=OAL -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -20

echo "[$(date +%H:%M:%S)] 开始全量编译 ($(nproc) 进程) ..."
make -j"$(nproc)" 2>&1 | tee /src/build_arm64/build.log
echo "[$(date +%H:%M:%S)] 编译完成，退出码 ${PIPESTATUS[0]}"

BIN=/src/build_real/src/reVC
if [ ! -x "$BIN" ]; then
  echo "ERROR: 产物不存在或不可执行: $BIN"
  exit 1
fi

echo "=== ELF 架构校验 ==="
file "$BIN"

echo "[$(date +%H:%M:%S)] 部署产物到 /gtavc_mod ..."
cp "$BIN" /gtavc_mod/reVC_gl
chmod +x /gtavc_mod/reVC_gl

echo "[$(date +%H:%M:%S)] 提取运行时库到 /gtavc_mod/libs ..."
mkdir -p /gtavc_mod/libs
for lib in libSDL2-2.0.so.0 libopenal.so.1 libmpg123.so.0; do
  src="/usr/lib/aarch64-linux-gnu/$lib"
  if [ -e "$src" ]; then
    cp -L "$src" "/gtavc_mod/libs/$lib"
    echo "  复制 $lib ($(du -h "$src" | cut -f1))"
  else
    echo "  WARN: 未找到 $src"
  fi
done

echo "[$(date +%H:%M:%S)] 校验 NEEDED 库 ..."
aarch64-linux-gnu-objdump -p "$BIN" 2>/dev/null | grep NEEDED || true

echo "[$(date +%H:%M:%S)] 全部完成。"
