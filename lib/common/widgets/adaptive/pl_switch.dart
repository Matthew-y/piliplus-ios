import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoCheckbox, CupertinoSwitch;
import 'package:material_ui/material_ui.dart';

/// 开关适配组件。
///
/// iOS 外观下用 [CupertinoSwitch]，其余保持 [Switch]。
class PLSwitch extends StatelessWidget {
  const PLSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.materialScale = 1.0,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Material 皮肤下的缩放比例，用于还原各页面原本的
  /// `Transform.scale(scale: 0.8, child: Switch(...))`。
  /// iOS 的 [CupertinoSwitch] 是系统尺寸，不参与缩放。
  final double materialScale;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOS(context)) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        // 固定品牌粉，而不是 Cupertino 默认的绿色 / M3 派生出的偏紫色。
        activeTrackColor: IosColors.brandPink,
      );
    }
    final switchWidget = Switch(value: value, onChanged: onChanged);
    if (materialScale == 1.0) {
      return switchWidget;
    }
    return Transform.scale(
      alignment: Alignment.centerRight,
      scale: materialScale,
      child: switchWidget,
    );
  }
}

/// 复选框适配组件。
class PLCheckbox extends StatelessWidget {
  const PLCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOS(context)) {
      return CupertinoCheckbox(value: value ?? false, onChanged: onChanged);
    }
    return Checkbox(value: value, onChanged: onChanged);
  }
}
