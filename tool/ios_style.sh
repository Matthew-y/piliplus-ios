#!/bin/bash
# 切换模拟器里 PiliPlus 的「界面风格」设置（无需打开 App 点选）。
#
# 用法：
#   bash tool/ios_style.sh list              # 查看当前模式
#   bash tool/ios_style.sh follow            # 跟随系统
#   bash tool/ios_style.sh on                # 始终开启 iOS 风格
#   bash tool/ios_style.sh off               # 始终关闭（Material 观感）
#
# 改完需要重启 App 才生效（theme 在启动时构建）。
# 默认目标模拟器 iPhone 16e，可用 DEVICE_NAME / DEVICE 覆盖。
set -euo pipefail

# 按设备名运行时解析 UDID，避免把某个模拟器的 UDID 写死在脚本里。
# 同名设备可能有多个（不同 iOS runtime），优先取已开机的那个。
# 仍可用 DEVICE=<UDID> 或 DEVICE_NAME="iPhone 16e" 覆盖。
DEVICE_NAME="${DEVICE_NAME:-iPhone 16e}"
if [ -z "${DEVICE:-}" ]; then
  SIM_LIST=$(xcrun simctl list devices available | grep "${DEVICE_NAME} (" || true)
  DEVICE=$(printf '%s\n' "$SIM_LIST" | grep '(Booted)' \
    | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/' | head -n 1 || true)
  if [ -z "$DEVICE" ]; then
    DEVICE=$(printf '%s\n' "$SIM_LIST" \
      | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/' | head -n 1 || true)
  fi
fi
BUNDLE_ID="${BUNDLE_ID:-com.example.piliplus}"

if [ -z "$DEVICE" ]; then
  echo "错误：找不到模拟器 ${DEVICE_NAME}，请先在 Xcode → Devices and Simulators 添加" >&2
  exit 1
fi

case "${1:-list}" in
  list)  KEY=follow ;;
  follow) KEY=follow ;;
  on)    KEY=on ;;
  off)   KEY=off ;;
  *) echo "用法: $0 {list|follow|on|off}" >&2; exit 1 ;;
esac

# 找 App 的数据容器
CONTAINER=$(for c in "$HOME/Library/Developer/CoreSimulator/Devices/$DEVICE/data/Containers/Data/Application/"*/; do
  id=$(plutil -extract MCMMetadataIdentifier raw "$c/.com.apple.mobile_container_manager.metadata.plist" 2>/dev/null || true)
  [ "$id" = "$BUNDLE_ID" ] && echo "$c" && break
done)

if [ -z "$CONTAINER" ]; then
  echo "错误：找不到 $BUNDLE_ID 的数据容器（模拟器 $DEVICE 是否已启动并运行过 App？）" >&2
  exit 1
fi

HIVE="${CONTAINER%/}/Library/Application Support/hive"

case "$KEY" in
  follow) VALUE=0 ;;
  on)     VALUE=1 ;;
  off)    VALUE=2 ;;
esac

# Hive 文件被 App 占用时无法写入，先确保 App 已退出
if xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" 2>/dev/null; then
  echo "已停止 App"
  sleep 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cat > "$WORK_DIR/pubspec.yaml" <<'YAML'
name: hive_edit
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  hive_ce: 2.22.0
YAML

cat > "$WORK_DIR/main.dart" <<'DART'
import 'dart:io';
import 'package:hive_ce/hive.dart';

Future<void> main(List<String> args) async {
  Hive.init(args[0]);
  final box = await Hive.openBox<dynamic>('setting');
  await box.put(args[1], int.parse(args[2]));
  stdout.writeln('iosStyle = ${box.get(args[1])}');
  await box.close();
}
DART

cd "$WORK_DIR"
dart pub get >/dev/null 2>&1
dart run main.dart "$HIVE" iosStyle "$VALUE"
echo "请重新启动 App 使设置生效：flutter run -d $DEVICE"
