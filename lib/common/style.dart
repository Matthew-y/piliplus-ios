import 'package:PiliPlus/utils/ios_style.dart';
import 'package:material_ui/material_ui.dart'
    show BorderRadius, Radius, BoxConstraints, ButtonStyle, VisualDensity;

abstract final class Style {
  static const cardSpace = 8.0;
  static const safeSpace = 12.0;
  static const mdRadius = BorderRadius.all(imgRadius);
  static const imgRadius = Radius.circular(10);
  static const borderRadius6 = BorderRadius.all(.circular(6));
  static const aspectRatio = 16 / 10;
  static const aspectRatio16x9 = 16 / 9;
  static const aspectRatio3x4 = 3 / 4;
  static const imgMaxRatio = 2.6;
  static const bottomSheetRadius = BorderRadius.vertical(top: .circular(18));
  static const dialogFixedConstraints = BoxConstraints.tightFor(width: 420);

  /// 顶栏高度。
  ///
  /// iOS 风格下顶栏只有搜索框一行（36 + 上下留白），比 Material 略高一点
  /// （Material 的搜索框是 44 高）。滚动收起逻辑（`barOffset`）依赖这个值，
  /// 所以要跟着风格走。
  static double get topBarHeight =>
      IosStyle.isIOSStyleEnabled ? iosTopBarHeight : materialTopBarHeight;

  static const materialTopBarHeight = 52.0;

  /// iOS 顶栏：搜索框 36 + 上下留白 12。
  static const iosTopBarHeight = 48.0;

  static const buttonStyle = ButtonStyle(
    visualDensity: VisualDensity(horizontal: -2, vertical: -1.25),
    tapTargetSize: .shrinkWrap,
  );
  static const placeHolder = '\uFFFC';
}
