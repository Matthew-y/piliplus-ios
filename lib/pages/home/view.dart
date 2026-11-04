import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_search_field.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_segmented_tabs.dart';
import 'package:PiliPlus/common/widgets/custom_height_widget.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends CommonPageState<HomePage>
    with AutomaticKeepAliveClientMixin {
  late ColorScheme _colorScheme;
  final _homeController = Get.putOrFind(HomeController.new);
  final _mainController = Get.find<MainController>();

  @override
  bool get needsCorrection => _homeController.hideTopBar;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isIOS = Adaptive.isIOS(context);
    final body = Expanded(
      child: onBuild(
        tabBarView(
          controller: _homeController.tabController,
          children: _homeController.tabs.map((e) => e.page).toList(),
        ),
      ),
    );

    // iOS 风格：搜索栏 + Tab 栏包进同一个纯白顶栏（见需求二.4）。
    if (isIOS) {
      return Column(
        children: [
          if (!_mainController.useSideBar &&
              MediaQuery.sizeOf(context).isPortrait)
            _iosHeader(),
          body,
        ],
      );
    }

    Widget tabBar;
    if (_homeController.tabs.length > 1) {
      tabBar = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: 42,
          width: double.infinity,
          child: TabBar(
            controller: _homeController.tabController,
            tabs: _homeController.tabs.map((e) => Tab(text: e.label)).toList(),
            isScrollable: true,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            splashBorderRadius: Style.mdRadius,
            tabAlignment: TabAlignment.center,
            onTap: (_) {
              feedBack();
              if (!_homeController.tabController.indexIsChanging) {
                _homeController.animateToTop();
              }
            },
          ),
        ),
      );
      if (_homeController.hideTopBar &&
          _mainController.barHideType == .instant) {
        tabBar = Material(
          color: _colorScheme.surface,
          child: tabBar,
        );
      }
    } else {
      tabBar = const SizedBox(height: 6);
    }
    return Column(
      children: [
        if (!_mainController.useSideBar &&
            MediaQuery.sizeOf(context).isPortrait)
          customAppBar(),
        tabBar,
        body,
      ],
    );
  }

  /// iOS 风格的顶栏：搜索栏 + Tab 栏整体作为一个单元。
  ///
  /// 用户要求：首页搜索区与分段控件区背景改为**纯白**。
  /// - 浅色模式：纯白底（`Colors.white`），与灰底搜索框 / 分段轨道形成层次。
  /// - 深色模式：取 [ThemeData.canvasColor]，避免白底导致文字/滑块不可读，
  ///   同时与状态栏那条留白的底色一致（不能硬用纯黑，否则出现色带）。
  /// - 向上滑动时搜索栏收起、Tab 栏随之上移（两者一起「收起」），
  ///   顶栏高度自然变小，露出下方内容。
  Widget _iosHeader() {
    return ColoredBox(
      color: _headerBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _iosTopBar(),
          if (_homeController.tabs.length > 1)
            Padding(
              // 与上方搜索栏留出间距：搜索栏自身有 8 的底边距，这里再加 8。
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _iosSegmentedTabs(),
            ),
        ],
      ),
    );
  }

  /// 顶栏底色：浅色纯白，深色跟随 canvas。
  Color get _headerBackground => IosColors.headerBackground(context);

  /// iOS 风格顶部 Tab：原生分段控件（浅灰轨道 + 白色滑块，无下划线）。
  ///
  /// 用 [AnimatedBuilder] 跟随 [TabController]，index 变化时重建并让滑块
  /// 平滑过渡。
  Widget _iosSegmentedTabs() {
    final tabs = _homeController.tabs;
    return AnimatedBuilder(
      animation: _homeController.tabController,
      builder: (context, _) {
        return PLSegmentedTabs<HomeTabType>(
          values: tabs,
          labelOf: (e) => e.label,
          groupValue: tabs[_homeController.tabController.index],
          onValueChanged: (value) {
            final index = tabs.indexOf(value);
            if (index < 0) return;
            feedBack();
            // CupertinoSlidingSegmentedControl 不会自动驱动 TabController，
            // 需手动 animateTo；index 同步更新后 AnimatedBuilder 触发滑块动画。
            _homeController.tabController.animateTo(index);
            // animateTo 已同步把 index 切到新页，这里滚到顶部。
            _homeController.animateToTop();
          },
        );
      },
    );
  }

  Widget customAppBar() {
    if (Adaptive.isIOS(context)) {
      return _iosTopBar();
    }
    const padding = EdgeInsets.fromLTRB(14, 6, 14, 0);
    final child = Row(
      children: [
        searchBar(),
        const SizedBox(width: 4),
        msgBadge(_mainController),
        const SizedBox(width: 8),
        userAvatar(colorScheme: _colorScheme, mainController: _mainController),
      ],
    );
    if (_homeController.hideTopBar) {
      if (_mainController.barOffset case final barOffset?) {
        return Obx(
          () {
            final offset = barOffset.value;
            return CustomHeightWidget(
              offset: Offset(0, -offset),
              height: Style.topBarHeight - offset,
              child: Padding(
                padding: padding,
                child: child,
              ),
            );
          },
        );
      }
      if (_homeController.showTopBar case final showTopBar?) {
        return Obx(() {
          final showSearchBar = showTopBar.value;
          return AnimatedOpacity(
            opacity: showSearchBar ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              height: showSearchBar ? Style.topBarHeight : 0,
              padding: padding,
              child: child,
            ),
          );
        });
      }
    }
    return Container(
      height: Style.topBarHeight,
      padding: padding,
      child: child,
    );
  }

  /// iOS 风格顶栏：搜索框一行，右侧紧跟消息与头像。
  ///
  /// 背景与顶栏一致（浅色纯白）；搜索框本身用 systemGray5，在白底上自然区分。
  ///
  /// 滚动收起时整体上移，露出内容——与 iOS 的行为一致。
  Widget _iosTopBar() {
    final child = ColoredBox(
      // 与顶栏整体同色（浅色纯白；深色 canvas）。
      color: _headerBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
        child: Row(
          children: [
            Expanded(child: _iosSearchBar()),
            const SizedBox(width: 8),
            msgBadge(_mainController, size: 28),
          ],
        ),
      ),
    );

    if (_homeController.hideTopBar) {
      if (_mainController.barOffset case final barOffset?) {
        return Obx(
          () {
            final offset = barOffset.value;
            return CustomHeightWidget(
              offset: Offset(0, -offset),
              height: Style.topBarHeight - offset,
              child: child,
            );
          },
        );
      }
      if (_homeController.showTopBar case final showTopBar?) {
        return Obx(() {
          final show = showTopBar.value;
          return AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              height: show ? Style.topBarHeight : 0,
              child: child,
            ),
          );
        });
      }
    }
    // 整行已经是纯白（ColoredBox），外面不能再套 Material(surface)。
    return SizedBox(height: Style.topBarHeight, child: child);
  }

  /// iOS 搜索框：灰底圆角矩形 + 放大镜图标，无水波纹。
  ///
  /// 宽度由外层的 [Expanded] 控制，这里不能用 [Expanded]（会嵌套），
  /// 所以用 [PLSearchField] 的紧凑形态（margin 传零边距）。
  Widget _iosSearchBar() {
    return PLSearchField.builder(
      placeholderBuilder: (context) => Obx(
        () => Text(
          _homeController.searchHint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            height: 1,
            color: _colorScheme.outline,
          ),
        ),
      ),
      onTap: () => Get.toNamed(
        '/search',
        parameters: _homeController.enableSearchWord
            ? {'hintText': _homeController.defaultSearch.value}
            : null,
      ),
      margin: EdgeInsets.zero,
      bottomPadding: 0,
    );
  }

  Widget searchBar() {
    const borderRadius = BorderRadius.all(Radius.circular(25));
    return Expanded(
      child: SizedBox(
        height: 44,
        child: Material(
          borderRadius: borderRadius,
          color: _colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: _colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            onTap: () => Get.toNamed(
              '/search',
              parameters: _homeController.enableSearchWord
                  ? {'hintText': _homeController.defaultSearch.value}
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_outlined,
                  color: _colorScheme.onSecondaryContainer,
                  semanticLabel: '搜索',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => Text(
                      _homeController.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget userAvatar({
  required ColorScheme colorScheme,
  required MainController mainController,
  double size = 34,
}) {
  return Semantics(
    label: "我的",
    child: Obx(
      () {
        if (mainController.accountService.isLogin.value) {
          return Stack(
            clipBehavior: .none,
            children: [
              NetworkImgLayer(
                type: .avatar,
                width: size,
                height: size,
                src: mainController.accountService.face.value,
              ),
              Positioned.fill(
                child: Material(
                  type: .transparency,
                  child: InkWell(
                    onTap: mainController.toMinePage,
                    splashColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    customBorder: const CircleBorder(),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Obx(
                  () => MineController.anonymity.value
                      ? IgnorePointer(
                          child: Container(
                            padding: const .all(2),
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              size: 14,
                              MdiIcons.incognito,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        }
        return SizedBox(
          width: size + 4,
          height: size + 4,
          child: IconButton(
            tooltip: '点击登录',
            style: IconButton.styleFrom(
              padding: .zero,
              backgroundColor: colorScheme.onInverseSurface,
            ),
            onPressed: mainController.toMinePage,
            icon: Icon(
              Icons.person_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    ),
  );
}

Widget msgBadge(MainController mainController, {double? size}) {
  return Obx(
    () {
      if (mainController.accountService.isLogin.value) {
        final count = mainController.msgUnReadCount.value;
        final isNumBadge = mainController.msgBadgeMode == .number;
        return IconButton(
          tooltip: '消息',
          onPressed: () async {
            // 不在点击瞬间清角标：未读只由服务端接口决定。
            // 进入消息页后返回时重新拉取，避免「点开即已读」的假象；
            // 同时不再顺延 lastCheckUnreadAt，让轮询仍按原周期检查新消息。
            await Get.toNamed('/whisper');
            mainController.queryUnreadMsg();
          },
          icon: Badge(
            isLabelVisible:
                mainController.msgBadgeMode != .hidden && count != null,
            alignment: isNumBadge
                ? const Alignment(0.0, -0.85)
                : const Alignment(1.0, -0.85),
            label: isNumBadge && count != null ? Text(count) : null,
            child: const Icon(Icons.notifications_none),
          ),
          // IconButton 默认 48x48 约束，iOS 顶栏里要跟搜索框等高。
          constraints: size == null
              ? null
              : BoxConstraints.tightFor(width: size, height: size),
          padding: size == null ? null : EdgeInsets.zero,
          iconSize: size == null ? null : size * 0.7,
        );
      }
      return const SizedBox.shrink();
    },
  );
}
