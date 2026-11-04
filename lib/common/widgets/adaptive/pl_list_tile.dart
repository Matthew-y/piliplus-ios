import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_section.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoListTile;
// fork 的 ListTile 用的是 material_ui 的 VisualDensity / ListTileTitleAlignment，
// 不能混用 flutter/material 的同名类型（它们是两个不同包里的独立类）。
// 因此这里 hide 掉 flutter/material 的 ListTile，其余类型统一从 material_ui 取。
import 'package:material_ui/material_ui.dart' hide ListTile;

/// 列表项适配组件。
///
/// iOS 外观下用 [CupertinoListTile]，其余保持 [ListTile]。
///
/// 参数与 Material 的 [ListTile] 对齐，调用点只需改类名。
///
/// 注意 `CupertinoListTile` 的能力弱于 Material 版：没有 `enabled` / `dense` /
/// `onLongPress` / `titleTextStyle`，因此这些参数在 iOS 外观下会被降级处理
/// （禁用态用半透明表示，长按与自定义文字样式不生效）。
class PLListTile extends StatelessWidget {
  const PLListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.dense,
    this.contentPadding,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.horizontalTitleGap,
    this.visualDensity,
    this.textColor,
    this.iconColor,
    this.selectedColor,
    this.tileColor,
    this.selectedTileColor,
    this.splashColor,
    this.focusColor,
    this.hoverColor,
    this.shape,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.enableFeedback,
    this.titleAlignment,
    this.safeArea = false,
    this.isThreeLine,
    this.onTapUp,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onTapUp;
  final bool enabled;
  final bool selected;
  final bool? dense;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextStyle? leadingAndTrailingTextStyle;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  final double? minTileHeight;
  final double? horizontalTitleGap;
  final VisualDensity? visualDensity;
  final Color? textColor;
  final Color? iconColor;
  final Color? selectedColor;
  final Color? tileColor;
  final Color? selectedTileColor;
  final Color? splashColor;
  final Color? focusColor;
  final Color? hoverColor;
  final ShapeBorder? shape;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool? enableFeedback;
  final ListTileTitleAlignment? titleAlignment;
  final bool safeArea;
  final bool? isThreeLine;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOS(context)) {
      // 在分组内时底色与分隔线由 CupertinoListSection 统一提供，
      // 独立使用时才用自己的背景色。
      final inSection = PLInSection.of(context);
      return Opacity(
        opacity: enabled ? 1 : 0.5,
        child: CupertinoListTile(
          // 设置子页的图标也用和主页一致的「圆角彩色方块」，
          // 否则同一套 iOS 设置里会出现两种图标形态。
          leading: leading == null
              ? null
              : PLListSectionTile.colorfulIcon(
                  leading!,
                  key: _titleText(title),
                ),
          title: _styled(title, titleTextStyle) ?? const SizedBox.shrink(),
          subtitle: _styled(subtitle, subtitleTextStyle),
          trailing: trailing,
          onTap: enabled ? onTap : null,
          backgroundColor: inSection ? null : tileColor,
          backgroundColorActivated: inSection ? null : selectedTileColor,
          padding: inSection ? null : contentPadding,
        ),
      );
    }
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      onTapUp: onTapUp,
      enabled: enabled,
      selected: selected,
      dense: dense,
      contentPadding: contentPadding,
      titleTextStyle: titleTextStyle,
      subtitleTextStyle: subtitleTextStyle,
      leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
      minTileHeight: minTileHeight,
      horizontalTitleGap: horizontalTitleGap,
      visualDensity: visualDensity,
      textColor: textColor,
      iconColor: iconColor,
      selectedColor: selectedColor,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      splashColor: splashColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      shape: shape,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: enableFeedback,
      titleAlignment: titleAlignment,
      safeArea: safeArea,
      isThreeLine: isThreeLine,
    );
  }

  /// `CupertinoListTile` 不接受外部文字样式，用 `DefaultTextStyle` 补上。
  static Widget? _styled(Widget? child, TextStyle? style) {
    if (child == null) return null;
    if (style == null) return child;
    return DefaultTextStyle(style: style, child: child);
  }

  /// 从标题文本取一个稳定的颜色 key，供 [PLListSectionTile.colorfulIcon] 选色。
  static String _titleText(Widget? title) =>
      title is Text ? (title.data ?? '') : '';
}
