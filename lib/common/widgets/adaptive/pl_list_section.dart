import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoListSection, CupertinoListTile;
import 'package:material_ui/material_ui.dart';

/// 标记「当前处于分组内」。
///
/// 由 [PLListSection] 提供，让内部的条目自动切换成「分组条目」形态
/// （透明底色、由 section 提供分隔线与内边距）。
class PLInSection extends InheritedWidget {
  const PLInSection({super.key, required super.child});

  /// 当前是否处于分组内。
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PLInSection>() != null;

  @override
  bool updateShouldNotify(PLInSection oldWidget) => false;
}

/// iOS 分组列表（inset grouped）。
///
/// iOS 的设置类列表不是平铺在背景上，而是若干个**圆角卡片**分组，
/// 组与组之间留白，组内条目由 hairline 分隔。这与 Material 的
/// 「全屏平铺 + 分割线」观感差别很大，是 iOS 最具辨识度的列表样式。
///
/// 内部直接用官方的 [CupertinoListSection.insetGrouped]，
/// 它会自动处理圆角卡片背景、组内分隔线的缩进、组标题/脚注样式，
/// 比自己画更准确。
class PLListSection extends StatelessWidget {
  const PLListSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<Widget> children;

  /// 分组标题（如「外观」）。
  final Widget? header;

  /// 分组底部的说明文字。
  final Widget? footer;

  /// 分组左右外边距。
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PLInSection(
      child: CupertinoListSection.insetGrouped(
        margin: margin,
        // CupertinoListSection 默认用固定的 systemGroupedBackground /
        // secondarySystemGroupedBackground，不跟随 App 主题色，
        // 会和页面上其它区域（搜索框、留白）的背景对不上。
        // 这里统一改成 iOS 语义色：
        // - 卡片外侧用 systemGroupedBackground（浅灰，跟页面底色一致）
        // - 卡片本身用 systemBackground（纯白）
        backgroundColor: IosColors.groupedBackground(theme.brightness),
        decoration: BoxDecoration(
          color: IosColors.secondaryGroupedBackground(theme.brightness),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        header: header == null
            ? null
            : DefaultTextStyle(
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.outline,
                ),
                child: header!,
              ),
        footer: footer == null
            ? null
            : DefaultTextStyle(
                style: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.outline,
                ),
                child: footer!,
              ),
        children: children,
      ),
    );
  }
}

/// 分组列表的单个条目。
///
/// iOS 的条目有明确的左右内边距（16pt），图标 29pt，标题 17pt。
class PLListSectionTile extends StatelessWidget {
  const PLListSectionTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 是否在右侧显示 iOS 风格的 chevron 箭头。
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoListTile(
      leading: leading == null
          ? null
          : colorfulIcon(leading!, key: _titleText(title)),
      title: title ?? const SizedBox.shrink(),
      subtitle: subtitle,
      trailing: trailing,
      additionalInfo: showChevron
          ? Icon(
              // 用 Material 的箭头：项目没有引入 Cupertino 图标字体，
              // CupertinoIcons 会渲染成方块。
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.outline.withValues(alpha: 0.6),
            )
          : null,
      onTap: onTap,
    );
  }

  /// 从标题文本取一个稳定的颜色 key（保证 rebuild 时颜色不跳变）。
  static String _titleText(Widget? title) =>
      title is Text ? (title.data ?? '') : '';

  /// iOS 设置页的图标是**圆角彩色方块 + 白色符号**（SF Symbols 的容器形态）。
  ///
  /// 项目没有引入 Cupertino 图标字体（`CupertinoIcons` 会渲染成方块），
  /// 所以这里保留 Material 的符号，只把容器做成 iOS 的样子——
  /// 这是 iOS 设置页最显眼的视觉特征。
  ///
  /// [key] 用于稳定选色：相同 key 永远得到同一种颜色。
  static Widget colorfulIcon(Widget icon, {String key = ''}) {
    const palette = [
      Color(0xFF34C759), // 绿
      Color(0xFF007AFF), // 蓝
      Color(0xFF5856D6), // 靛
      Color(0xFFFF9500), // 橙
      Color(0xFFFF2D55), // 红
      Color(0xFF00C7BE), // 青
      Color(0xFFFFCC00), // 黄
    ];
    final color = palette[key.hashCode.abs() % palette.length];
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white, size: 18),
        child: icon,
      ),
    );
  }
}
