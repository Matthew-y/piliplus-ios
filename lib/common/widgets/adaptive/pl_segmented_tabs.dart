import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:material_ui/material_ui.dart';

/// iOS 风格的等宽分段控件（投票页等静态选择场景）。
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

/// 首页 / 动态页顶部的 iOS 分段 Tab。
///
/// 官方源码（`Source Repo`）这两页用 `TabBar` + `TabBarView` 共用同一个
/// [TabController]，框架的 `_IndicatorPainter` 按 `controller.animation`
/// 连续重绘滑块，左右滑动内容区时天然跟手，不需要任何手写同步。
/// 这里沿用同一套机制，只把 `TabBar` 的 indicator 换成白色胶囊、外层补灰轨道，
/// 保留 iOS 分段控件观感。
///
/// 相对 [CupertinoSlidingSegmentedControl]：滑块由「滚动结算后 412ms 弹簧」
/// 变为随手指连续移动；代价是没有原生控件的拖拽滑块与按压动效。
class PLTabSegmentedTabs<T extends Object> extends StatelessWidget {
  const PLTabSegmentedTabs({
    super.key,
    required this.controller,
    required this.values,
    required this.labelOf,
    this.onTap,
    this.fontSize = 13,
  });

  final TabController controller;

  final List<T> values;

  final String Function(T value) labelOf;

  /// 与 `TabBar.onTap` 语义一致：`TabBar` 已自行 `animateTo`，这里只做副作用。
  final ValueChanged<int>? onTap;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    return Container(
      // Cupertino 分段控件的最小内容高度是 28，加上下各 2 的轨道内边距。
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: IosColors.gray5(brightness),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        tabAlignment: .fill,
        tabs: [
          for (final value in values)
            Tab(
              height: 28,
              child: Text(
                labelOf(value),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        dividerHeight: 0,
        dividerColor: Colors.transparent,
        indicatorWeight: 0,
        indicatorPadding: EdgeInsets.zero,
        indicatorSize: .tab,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF636366) : Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
        // iOS 分段控件没有 Material 水波纹。
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor: IosColors.secondaryLabel(brightness),
        labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        onTap: onTap,
      ),
    );
  }
}
