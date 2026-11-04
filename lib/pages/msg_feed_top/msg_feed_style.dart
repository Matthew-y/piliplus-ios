import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:material_ui/material_ui.dart';

/// 消息子页（回复 / @我 / 收到的赞 / 系统通知 / 点赞详情）的列表外观。
///
/// 这些页面共有同一套「头像 + 多行文字」的通知行，但此前仍沿用 Material 的
/// 全宽平铺 + 6px 灰色粗分隔线。消息主页已经是 iOS 分组卡片，子页再这样画会
/// 在「界面风格 = 始终开启」时出现列表 Material、弹窗 iOS 的割裂观感。
///
/// 这里只统一**背景与分隔线**：iOS 用白卡底色 + 0.5pt hairline，Material 分支
/// 保持原样，避免改动现有 Material 用户的观感。
abstract final class MsgFeedStyle {
  /// 分组卡片背景色；Material 皮肤返回 `null`（沿用列表默认背景）。
  static Color? tileColor(BuildContext context) {
    if (!Adaptive.isIOS(context)) return null;
    return IosColors.secondaryGroupedBackground(Theme.of(context).brightness);
  }

  /// 列表分隔线。
  ///
  /// iOS：0.5pt hairline，颜色取系统 separator；
  /// Material：保持原来的 6px 粗间距 + 淡灰线。
  ///
  /// [indent] 用于和文字左边缘对齐（有头像的页面约 72，纯文字页面 16）。
  /// [iosIndent] 仅在 iOS 下覆盖 [indent]（例如系统通知没有头像，缩进更小）。
  static Widget divider(
    BuildContext context, {
    double indent = 72,
    double? iosIndent,
  }) {
    if (!Adaptive.isIOS(context)) {
      return Divider(
        indent: indent,
        endIndent: 20,
        height: 6,
        color: Colors.grey.withValues(alpha: 0.1),
      );
    }
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: iosIndent ?? indent,
      color: IosColors.separator(Theme.of(context).brightness),
    );
  }

  /// iOS 下给分组列表首/末项加 10pt 圆角；Material 原样返回。
  static Widget card(
    BuildContext context,
    Widget child, {
    required bool isFirst,
    required bool isLast,
  }) {
    if (!Adaptive.isIOS(context)) return child;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isFirst ? 10 : 0),
        bottom: Radius.circular(isLast ? 10 : 0),
      ),
      child: child,
    );
  }

  /// iOS 分组卡片左右留白；Material 为 0。
  static EdgeInsets sliverPadding(BuildContext context) =>
      Adaptive.isIOS(context)
      ? const EdgeInsets.symmetric(horizontal: 16)
      : EdgeInsets.zero;
}
