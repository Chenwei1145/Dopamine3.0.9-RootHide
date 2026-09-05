#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
export THEOS="${THEOS:-$HOME/theos}"

if [[ ! -f "$THEOS/makefiles/common.mk" ]]; then
  echo "找不到 Theos: $THEOS" >&2
  exit 1
fi

if [[ "$(uname -s)" == "Linux" ]]; then
  cat >&2 <<'EOF'
当前环境是 Linux/WSL。Theos 的 application.mk 不支持在 Linux 上构建 iOS SwiftUI 应用，
因此 JailbreakDetector（SwiftUI）不能用这个命令编译。请在 macOS + Xcode 上构建，
或告诉我改成 UIKit/Objective-C 版本以便继续使用 WSL Theos。
EOF
  exit 2
fi

echo "使用 Theos: $THEOS"
echo "开始编译独立 SwiftUI RootHide Detector（不会编译 Dopamine）..."
make -C "$ROOT_DIR/JailbreakDetector" clean package FINALPACKAGE=1

echo "构建产物：$ROOT_DIR/JailbreakDetector/packages/"
