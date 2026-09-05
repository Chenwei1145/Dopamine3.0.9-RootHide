#!/usr/bin/env bash
set -euo pipefail

# Build only the TouchPoint RootHide package (Dopamine is never built here).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export THEOS="${THEOS:-$HOME/theos}"

die() { echo "错误: $*" >&2; exit 1; }

[[ -f "$THEOS/makefiles/common.mk" ]] || die "找不到 Theos: $THEOS"
[[ -d "$THEOS/vendor/mod/roothide" ]] || die "当前 Theos 不是 RootHide 版本: $THEOS"
compgen -G "$THEOS/sdks/*.sdk" >/dev/null || die "找不到 iOS SDK，请先安装到 $THEOS/sdks"
[[ -x "$THEOS/toolchain/linux/iphone/bin/clang" ]] || die "找不到 iOS clang 工具链"

if ! command -v ldid >/dev/null 2>&1; then
    die "找不到 ldid，请先安装 ldid"
fi
if [[ ! -x "$(command -v ldid)" ]]; then
    die "ldid 没有执行权限: $(command -v ldid)（运行 sudo chmod 755 $(command -v ldid)）"
fi

echo "使用 Theos: $THEOS"
echo "开始编译 TouchPoint（不会编译 Dopamine）..."
# Git/DrvFS may rewrite text files with CRLF; Debian control files must use LF.
sed -i 's/\r$//' "$ROOT/TouchPoint/control" "$ROOT/TouchPoint/TouchPoint.plist" "$ROOT/TouchPoint/layout/DEBIAN/postinst" 2>/dev/null || true
rm -rf "$ROOT/TouchPoint/.theos"
make -C "$ROOT/TouchPoint" clean package

PKG="$(find "$ROOT/TouchPoint/packages" -maxdepth 1 -type f -name '*.deb' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)"
[[ -n "$PKG" && -f "$PKG" ]] || die "编译结束但没有找到 .deb"
echo
echo "编译成功: $PKG"
