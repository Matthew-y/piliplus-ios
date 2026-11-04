import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueNotifier, defaultTargetPlatform;

/// iOS 外观模式。
///
/// - [followSystem]：跟随运行平台，iOS 上开启、其他平台关闭（默认）。
/// - [alwaysOn]：无论什么平台都开启，便于在 Android / 桌面端对比效果。
/// - [alwaysOff]：无论什么平台都关闭。
enum IosStyleMode with EnumWithLabel {
  followSystem('跟随系统'),
  alwaysOn('始终开启'),
  alwaysOff('始终关闭');

  const IosStyleMode(this.label);

  @override
  final String label;

  static IosStyleMode fromIndex(int? index) =>
      index == null || index < 0 || index >= values.length
      ? IosStyleMode.followSystem
      : values[index];
}

/// iOS 风格开关。
///
/// 判定一律走 [ThemeData.platform]（见 [Pref.iosStyleTargetPlatform]），
/// 这样 Android / 桌面上手动开启也能得到同样的 Cupertino 观感，
/// 而不需要在业务代码里散落 `Platform.isIOS` 判断。
abstract final class IosStyle {
  /// 风格切换后自增，`MyApp` 监听它重建主题，避免「提示重启但只有部分生效」。
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// 当前模式。
  static IosStyleMode get mode =>
      IosStyleMode.fromIndex(Pref.iosStyleModeIndex);

  /// 写入模式并通知主题重建。
  static Future<void> setMode(IosStyleMode mode) async {
    await GStorage.setting.put(SettingBoxKey.iosStyle, mode.index);
    revision.value++;
  }

  /// 该模式下应当呈现的平台。
  ///
  /// 设为 [TargetPlatform.iOS] 时，Flutter 内建的 `AppBar.centerTitle`、
  /// `Scrollbar`、`PageTransitionsTheme` 等会自动切换成 iOS 表现。
  ///
  /// [IosStyleMode.alwaysOff] 只把 iOS 映射成 Android，桌面平台保持原样——
  /// 否则会连带改变桌面的页面转场等行为。
  static TargetPlatform get targetPlatform => switch (mode) {
    IosStyleMode.followSystem => defaultTargetPlatform,
    IosStyleMode.alwaysOn => TargetPlatform.iOS,
    IosStyleMode.alwaysOff =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? TargetPlatform.android
          : defaultTargetPlatform,
  };

  /// 在给定平台下是否启用 iOS 外观。
  static bool isEnabled(TargetPlatform platform) =>
      platform == TargetPlatform.iOS;

  /// 当前是否处于 iOS 外观（不依赖 BuildContext）。
  static bool get isIOSStyleEnabled => isEnabled(targetPlatform);
}
