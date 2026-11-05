import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:material_ui/material_ui.dart';

/// iOS 风格的列表页顶部分类条（可横向滚动）。
///
/// 与 [PLSegmentedTabs] 的分工：那个是等宽 `UISegmentedControl`，适合首页 /
/// 动态这类 2~3 个固定分类；这里是「可变数量的分类条」，每个标题按内容宽度
/// 排版，超出屏幕时整体横向滚动——`/fav` 的 7 个 tab 因此不会被等宽压到
/// 约 50pt、中文标题也不会被右缘硬切断。
///
/// 选中态沿用 iOS 语言：没有下划线，靠品牌粉 + 加粗 + 浅胶囊底区分。
/// 不持有 [TabController] 的生命周期（不 dispose），由页面管理。
class PLSegmentedTabBar extends StatefulWidget {
  const PLSegmentedTabBar({
    super.key,
    required this.controller,
    required this.labels,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.isScrollable = true,
  });

  final TabController controller;

  /// 已含计数后缀的标题，如 `全部(13)`。
  final List<String> labels;

  /// 语义与 `TabBar.onTap` 一致：先切页（`animateTo`）再回调。
  final ValueChanged<int>? onTap;

  /// 长按某一项（`/follow` 用它打开自定义标签排序）。
  final ValueChanged<int>? onLongPress;

  final EdgeInsetsGeometry padding;

  final bool isScrollable;

  @override
  State<PLSegmentedTabBar> createState() => _PLSegmentedTabBarState();
}

class _PLSegmentedTabBarState extends State<PLSegmentedTabBar> {
  static const double _height = 44;

  /// 品牌粉 #FB7299 在白底上只有 2.6:1，达不到「对比度 ≥ 3:1」的验收线；
  /// 浅色模式按同一色相压到 3.6:1，深色模式品牌粉本身有 6.4:1，直接用原色。
  static const Color _brandPinkOnLight = Color(0xFFE0557E);

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  Animation<double>? _animation;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.controller.index;
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(PLSegmentedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _index = widget.controller.index;
      _attach(widget.controller);
    }
  }

  @override
  void dispose() {
    _detach(widget.controller);
    _scrollController.dispose();
    super.dispose();
  }

  void _attach(TabController controller) {
    controller.addListener(_syncIndex);
    // 滑动手势改变的是 animation（offset），index 要等翻页结束才更新，
    // 两个都监听才能保证选中态与实际页面一致。
    _animation = controller.animation;
    _animation?.addListener(_syncIndex);
  }

  void _detach(TabController controller) {
    controller.removeListener(_syncIndex);
    _animation?.removeListener(_syncIndex);
    _animation = null;
  }

  void _syncIndex() {
    if (!mounted) return;
    final index = widget.controller.index;
    if (index == _index) return;
    setState(() => _index = index);
    _reveal(index);
  }

  /// 切到看不见的那一项时（如左滑到 `/fav` 的「课堂」）把它滚进视口。
  void _reveal(int index) {
    if (!widget.isScrollable || index >= _itemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = _itemKeys[index].currentContext;
      if (!mounted || itemContext == null) return;
      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  GlobalKey _keyFor(int index) {
    while (_itemKeys.length <= index) {
      _itemKeys.add(GlobalKey());
    }
    return _itemKeys[index];
  }

  void _handleTap(int index) {
    if (index != widget.controller.index) {
      widget.controller.animateTo(index);
    }
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final selectedColor = isDark ? IosColors.brandPink : _brandPinkOnLight;
    final unselectedColor = IosColors.secondaryLabel(brightness);
    final selectedBackground = IosColors.brandPink.withValues(
      alpha: isDark ? 0.22 : 0.14,
    );

    final items = <Widget>[
      for (var index = 0; index < widget.labels.length; index++)
        GestureDetector(
          key: _keyFor(index),
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleTap(index),
          onLongPress: widget.onLongPress == null
              ? null
              : () => widget.onLongPress!(index),
          child: SizedBox(
            height: _height,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: index == _index
                      ? selectedBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.labels[index],
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: index == _index
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: index == _index ? selectedColor : unselectedColor,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];

    if (!widget.isScrollable) {
      return Padding(
        padding: widget.padding,
        child: SizedBox(
          height: _height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items,
          ),
        ),
      );
    }

    return SizedBox(
      height: _height,
      // 撑满可用宽度：`SingleChildScrollView` 默认按内容收窄，父级 Column 一旦
      // `crossAxisAlignment.center`（/later）整排 tab 就会飘到中间。
      width: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: Row(spacing: 8, children: items),
      ),
    );
  }
}
