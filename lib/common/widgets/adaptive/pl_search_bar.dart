import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:material_ui/material_ui.dart';

/// iOS 风格搜索栏顶栏（对齐 App Store 搜索页）。
///
/// 结构：`[灰色圆角搜索框] [取消]`，没有返回箭头。
/// - 搜索框：systemGrey5 底、圆角 10、内嵌放大镜图标、输入时右侧出现清除按钮；
/// - 取消：品牌色文字按钮，点击收起键盘并返回上一页。
///
/// 只在 iOS 外观下使用；Material 风格的分页仍然用 [AppBar]。
class PLSearchBar extends StatefulWidget {
  const PLSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = true,
    this.hintText = '搜索',
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.trailing,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;

  /// 搜索框与「取消」之间的可选按钮（如首页的 UID 搜索入口）。
  final Widget? trailing;

  @override
  State<PLSearchBar> createState() => _PLSearchBarState();
}

class _PLSearchBarState extends State<PLSearchBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = IosColors.secondaryLabel(theme.brightness);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
        child: Row(
          children: [
            Expanded(child: _field(context, secondary)),
            if (widget.trailing != null) widget.trailing!,
            TextButton(
              onPressed:
                  widget.onCancel ??
                  () {
                    FocusScope.of(context).unfocus();
                    final navigator = Navigator.maybeOf(context);
                    if (navigator != null && navigator.canPop()) {
                      navigator.pop();
                    }
                  },
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                minimumSize: WidgetStatePropertyAll(Size.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: IosColors.brandPink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, Color secondary) {
    final theme = Theme.of(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: IosColors.gray5(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search, size: 17, color: secondary),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: IosColors.brandPink,
              style: TextStyle(
                fontSize: 17,
                height: 1,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 17,
                  height: 1,
                  color: secondary,
                ),
              ),
            ),
          ),
          // 仅在输入时显示清除按钮（App Store 行为）。
          ValueListenableBuilder(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 8);
              return IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged?.call('');
                },
                padding: const EdgeInsets.only(right: 8, left: 4),
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
                iconSize: 16,
                color: secondary,
                icon: const Icon(Icons.cancel),
              );
            },
          ),
        ],
      ),
    );
  }
}
