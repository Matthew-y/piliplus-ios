import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:material_ui/material_ui.dart';

/// iOS 风格搜索框。
///
/// iOS 的搜索框（`UISearchBar`）是**灰底圆角矩形**（不是胶囊），
/// 高度 36pt，图标与文字垂直居中。
class PLSearchField extends StatelessWidget {
  const PLSearchField({
    super.key,
    required this.placeholder,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.bottomPadding = 16,
  }) : placeholderBuilder = null;

  /// 占位文字随外部状态变化时用这个构造（首页的搜索词是响应式的）。
  const PLSearchField.builder({
    super.key,
    required this.placeholderBuilder,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.bottomPadding = 16,
  }) : placeholder = '';

  /// 占位文字。
  final String placeholder;

  /// 占位文字的响应式版本，优先于 [placeholder]。
  final Widget Function(BuildContext context)? placeholderBuilder;

  final VoidCallback? onTap;

  /// 左右外边距。
  final EdgeInsets margin;

  /// 与下方内容的间距。
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: margin,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Material(
          // 搜索框用 systemGray5，与页面底色（systemGroupedBackground）
          // 只有极弱的区分度——这是 iOS 设置/App Store 的做法。
          color: IosColors.gray5(theme.brightness),
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  // 用 Material 的搜索图标：项目没有引入 Cupertino 图标字体，
                  // CupertinoIcons 会渲染成方块。
                  Icon(
                    Icons.search,
                    size: 17,
                    color: theme.colorScheme.outline,
                    semanticLabel: '搜索',
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child:
                        placeholderBuilder?.call(context) ??
                        Text(
                          placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
