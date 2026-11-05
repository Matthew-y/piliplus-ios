import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoButton, CupertinoColors;
import 'package:material_ui/material_ui.dart';

/// iOS 表单/内容卡片。
///
/// iOS 外观下是「白底 + 12pt 圆角 + 16pt 外边距」的卡片（对应
/// `CupertinoListSection.insetGrouped` 的视觉），Material 皮肤保持 [Card]。
class PLCard extends StatelessWidget {
  const PLCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isIOS(context)) {
      return Card(
        margin: margin,
        child: Padding(padding: padding, child: child),
      );
    }
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: IosColors.secondaryGroupedBackground(
          Theme.of(context).brightness,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: child,
    );
  }
}

/// iOS 表单输入框外观：灰底、无边框、10pt 圆角。
///
/// 只返回 [InputDecoration]，调用方继续使用 `TextField` / `TextFormField`，
/// 这样 `validator`、`inputFormatters` 等表单能力不会被削弱。
InputDecoration plInputDecoration(
  BuildContext context, {
  String? hintText,
  String? labelText,
  String? suffixText,
  bool isDense = true,
}) {
  if (!Adaptive.isIOS(context)) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      suffixText: suffixText,
      isDense: isDense,
    );
  }
  final fill = IosColors.gray5(Theme.of(context).brightness);
  final radius = BorderRadius.circular(10);
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    suffixText: suffixText,
    isDense: isDense,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
  );
}

/// iOS 主操作按钮：品牌粉填充、10pt 圆角、全宽。
class PLPrimaryButton extends StatelessWidget {
  const PLPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isIOS(context)) {
      return FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      );
    }
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: IosColors.brandPink.withValues(alpha: enabled ? 1 : 0.4),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
