import 'package:material_ui/material_ui.dart';

/// 列表为空时的占位。
///
/// 与 [HttpError] 区分开：
/// - [HttpError] 表示请求失败，带错误插画与「点击重试」；
/// - [EmptyState] 表示请求成功但确实没有数据，只给一句说明，不诱导用户重试。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.isSliver = true,
    this.message = '暂无消息',
    this.icon = Icons.inbox_outlined,
    this.safeArea = true,
  });

  final bool isSliver;
  final String message;
  final IconData icon;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Padding(
      padding: EdgeInsets.only(
        top: 72,
        bottom: safeArea ? 40 + MediaQuery.viewPaddingOf(context).bottom : 40,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 44,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );

    return isSliver ? SliverToBoxAdapter(child: child) : child;
  }
}
