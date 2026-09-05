#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$ROOT_DIR/JailbreakDetector"
BUILD_DIR="$HOME/projects/jailbreak-detector-build"
OUTPUT_DIR="$SOURCE_DIR/output"
export THEOS="${THEOS:-$HOME/theos}"

if [[ ! -f "$THEOS/makefiles/common.mk" ]]; then
  echo "找不到 Theos: $THEOS" >&2
  exit 1
fi

echo "使用 Theos: $THEOS"
echo "开始编译独立 SwiftUI RootHide Detector（不会编译 Dopamine）..."

for command_name in rsync make zip; do
  command -v "$command_name" >/dev/null 2>&1 || { echo "缺少命令：$command_name" >&2; exit 1; }
done

if command -v ldconfig >/dev/null 2>&1 && ! ldconfig -p 2>/dev/null | grep -q 'libxml2\.so\.2'; then
  # Some Swift distributions ship the runtime library beside the toolchain.
  # Use it when available before asking the user to repair apt sources.
  SWIFT_XML2="$(find "$HOME" -type f -name 'libxml2.so.2*' 2>/dev/null | head -n 1 || true)"
  if [[ -n "$SWIFT_XML2" ]]; then
    export LD_LIBRARY_PATH="$(dirname "$SWIFT_XML2")${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    echo "使用 Swift 工具链自带的 libxml2：$SWIFT_XML2"
  else
    cat >&2 <<'EOF'
缺少 Swift 工具链依赖 libxml2.so.2，且当前 apt 没有可用的软件源。
请先执行：sudo apt update
然后按发行版尝试：sudo apt install -y libxml2 或 sudo apt install -y libxml2t64
如果仍提示没有 candidate，请检查 /etc/apt/sources.list* 是否配置了 Ubuntu/Debian 官方源。
EOF
    exit 1
  fi
fi

# 在 Linux 文件系统中编译，避免 /mnt/c 的权限、时间戳和 ldid 问题。
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
rsync -a --delete --exclude='.theos/' --exclude='packages/' --exclude='output/' "$SOURCE_DIR/" "$BUILD_DIR/"
make -C "$BUILD_DIR" clean package FINALPACKAGE=1

APP_DIR="$BUILD_DIR/.theos/_/Applications/JailbreakDetector.app"
[[ -d "$APP_DIR" ]] || { echo "未找到构建后的 App：$APP_DIR" >&2; exit 1; }

IPA_WORK="$BUILD_DIR/ipa-build"
rm -rf "$IPA_WORK"
mkdir -p "$IPA_WORK/Payload"
cp -a "$APP_DIR" "$IPA_WORK/Payload/"
(cd "$IPA_WORK" && zip -qry "$BUILD_DIR/JailbreakDetector.ipa" Payload)

rm -f "$OUTPUT_DIR/JailbreakDetector.ipa" "$OUTPUT_DIR"/*.deb
cp "$BUILD_DIR/JailbreakDetector.ipa" "$OUTPUT_DIR/"
cp "$BUILD_DIR"/packages/*.deb "$OUTPUT_DIR/"

echo "构建完成：$OUTPUT_DIR/JailbreakDetector.ipa"
