import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoTabBar, CupertinoTheme, CupertinoThemeData;
import 'package:flutter/cupertino.dart'
    show CupertinoColors, CupertinoDynamicColor;
import 'package:material_ui/material_ui.dart';

/// 底部标签栏适配组件。
///
/// iOS 外观下用 [CupertinoTabBar]，其余保持原实现。
///
/// 用法：把 `NavigationBar(...)` / `BottomNavigationBar(...)` 换成
/// `PLBottomNav(...)`，`destinations` 统一用 [PLNavDestination]。
class PLBottomNav extends StatelessWidget {
  const PLBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.maintainBottomViewPadding = false,
  });

  final List<PLNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Material `NavigationBar` 专用：键盘弹出时保留底部安全区。
  /// `CupertinoTabBar` 自己处理安全区，忽略此参数。
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOS(context)) {
      final theme = Theme.of(context);
      // 半透明 systemBackground 遮罩：在毛玻璃之上再压一层浅色/深色，
      // 避免底层鲜艳的内容卡片透出来糊住文字（需求二.2）。仍非不透明，
      // 故 CupertinoTabBar 的 BackdropFilter 模糊依旧生效。
      final barBg = CupertinoDynamicColor.resolve(
        CupertinoColors.systemBackground,
        context,
      ).withValues(alpha: 0.8);
      return CupertinoTheme(
        data: CupertinoThemeData(
          brightness: theme.brightness,
          // 选中态：固定 B 站品牌粉（M3 从主题色派生的 primary 偏紫）。
          primaryColor: IosColors.brandPink,
          scaffoldBackgroundColor: theme.colorScheme.surface,
          // 未选中态：系统次要色（inactiveGray，由 CupertinoTabBar 默认提供）。
          // 背景：半透明 systemBackground，既保留毛玻璃又提升文字对比度。
          barBackgroundColor: barBg,
        ),
        child: CupertinoTabBar(
          currentIndex: selectedIndex,
          onTap: onDestinationSelected,
          activeColor: IosColors.brandPink,
          inactiveColor: CupertinoColors.inactiveGray,
          // CupertinoTabBar 默认图标 30pt，比 iOS 原生（~25pt）大一号。
          iconSize: 24,
          items: destinations
              .map(
                (e) => BottomNavigationBarItem(
                  label: e.label,
                  icon: e.icon,
                  activeIcon: e.selectedIcon,
                ),
              )
              .toList(),
        ),
      );
    }
    return NavigationBar(
      maintainBottomViewPadding: maintainBottomViewPadding,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations
          .map(
            (e) => NavigationDestination(
              label: e.label,
              icon: e.icon,
              selectedIcon: e.selectedIcon,
            ),
          )
          .toList(),
    );
  }
}

/// 标签项。
class PLNavDestination {
  const PLNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final Widget icon;
  final Widget? selectedIcon;
}
