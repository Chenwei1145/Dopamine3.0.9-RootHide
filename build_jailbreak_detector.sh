#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
export THEOS="${THEOS:-$HOME/theos}"

if [[ ! -f "$THEOS/makefiles/common.mk" ]]; then
  echo "找不到 Theos: $THEOS" >&2
  exit 1
fi

echo "使用 Theos: $THEOS"
echo "开始编译独立 SwiftUI RootHide Detector（不会编译 Dopamine）..."
make -C "$ROOT_DIR/JailbreakDetector" clean package FINALPACKAGE=1

echo "构建产物：$ROOT_DIR/JailbreakDetector/packages/"
