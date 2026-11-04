import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoColors;
import 'package:material_ui/material_ui.dart';

/// iOS 18 风格的锚定 Popover。
///
/// 与 [PopupMenuButton] 的区别：
/// - 菜单紧贴触发按钮下方/上方，并按按钮右边缘对齐；
/// - 使用 `BackdropFilter` 做磨砂玻璃，13pt 圆角与极轻阴影；
/// - 从触发按钮方向缩放展开，点击遮罩淡出关闭；
/// - 行高 44、图标 20、文字 16、图标与文字间距 12。
///
/// Material 皮肤下仍返回原生 [PopupMenuButton]，外观与行为完全不变。
///
/// 行为约定：
/// - 与原生一致，`onTap` 在菜单关闭后执行，`onSelected` 在 `value != null` 时执行；
/// - 只把 [PopupMenuItem] / [CheckedPopupMenuItem] / [CustomPopupMenuItem] /
///   [PopupMenuDivider] / [CustomPopupMenuDivider] 转成自绘行；遇到其它自定义
///   [PopupMenuEntry] 时**回退到原生菜单**，避免条目被静默丢弃。
class PLPopupMenuButton<T> extends StatelessWidget {
  const PLPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onOpened,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.padding = const EdgeInsets.all(8.0),
    this.menuPadding,
    this.child,
    this.borderRadius,
    this.splashRadius,
    this.icon,
    this.iconSize,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    this.iconColor,
    this.enableFeedback,
    this.constraints,
    this.position,
    this.clipBehavior = Clip.none,
    this.useRootNavigator = false,
    this.popUpAnimationStyle,
    this.routeSettings,
    this.style,
    this.requestFocus,
  }) : assert(
         !(child != null && icon != null),
         'You can only pass [child] or [icon], not both.',
       );

  final PopupMenuItemBuilder<T> itemBuilder;
  final T? initialValue;
  final VoidCallback? onOpened;
  final PopupMenuItemSelected<T>? onSelected;
  final PopupMenuCanceled? onCanceled;
  final String? tooltip;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? menuPadding;
  final Widget? child;
  final BorderRadius? borderRadius;
  final double? splashRadius;
  final Widget? icon;
  final double? iconSize;
  final Offset offset;
  final bool enabled;
  final ShapeBorder? shape;
  final Color? color;
  final Color? iconColor;
  final bool? enableFeedback;
  final BoxConstraints? constraints;
  final PopupMenuPosition? position;
  final Clip clipBehavior;
  final bool useRootNavigator;
  final AnimationStyle? popUpAnimationStyle;
  final RouteSettings? routeSettings;
  final ButtonStyle? style;
  final bool? requestFocus;

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isIOS(context)) {
      return PopupMenuButton<T>(
        itemBuilder: itemBuilder,
        initialValue: initialValue,
        onOpened: onOpened,
        onSelected: onSelected,
        onCanceled: onCanceled,
        tooltip: tooltip,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        padding: padding,
        menuPadding: menuPadding,
        borderRadius: borderRadius,
        splashRadius: splashRadius,
        icon: icon,
        iconSize: iconSize,
        offset: offset,
        enabled: enabled,
        shape: shape,
        color: color,
        iconColor: iconColor,
        enableFeedback: enableFeedback,
        constraints: constraints,
        position: position,
        clipBehavior: clipBehavior,
        useRootNavigator: useRootNavigator,
        popUpAnimationStyle: popUpAnimationStyle,
        routeSettings: routeSettings,
        style: style,
        requestFocus: requestFocus,
        child: child,
      );
    }

    return Builder(
      builder: (buttonContext) {
        void open() {
          final renderBox = buttonContext.findRenderObject() as RenderBox?;
          if (renderBox == null || !renderBox.hasSize) return;
          final anchor = renderBox.localToGlobal(Offset.zero) & renderBox.size;
          final entries = itemBuilder(buttonContext);
          onOpened?.call();
          if (!entries.every(_isSupportedEntry)) {
            // 有自绘层不认识的自定义 entry 时回退到原生菜单，
            // 保证调用方传进来的条目不会被静默丢掉。
            _showNativeMenu(
              context: buttonContext,
              anchor: anchor,
              entries: entries,
              onSelected: onSelected,
              onCanceled: onCanceled,
              useRootNavigator: useRootNavigator,
            );
            return;
          }
          _showEntries(
            context: buttonContext,
            anchor: anchor,
            entries: entries,
            initialValue: initialValue,
            onSelected: onSelected,
            onCanceled: onCanceled,
            useRootNavigator: useRootNavigator,
          );
        }

        if (child != null) {
          Widget trigger = InkWell(
            onTap: enabled ? open : null,
            borderRadius: borderRadius,
            child: child,
          );
          if (tooltip != null) {
            trigger = Tooltip(message: tooltip!, child: trigger);
          }
          return Semantics(button: true, label: tooltip, child: trigger);
        }

        return IconButton(
          tooltip: tooltip,
          icon: icon ?? Icon(Icons.adaptive.more),
          iconSize: iconSize,
          padding: padding,
          splashRadius: splashRadius,
          color: iconColor ?? color,
          onPressed: enabled ? open : null,
          enableFeedback: enableFeedback,
          // iOS 顶栏按钮统一保证 44pt 的最小点击区。
          constraints:
              constraints ?? const BoxConstraints(minWidth: 44, minHeight: 44),
          style: style,
        );
      },
    );
  }

  bool _isSupportedEntry(PopupMenuEntry<T> entry) =>
      entry is PopupMenuDivider ||
      entry is CustomPopupMenuDivider ||
      entry is CheckedPopupMenuItem<T> ||
      entry is PopupMenuItem<T> ||
      entry is CustomPopupMenuItem<T>;

  Future<void> _showNativeMenu({
    required BuildContext context,
    required Rect anchor,
    required List<PopupMenuEntry<T>> entries,
    required PopupMenuItemSelected<T>? onSelected,
    required PopupMenuCanceled? onCanceled,
    required bool useRootNavigator,
  }) async {
    final size = MediaQuery.sizeOf(context);
    final value = await showMenu<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      position: RelativeRect.fromLTRB(
        anchor.left,
        anchor.bottom,
        size.width - anchor.right,
        size.height - anchor.bottom,
      ),
      items: entries,
    );
    if (value != null) {
      onSelected?.call(value);
    } else {
      onCanceled?.call();
    }
  }

  Future<void> _showEntries({
    required BuildContext context,
    required Rect anchor,
    required List<PopupMenuEntry<T>> entries,
    required T? initialValue,
    required PopupMenuItemSelected<T>? onSelected,
    required PopupMenuCanceled? onCanceled,
    required bool useRootNavigator,
  }) async {
    final items = <PLPopoverItem>[];
    for (final entry in entries) {
      if (entry is PopupMenuDivider || entry is CustomPopupMenuDivider) {
        items.add(const PLPopoverItem.separator());
        continue;
      }
      if (entry is CheckedPopupMenuItem<T>) {
        final value = entry.value;
        items.add(
          _entryToItem(
            context,
            child: entry.child,
            enabled: entry.enabled,
            selected: entry.checked,
            onTap: () {
              entry.onTap?.call();
              if (value != null) onSelected?.call(value);
            },
          ),
        );
        continue;
      }
      if (entry is PopupMenuItem<T>) {
        final value = entry.value;
        items.add(
          _entryToItem(
            context,
            child: entry.child,
            enabled: entry.enabled,
            selected: value != null && value == initialValue,
            onTap: () {
              entry.onTap?.call();
              if (value != null) onSelected?.call(value);
            },
          ),
        );
        continue;
      }
      if (entry is CustomPopupMenuItem<T>) {
        final value = entry.value;
        items.add(
          _entryToItem(
            context,
            child: entry.child,
            selected: value != null && value == initialValue,
            onTap: () {
              if (value != null) onSelected?.call(value);
            },
          ),
        );
      }
    }

    if (items.isEmpty) return;
    final selected = await showPLPopover(
      context: context,
      anchor: anchor,
      items: items,
      useRootNavigator: useRootNavigator,
    );
    if (!selected) onCanceled?.call();
  }
}

