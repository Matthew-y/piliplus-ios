import 'package:PiliPlus/utils/ios_style.dart';
import 'package:material_ui/material_ui.dart';

/// 自适应工具：在 iOS 外观下返回 Cupertino 版本，否则返回 Material 版本。
///
/// 判定依据是 [ThemeData.platform]。`ThemeUtils` 会根据「iOS 风格」开关把它
/// 设为 [TargetPlatform.iOS]，因此在 Android / 桌面上手动开启也能得到同样
/// 的 Cupertino 观感，且 Flutter 内建组件（`AppBar` 标题居中、`Scrollbar`、
/// `PageTransitionsTheme` 等）也会自动跟随。
abstract final class Adaptive {
  /// 当前主题是否呈现为 iOS 外观。
  static bool isIOS(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS;

  /// 二选一。
  static Widget pick(
    BuildContext context, {
    required Widget Function(BuildContext context) cupertino,
    required Widget Function(BuildContext context) material,
  }) => isIOS(context) ? cupertino(context) : material(context);
}

/// [Adaptive.isIOS] 的 ThemeData 版本。
extension AdaptiveTheme on ThemeData {
  bool get isIOS => platform == TargetPlatform.iOS;
}

/// 无 [BuildContext] 时的判定（用于静态方法、controller 初始化等场景）。
bool get isIOSStyleEnabled => IosStyle.isIOSStyleEnabled;
