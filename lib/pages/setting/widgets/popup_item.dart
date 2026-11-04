import 'package:PiliPlus/common/widgets/adaptive/pl_list_tile.dart';
import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

typedef PopupMenuItemSelected<T> = void Function(
  T value,
  VoidCallback setState,
);

List<PopupMenuEntry<T>> enumItemBuilder<T extends EnumWithLabel>(
  Iterable<T> items,
) => items.map((e) => PopupMenuItem(value: e, child: Text(e.label))).toList();

enum DescPosType { subtitle, title, trailing }

class PopupListTile<T> extends StatefulWidget {
  const PopupListTile({
    super.key,
    this.dense,
    this.safeArea = true,
    this.enabled = true,
    this.leading,
    required this.title,
    this.subtitle,
    this.descPosType = .subtitle,
    required this.value,
    required this.itemBuilder,
    required this.onSelected,
    this.titleStyle,
    this.descStyle,
  });

  final bool? dense;
  final bool safeArea;
  final bool enabled;
  final Widget? leading;
  final Widget title;

  /// 标题下方的补充说明。
  final String? subtitle;

  final DescPosType descPosType;
  final ValueGetter<(T, String)> value;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final TextStyle? titleStyle;
  final TextStyle? descStyle;

  @override
  State<PopupListTile<T>> createState() => _PopupListTileState<T>();
}

class _PopupListTileState<T> extends State<PopupListTile<T>> {
  final _key = PlatformUtils.isDesktop ? null : GlobalKey();

  /// 用行自身的 RenderBox 定位菜单。
  ///
  /// 不能只依赖 `onTapUp`：iOS 分支的 `PLListTile` 使用 `CupertinoListTile`，
  /// 它只支持 `onTap`，传入 `onTapUp` 会被丢弃——设置里的下拉项会全部点不动。
  void _showButtonMenu(T value) {
    final thisBox = context.findRenderObject() as RenderBox;
    final thisOffset = thisBox.localToGlobal(.zero);
    final double dx;
    if (PlatformUtils.isDesktop) {
      dx = thisOffset.dx + 1;
    } else {
      final titleBox = _key!.currentContext!.findRenderObject() as RenderBox;
      final titleOffset = titleBox.localToGlobal(.zero, ancestor: thisBox);
      dx = thisOffset.dx + titleOffset.dx;
    }
    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(dx, thisOffset.dy + 5, dx, 0),
      items: widget.itemBuilder(context),
      initialValue: value,
      requestFocus: false,
    ).then<void>((newValue) {
      if (!mounted) return;
      if (newValue == null || newValue == value) return;
      widget.onSelected(newValue, _refresh);
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (value, descStr) = widget.value();
    Widget title = KeyedSubtree(key: _key, child: widget.title);
    Widget? subtitle;
    Widget? trailing;
    final desc = Text(
      descStr,
      style: (widget.descStyle ?? theme.textTheme.labelMedium!).copyWith(
        color: widget.enabled
            ? theme.colorScheme.secondary
            : theme.disabledColor,
      ),
    );
    // 设置项自带的补充说明。
    final extraSubtitle = widget.subtitle == null
        ? null
        : Text(
            widget.subtitle!,
            style: theme.textTheme.labelMedium!.copyWith(
              color: theme.colorScheme.outline,
            ),
          );
    switch (widget.descPosType) {
      case DescPosType.subtitle:
        subtitle = extraSubtitle == null ? desc : _stack(extraSubtitle, desc);
      case DescPosType.title:
        title = Row(
          spacing: 12,
          mainAxisSize: .min,
          children: [title, desc],
        );
      case DescPosType.trailing:
        trailing = desc;
    }
    return PLListTile(
      dense: widget.dense,
      safeArea: widget.safeArea,
      enabled: widget.enabled,
      onTap: () => _showButtonMenu(value),
      leading: widget.leading,
      title: title,
      titleTextStyle: widget.titleStyle ?? theme.textTheme.titleMedium,
      subtitle: subtitle,
      trailing: trailing,
    );
  }

  /// 副标题槽位里同时放两行文字（补充说明 + 右侧描述）。
  static Widget _stack(Widget first, Widget second) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [first, second],
  );
}
