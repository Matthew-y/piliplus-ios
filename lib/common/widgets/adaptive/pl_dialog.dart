import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        CupertinoAlertDialog,
        CupertinoDialogAction,
        CupertinoTheme,
        showCupertinoDialog,
        showCupertinoModalPopup;
import 'package:material_ui/material_ui.dart';

/// 确认对话框适配组件（iOS 版）。
///
/// Material 版见 `dialog.dart` 的 `showConfirmDialog`——那里保留了原有的
/// `Get.back` 关闭逻辑，不在这里统一，以避免改变既有行为。
Future<bool> showPLConfirmDialog({
  required BuildContext context,
  required Widget title,
  Widget? content,
  String cancelText = '取消',
  String confirmText = '确认',
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: title,
      content: content,
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        CupertinoDialogAction(
          isDefaultAction: !destructive,
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 操作表适配组件（iOS 版）。
///
/// 视觉完全交给系统的 [CupertinoActionSheet]：
/// - 自动带上从底部滑入的动画、圆角与半透明遮罩；
/// - 每一项高度、分隔线、取消按钮与主操作区之间的间隙都由系统决定；
/// - 危险操作传 [PLActionSheetItem.isDestructive]，会渲染成红色并自动排到后面；
/// - 取消按钮单独成块并加粗，底部安全区（Home Indicator）由系统处理。
Future<void> showPLActionSheet({
  required BuildContext context,
  required List<PLActionSheetItem> items,
  String? title,
  String? message,
  String? cancelText = '取消',
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => CupertinoTheme(
      // 强调色跟随 App 的 iOS 风格品牌粉；危险操作由系统渲染为红色。
      data: CupertinoTheme.of(
        context,
      ).copyWith(primaryColor: IosColors.brandPink),
      child: CupertinoActionSheet(
        title: title == null ? null : Text(title),
        message: message == null ? null : Text(message),
        actions: [
          for (final item in items)
            CupertinoActionSheetAction(
              isDestructiveAction: item.isDestructive,
              onPressed: () {
                Navigator.of(context).pop();
                item.onTap();
              },
              child: Text(item.title),
            ),
        ],
        cancelButton: cancelText == null
            ? null
            : CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  cancelText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
      ),
    ),
  );
}

/// 操作表项。
class PLActionSheetItem {
  const PLActionSheetItem({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final VoidCallback onTap;

  /// 危险操作（删除、举报、屏蔽等），系统会渲染成红色。
  final bool isDestructive;
}
