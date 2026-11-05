import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:material_ui/material_ui.dart';

/// iOS 分组列表的「自定义行」容器。
///
/// 收藏 / 历史 / 稍后再看 / 关注 四个列表区的行都是自带复杂布局的
/// （封面 + 多行文字 + 收藏按钮 / 更多菜单 / 选择遮罩），装不进
/// `CupertinoListTile`；而 [PLListSection] 只能接收固定的 `children`，
/// 无法嵌在 `SliverList` / `SliverGrid` 里。所以这里补两个可复用的
/// 小容器，四个页面共用一份，不各写各的圆角与颜色。
///
/// - [PLGroupedCard]：网格里的单个卡片（四角 10pt）。
/// - [PLGroupedRow]：分组列表里的一行（首项上圆角、末项下圆角、中间直角，
///   行与行之间 0.5pt hairline）。
///
/// 两者在 Material 皮肤下都**原样返回 [child]**，不改变原有布局与观感。
class PLGroupedCard extends StatelessWidget {
  const PLGroupedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isIOS(context)) return child;
    const borderRadius = BorderRadius.all(Radius.circular(10));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: IosColors.secondaryGroupedBackground(
          Theme.of(context).brightness,
        ),
        borderRadius: borderRadius,
      ),
      // 裁掉封面溢出的部分，圆角才干净。
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

/// iOS 分组列表的单行：白卡 + 首/末项 10pt 圆角 + 0.5pt hairline。
///
/// [isFirst] / [isLast] 由调用方按索引给出；单行列表两者都传 `true`。
/// [margin] 只在 iOS 下生效，用于给分组卡片留左右外边距，
/// 这样 Material 分支的缩进、分隔线、行高都保持原样。
class PLGroupedRow extends StatelessWidget {
  const PLGroupedRow({
    super.key,
    required this.child,
    required this.isFirst,
    required this.isLast,
    this.dividerIndent = 16,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;

  /// hairline 左侧缩进，和文字左边缘对齐（有头像的行约 71）。
  final double dividerIndent;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isIOS(context)) return child;
    final brightness = Theme.of(context).brightness;
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(isFirst ? 10 : 0),
      bottom: Radius.circular(isLast ? 10 : 0),
    );
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: IosColors.secondaryGroupedBackground(brightness),
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (!isLast)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: dividerIndent,
                  color: IosColors.separator(brightness),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 列表页级别的 iOS 分组参数。
abstract final class PLGrouped {
  /// 分组列表的外边距：iOS 左右各 16pt，Material 保持调用方原值。
  ///
  /// [top] / [bottom] 传 Material 分支原来的值，iOS 只在顶部补 5pt
  /// 让第一张卡片离导航栏 / Tab 栏有一点呼吸空间。
  static EdgeInsets sliverPadding(
    BuildContext context, {
    required double top,
    required double bottom,
  }) {
    if (!Adaptive.isIOS(context)) {
      return EdgeInsets.only(top: top, bottom: bottom);
    }
    return EdgeInsets.only(
      top: top + 5,
      left: 16,
      right: 16,
      bottom: bottom,
    );
  }

  /// 网格卡片的代理：卡片之间留 10pt 间距，避免白色卡片贴在一起。
  ///
  /// 只在 iOS 分支使用；Material 继续走 `GridMixin.gridDelegate` 的原值。
  static SliverGridDelegate cardGridDelegate({
    required double maxCrossAxisExtent,
    double mainAxisExtent = 110,
    double spacing = 10,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      mainAxisExtent: mainAxisExtent,
      maxCrossAxisExtent: maxCrossAxisExtent,
    );
  }

  /// 与 `SliverGridDelegateWithMaxCrossAxisExtent` 内部完全相同的列数算法。
  ///
  /// 判「单列 / 多列」必须用调用点自己的 delegate 参数算，
  /// 这样用户改了「卡片宽度」或换到 iPad 时会自动跟着变，不需要新开关。
  static int crossAxisCount({
    required double crossAxisExtent,
    required double maxCrossAxisExtent,
    double crossAxisSpacing = 0,
  }) {
    final count = (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing))
        .ceil();
    return count < 1 ? 1 : count;
  }

  /// 视频列表的容器：Material 原样网格；iOS 单列走连续分组行、多列走卡片网格。
  ///
  /// 用 [SliverLayoutBuilder] 拿真实的横向可用宽度（已扣掉 [sliverPadding] 的
  /// 16pt 外边距），按 [materialGridDelegate] 的列数决定形态：
  ///
  /// - 1 列：`SliverList` + [PLGroupedRow]（首项上圆角、末项下圆角、行间 hairline）；
  /// - ≥2 列：`SliverGrid` + [PLGroupedCard]（每格一张独立圆角卡片）。
  ///
  /// 单列时给每行套上与网格相同的 `mainAxisExtent` 高度，保证行内
  /// `AspectRatio` 封面拿到和网格里一致的约束，两种形态的封面尺寸不跳变。
  ///
  /// iOS 两种形态的格子高度都比 [materialGridDelegate] 多 [iosExtentDelta]：
  /// 行内的「更多 / 移除」按钮是 44pt 点击区，而 `Stack` 的 hitTest 以自身
  /// size 为界，探出卡片的那截既不给子节点也不给父节点。把行高抬高 5pt 后，
  /// 按钮可以 `bottom: 0` 贴着卡片下沿完整落在行内，图标视觉中心又与
  /// 原来（110 高 + `bottom: -5`）一致，不需要改图标位置。
  static const double iosExtentDelta = 5;
  static Widget sliverGridOrList({
    required BuildContext context,
    required SliverGridDelegate materialGridDelegate,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    if (!Adaptive.isIOS(context)) {
      return SliverGrid.builder(
        gridDelegate: materialGridDelegate,
        itemBuilder: itemBuilder,
        itemCount: itemCount,
      );
    }
    final delegate = materialGridDelegate;
    final maxCrossAxisExtent =
        delegate is SliverGridDelegateWithMaxCrossAxisExtent
        ? delegate.maxCrossAxisExtent
        : 480.0;
    final crossAxisSpacing =
        delegate is SliverGridDelegateWithMaxCrossAxisExtent
        ? delegate.crossAxisSpacing
        : 0.0;
    final mainAxisExtent = delegate is SliverGridDelegateWithMaxCrossAxisExtent
        ? delegate.mainAxisExtent ?? 110
        : 110.0;
    final iosMainAxisExtent = mainAxisExtent + iosExtentDelta;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final count = crossAxisCount(
          crossAxisExtent: constraints.crossAxisExtent,
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
        );
        if (count > 1) {
          return SliverGrid.builder(
            gridDelegate: cardGridDelegate(
              maxCrossAxisExtent: maxCrossAxisExtent,
              mainAxisExtent: iosMainAxisExtent,
            ),
            itemBuilder: (context, index) =>
                PLGroupedCard(child: itemBuilder(context, index)),
            itemCount: itemCount,
          );
        }
        return SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => PLGroupedRow(
            isFirst: index == 0,
            isLast: index == itemCount - 1,
            // 五个列表区的行内水平内边距都是 12（Style.safeSpace），
            // hairline 从内容左边缘起算，和封面左边缘对齐。
            dividerIndent: 12,
            child: SizedBox(
              height: iosMainAxisExtent,
              child: itemBuilder(context, index),
            ),
          ),
        );
      },
    );
  }
}
