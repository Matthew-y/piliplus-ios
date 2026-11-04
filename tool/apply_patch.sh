#!/bin/bash
# 用 bash 复现 lib/scripts/patch.ps1 的行为（本机没有 PowerShell）。
#
# 用途：本地验证构建。CI 仍走 patch.ps1，两边保持等价。
#
# 用法：bash tool/apply_patch.sh ios|android|macos
#
# 会做三件事：
#   1. 给 Flutter SDK 自身打补丁（packages/flutter 里的 widget 实现）
#   2. 给 pub cache 里的 material_ui 打补丁
#   3. 给 pub cache 里的 cupertino_ui 打补丁

set -euo pipefail

PLATFORM="${1:-ios}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_ROOT="${FLUTTER_ROOT:-/Users/matt/development/flutter}"
PUB_CACHE_DIR="$HOME/.pub-cache/hosted/pub.dev"

cd "$ROOT"

# ---- Flutter SDK 自身的补丁 ----
SDK_PATCHES=(
  "lib/scripts/modal_barrier.patch"
  "lib/scripts/text_selection.patch"
  "lib/scripts/mouse_cursor.patch"
  "lib/scripts/image_anim.patch"
  "lib/scripts/layout_builder.patch"
  "lib/scripts/navigation_drawer.patch"
  "lib/scripts/popup_menu.patch"
  "lib/scripts/fab.patch"
  "lib/scripts/null_safety_for_selectable_region.patch"
  "lib/scripts/selectable_region.patch"
  "lib/scripts/editable_text.patch"
  "lib/scripts/text_field.patch"
  "lib/scripts/scroll_position.patch"
  "lib/scripts/scrollable.patch"
  "lib/scripts/scrollable_gesture.patch"
  "lib/scripts/draggable_scrollable_sheet.patch"
  "lib/scripts/scaffold.patch"
  "lib/scripts/text.patch"
  "lib/scripts/text_painter.patch"
  "lib/scripts/sliver.patch"
  "lib/scripts/refresh_indicator.patch"
  "lib/scripts/double_tap_gesture.patch"
)

case "$PLATFORM" in
  android)
    SDK_PATCHES+=("lib/scripts/bottom_sheet_android.patch")
    SDK_PATCHES+=("lib/scripts/scroll_view.patch")
    SDK_PATCHES+=("lib/scripts/navigator.patch")
    ;;
  ios)
    SDK_PATCHES+=("lib/scripts/scroll_view.patch")
    SDK_PATCHES+=("lib/scripts/bottom_sheet_ios_flutter.patch")
    SDK_PATCHES+=("lib/scripts/navigator.patch")
    ;;
esac

echo "==> 给 Flutter SDK 打补丁（${PLATFORM}）"
cd "$FLUTTER_ROOT"
git checkout -- . 2>/dev/null || true
for p in "${SDK_PATCHES[@]}"; do
  if git apply --check "$ROOT/$p" 2>/dev/null; then
    git apply "$ROOT/$p"
    echo "  applied $(basename "$p")"
  else
    echo "  skip（已应用或不匹配）$(basename "$p")"
  fi
done

# ---- material_ui ----
echo "==> 给 material_ui 打补丁"
cd "$ROOT"
export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter pub get >/dev/null

MATERIAL_UI_DIR=$(ls -d "$PUB_CACHE_DIR"/material_ui-* 2>/dev/null | tail -1)
if [ -z "$MATERIAL_UI_DIR" ]; then
  echo "错误：pub cache 里找不到 material_ui" >&2
  exit 1
fi

MATERIAL_PATCHES=(
  "lib/scripts/material/modal_barrier_material.patch"
  "lib/scripts/material/navigation_drawer.patch"
  "lib/scripts/material/popup_menu.patch"
  "lib/scripts/material/fab.patch"
  "lib/scripts/material/text_field.patch"
  "lib/scripts/material/scaffold.patch"
  "lib/scripts/material/refresh_indicator.patch"
  "lib/scripts/material/tabs.patch"
)
case "$PLATFORM" in
  android) MATERIAL_PATCHES+=("lib/scripts/material/bottom_sheet_android.patch") ;;
  ios)     MATERIAL_PATCHES+=("lib/scripts/material/bottom_sheet_ios_flutter_material.patch") ;;
esac

cd "$MATERIAL_UI_DIR"
for p in "${MATERIAL_PATCHES[@]}"; do
  if git apply --check "$ROOT/$p" 2>/dev/null; then
    git apply "$ROOT/$p"
    echo "  applied $(basename "$p")"
  else
    echo "  skip（已应用或不匹配）$(basename "$p")"
  fi
done

# ---- cupertino_ui ----
echo "==> 给 cupertino_ui 打补丁"
CUPERTINO_UI_DIR=$(ls -d "$PUB_CACHE_DIR"/cupertino_ui-* 2>/dev/null | tail -1)
if [ -z "$CUPERTINO_UI_DIR" ]; then
  echo "错误：pub cache 里找不到 cupertino_ui" >&2
  exit 1
fi

cd "$CUPERTINO_UI_DIR"
if [ "$PLATFORM" = "ios" ] && git apply --check "$ROOT/lib/scripts/cupertino/bottom_sheet_ios_flutter.patch" 2>/dev/null; then
  git apply "$ROOT/lib/scripts/cupertino/bottom_sheet_ios_flutter.patch"
  echo "  applied bottom_sheet_ios_flutter.patch"
else
  echo "  skip（已应用或不匹配）bottom_sheet_ios_flutter.patch"
fi

echo "==> 完成"
