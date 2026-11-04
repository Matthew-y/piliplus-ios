import 'package:material_ui/material_ui.dart';

/// iOS 系统语义色。
///
/// 需求里点名的那几个色（`systemGroupedBackground` / `systemBackground` /
/// `systemGray5`）在 Flutter 的 [ColorScheme] 里没有一一对应的，
/// 这里按 iOS 的实际取值手写，避免用 Material 的粉色系 surface 顶替。
abstract final class IosColors {
  /// B 站品牌粉。iOS 风格下的强调色（底栏选中、分段控件、侧栏选中、
  /// 进度条填充等）固定用它，不再跟随 M3 主题色派生出的偏紫色。
  static const brandPink = Color(0xFFFB7299);

  /// 浅色模式下的系统分组背景（#F2F2F7）。
  static const groupedBackgroundLight = Color(0xFFF2F2F7);

  /// 深色模式下的系统分组背景（#000000）。
  static const groupedBackgroundDark = Color(0xFF000000);

  /// 浅色模式下的二级分组背景 / 内容卡片（#FFFFFF）。
  static const secondaryGroupedBackgroundLight = Color(0xFFFFFFFF);

  /// 深色模式下的二级分组背景（#1C1C1E）。
  static const secondaryGroupedBackgroundDark = Color(0xFF1C1C1E);

  /// 浅色模式下的 `systemGray5`（输入框底色，#E3E3E8）。
  static const gray5Light = Color(0xFFE3E3E8);

  /// 深色模式下的 `systemGray5`（#3A3A3C）。
  static const gray5Dark = Color(0xFF3A3A3C);

  /// 浅色模式下的 `systemGray4`（按压高亮，#D1D1D6）。
  static const gray4Light = Color(0xFFD1D1D6);

  /// 深色模式下的 `systemGray4`（#3A3A3C）。
  static const gray4Dark = Color(0xFF3A3A3C);

  /// 浅色模式下的分隔线（`separator`，#C6C6C8）。
  static const separatorLight = Color(0xFFC6C6C8);

  /// 深色模式下的分隔线（#38383A）。
  static const separatorDark = Color(0xFF38383A);

  /// 浅色模式下的次要文字（`secondaryLabel`，#3C3C43 60%）。
  static const secondaryLabelLight = Color(0x993C3C43);

  /// 深色模式下的次要文字（#EBEBF5 60%）。
  static const secondaryLabelDark = Color(0x99EBEBF5);

  /// 当前主题下的分组背景（页面底色）。
  static Color groupedBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? groupedBackgroundDark
      : groupedBackgroundLight;

  /// 当前主题下的内容卡片背景。
  static Color secondaryGroupedBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? secondaryGroupedBackgroundDark
      : secondaryGroupedBackgroundLight;

  /// 当前主题下的输入框底色。
  static Color gray5(Brightness brightness) =>
      brightness == Brightness.dark ? gray5Dark : gray5Light;

  /// 当前主题下的按压高亮色。
  static Color gray4(Brightness brightness) =>
      brightness == Brightness.dark ? gray4Dark : gray4Light;

  /// 当前主题下的分隔线。
  static Color separator(Brightness brightness) =>
      brightness == Brightness.dark ? separatorDark : separatorLight;

  /// 当前主题下的次要文字色。
  static Color secondaryLabel(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryLabelDark : secondaryLabelLight;

  /// 顶部工具条（搜索栏 / Tab 栏 / 图标行）的底色。
  ///
  /// 浅色用纯白；深色必须跟随 `canvasColor`——状态栏那条留白由 `MainApp`
  /// 的 `Material` 上色（默认即 canvasColor），写死纯黑会在顶部露出一道色带。
  static Color headerBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.canvasColor
        : Colors.white;
  }
}
