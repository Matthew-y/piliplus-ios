import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:material_ui/material_ui.dart';

/// iOS 风格的等宽分段控件（首页 / 动态页顶部的 Tab）。
///
/// iOS 规范里顶部分类用 `UISegmentedControl`：浅灰轨道 + 白色滑块，
/// 选中项靠滑块和字重区分，**没有下划线**（下划线是 Material 的 Tab 语言）。
///
/// 颜色全部按 `Theme.brightness` 取固定值，不走 `CupertinoDynamicColor`
/// 的动态解析——后者认的是系统亮度，App 内主题与系统不一致时会串色。
class PLSegmentedTabs<T extends Object> extends StatelessWidget {
  const PLSegmentedTabs({
    super.key,
    required this.values,
    required this.labelOf,
    required this.groupValue,
    required this.onValueChanged,
    this.fontSize = 13,
  });

  /// 可选的 Tab 值（按显示顺序）。
  final List<T> values;

  final String Function(T value) labelOf;

  final T groupValue;

  final ValueChanged<T> onValueChanged;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = theme.colorScheme.onSurface;
    final unselectedColor = IosColors.secondaryLabel(theme.brightness);
    return CupertinoSlidingSegmentedControl<T>(
      groupValue: groupValue,
      children: <T, Widget>{
        for (final value in values)
          value: Text(
            labelOf(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: value == groupValue
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: value == groupValue ? selectedColor : unselectedColor,
            ),
          ),
      },
      // 浅灰轨道（systemGrey5）+ 滑块（浅色白 / 深色 #636366，原生取值）。
      backgroundColor: IosColors.gray5(theme.brightness),
      thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
      padding: const EdgeInsets.all(2),
      onValueChanged: (value) {
        if (value == null || value == groupValue) return;
        onValueChanged(value);
      },
    );
  }
}