/// Popover 中的一项。用 [PLPopoverItem.separator] 插入分组分割线。
class PLPopoverItem {
  const PLPopoverItem({
    this.icon,
    this.title,
    this.child,
    this.onTap,
    this.isDestructive = false,
    this.enabled = true,
    this.selected = false,
    this.trailing,
  }) : isSeparator = false;

  const PLPopoverItem.separator()
    : icon = null,
      title = null,
      child = null,
      onTap = null,
      isDestructive = false,
      enabled = false,
      selected = false,
      trailing = null,
      isSeparator = true;

  final IconData? icon;
  final String? title;
  final Widget? child;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool enabled;
  final bool selected;
  final Widget? trailing;
  final bool isSeparator;
}

/// 取 [context] 对应渲染对象在全局坐标中的位置，作为 Popover 锚点。
///
/// 适合给自定义触发控件（非 [PLPopupMenuButton]）使用；拿不到布局时返回
/// `null`，调用方可退化为屏幕右上角。
Rect? plPopoverAnchorOf(BuildContext context) {
  final renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.hasSize) return null;
  return renderBox.localToGlobal(Offset.zero) & renderBox.size;
}

/// 在 [anchor] 附近显示 iOS 18 风格 Popover。
///
/// 返回 `true` 表示点击了某一项，`false` 表示点击遮罩或返回键关闭。
Future<bool> showPLPopover({
  required BuildContext context,
  required Rect anchor,
  required List<PLPopoverItem> items,
  bool useRootNavigator = false,
}) async {
  if (items.isEmpty) return false;

  final screenSize = MediaQuery.sizeOf(context);
  final viewPadding = MediaQuery.viewPaddingOf(context);
  const margin = 12.0;
  const gap = 6.0;
  final width = math.min(250.0, screenSize.width - margin * 2);

  final actionCount = items.where((item) => !item.isSeparator).length;
  final separatorCount = items.length - actionCount;
  final estimatedHeight = 12 + actionCount * 44.0 + separatorCount * 9.0;

  var left = anchor.right - width;
  left = left.clamp(margin, screenSize.width - width - margin).toDouble();

  final bottomLimit = screenSize.height - viewPadding.bottom - margin;
  final topLimit = viewPadding.top + margin;
  final belowTop = anchor.bottom + gap;
  final belowAvailable = bottomLimit - belowTop;
  final aboveTop = anchor.top - gap;
  final aboveAvailable = aboveTop - topLimit;

  final double top;
  final double availableHeight;
  final Alignment alignment;
  if (estimatedHeight <= belowAvailable || belowAvailable >= aboveAvailable) {
    top = belowTop;
    availableHeight = belowAvailable;
    alignment = Alignment.topRight;
  } else {
    availableHeight = aboveAvailable;
    top = aboveTop - math.min(estimatedHeight, aboveAvailable);
    alignment = Alignment.bottomRight;
  }
  // 不把高度硬抬到 96：锚点贴近屏幕边缘时，硬抬会直接压到状态栏 / 安全区外。
  final maxHeight = math.max(44.0, math.min(estimatedHeight, availableHeight));
  // 再对最终位置做一次 clamp：极端情况下 belowAvailable / aboveAvailable 可能
  // 是负数，仅靠上面的分支会把菜单放到安全区以外。
  final clampedTop = top
      .clamp(topLimit, math.max(topLimit, bottomLimit - maxHeight))
      .toDouble();

  final result = await showGeneralDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.08),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      );
      return Stack(
        children: [
          Positioned(
            left: left,
            top: clampedTop,
            width: width,
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                alignment: alignment,
                child: _PLPopoverCard(items: items, maxHeight: maxHeight),
              ),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _PLPopoverCard extends StatelessWidget {
  const _PLPopoverCard({required this.items, required this.maxHeight});

  final List<PLPopoverItem> items;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final systemBackground = CupertinoColors.systemBackground.resolveFrom(
      context,
    );
    final separator = CupertinoColors.separator.resolveFrom(context);
    final background = systemBackground.withValues(
      alpha: brightness == Brightness.dark ? 0.72 : 0.75,
    );
    final shadow = Colors.black.withValues(
      alpha: brightness == Brightness.dark ? 0.45 : 0.14,
    );
    // 有图标或勾选状态时统一预留左侧 20 + 12 的位置，保证文字对齐。
    final reserveLeading = items.any(
      (item) => !item.isSeparator && (item.icon != null || item.selected),
    );
    final dividerIndent = reserveLeading ? 44.0 : 12.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: separator.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items)
                        if (item.isSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Divider(
                              height: 0.5,
                              thickness: 0.5,
                              indent: dividerIndent,
                              color: separator,
                            ),
                          )
                        else
                          _PLPopoverRow(
                            item: item,
                            reserveLeading: reserveLeading,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PLPopoverRow extends StatelessWidget {
  const _PLPopoverRow({required this.item, required this.reserveLeading});

  final PLPopoverItem item;
  final bool reserveLeading;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final red = CupertinoColors.systemRed.resolveFrom(context);
    final activeBlue = CupertinoColors.activeBlue.resolveFrom(context);
    final color = item.isDestructive ? red : label;

    final Widget content =
        item.child ??
        Row(
          children: [
            if (reserveLeading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: item.selected
                    ? Icon(Icons.check, size: 18, color: activeBlue)
                    : item.icon != null
                    ? Icon(item.icon, size: 20, color: color)
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                item.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: color),
              ),
            ),
            if (item.trailing != null) ...[
              const SizedBox(width: 8),
              item.trailing!,
            ],
          ],
        );

    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: item.enabled
            ? () {
                Navigator.of(context).pop(true);
                item.onTap?.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Opacity(
            opacity: item.enabled ? 1 : 0.4,
            child: Align(
              alignment: Alignment.centerLeft,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

PLPopoverItem _entryToItem(
  BuildContext context, {
  required Widget? child,
  required VoidCallback onTap,
  bool enabled = true,
  bool selected = false,
}) {
  final theme = Theme.of(context);
  final errorColor = theme.colorScheme.error;

  if (child is Text) {
    final destructive =
        child.style?.color != null && child.style!.color == errorColor;
    final data = child.data;
    if (data != null) {
      return PLPopoverItem(
        title: data,
        isDestructive: destructive,
        enabled: enabled,
        selected: selected,
        onTap: onTap,
      );
    }
  }

  if (child is Row) {
    final extracted = _extractIconText(child, errorColor);
    if (extracted != null) {
      return PLPopoverItem(
        icon: extracted.icon,
        title: extracted.title,
        isDestructive: extracted.destructive,
        enabled: enabled,
        selected: selected,
        onTap: onTap,
      );
    }
  }

  final destructive = _containsErrorColor(child, errorColor);
  final label = destructive
      ? CupertinoColors.systemRed.resolveFrom(context)
      : CupertinoColors.label.resolveFrom(context);
  return PLPopoverItem(
    child: DefaultTextStyle.merge(
      style: TextStyle(fontSize: 16, color: label),
      child: IconTheme.merge(
        data: IconThemeData(size: 20, color: label),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
    enabled: enabled,
    selected: selected,
    onTap: onTap,
  );
}

({IconData icon, String title, bool destructive})? _extractIconText(
  Row row,
  Color errorColor,
) {
  final children = row.children;
  if (children.isEmpty || children.first is! Icon) return null;
  final icon = children.first as Icon;
  if (icon.icon == null) return null;

  Text? text;
  for (final widget in children.skip(1)) {
    if (widget is Text) {
      text = widget;
      break;
    }
    if (widget is Expanded && widget.child is Text) {
      text = widget.child as Text;
      break;
    }
    if (widget is Flexible && widget.child is Text) {
      text = widget.child as Text;
      break;
    }
  }
  final data = text?.data?.trim();
  if (data == null || data.isEmpty) return null;

  final destructive =
      text!.style?.color != null && text.style!.color == errorColor;
  return (icon: icon.icon!, title: data, destructive: destructive);
}

bool _containsErrorColor(Widget? child, Color errorColor) {
  if (child == null) return false;
  if (child is Text) return child.style?.color == errorColor;
  if (child is Row) {
    return child.children.any((w) => _containsErrorColor(w, errorColor));
  }
  if (child is Expanded) return _containsErrorColor(child.child, errorColor);
  if (child is Flexible) return _containsErrorColor(child.child, errorColor);
  if (child is Padding) return _containsErrorColor(child.child, errorColor);
  return false;
}
