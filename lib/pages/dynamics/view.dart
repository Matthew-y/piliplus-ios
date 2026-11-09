import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_segmented_tabs.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/common/dynamic/up_panel_position.dart';
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/up_panel.dart';
import 'package:PiliPlus/pages/dynamics_create/view.dart';
import 'package:PiliPlus/pages/dynamics_tab/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide DraggableScrollableSheet;

class DynamicsPage extends StatefulWidget {
  const DynamicsPage({super.key});

  @override
  State<DynamicsPage> createState() => _DynamicsPageState();
}

class _DynamicsPageState extends CommonPageState<DynamicsPage>
    with AutomaticKeepAliveClientMixin {
  final _dynamicsController = Get.putOrFind(DynamicsController.new);
  UpPanelPosition get upPanelPosition => _dynamicsController.upPanelPosition;
  late final MainController _mainController = Get.find<MainController>();

  @override
  bool get wantKeepAlive => true;

  Widget _createDynamicBtn(ColorScheme colorScheme, {bool isRight = true}) {
    // iOS：顶栏不再放「+」发布按钮（与 iOS 原生的导航栏层级不符），
    // 发布入口保留在其他地方；这里直接不占位。
    if (Adaptive.isIOS(context)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 34,
      height: 34,
      margin: isRight ? const .only(right: 16) : const .only(left: 16),
      child: IconButton(
        tooltip: '发布动态',
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.secondaryContainer,
          ),
        ),
        onPressed: () => CreateDynPanel.onCreateDyn(context),
        icon: Icon(
          Icons.add,
          size: 18,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  /// iOS 顶栏：分段控件（全部 / 投稿 / 番剧 / 专栏 / UP）。
  ///
  /// 去掉了 Material 的底部下划线；底色与首页顶栏一致（浅色纯白 / 深色 canvas）。
  /// 没有「+」后，分段控件占满整行，左右各留 16。
  Widget _iosTopBar({Widget? leading, required Widget actions}) {
    return ColoredBox(
      color: IosColors.headerBackground(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            ?leading,
            Expanded(child: _iosSegmentedTabs()),
            actions,
          ],
        ),
      ),
    );
  }

  /// `TabBar` 与 `TabBarView` 共用 TabController，滑块连续跟随内容区滑动。
  Widget _iosSegmentedTabs() {
    const tabs = DynamicsTabType.values;
    return PLTabSegmentedTabs<DynamicsTabType>(
      controller: _dynamicsController.tabController,
      values: tabs,
      labelOf: (e) => e.label,
      onTap: (_) {
        feedBack();
        // 官方语义：切页动画期间不抢着滚列表，仅点击当前 tab 时回顶部。
        if (!_dynamicsController.tabController.indexIsChanging) {
          _dynamicsController.animateToTop();
        }
      },
    );
  }

  Widget upPanelPart(ColorScheme colorScheme) {
    final isTop = upPanelPosition == .top;
    final needBg = upPanelPosition.index > 2;
    // iOS：UP 侧栏用系统分组背景，与右侧内容区（白 / 卡片）拉开层级。
    // 横向（top）时不需要，它本身就是内容区上方的一条。
    final isIOS = Adaptive.isIOS(context);
    final Color? bgColor = isIOS && !isTop
        ? IosColors.groupedBackground(Theme.of(context).brightness)
        : needBg
        ? colorScheme.surface
        : null;
    return Material(
      type: bgColor != null ? .canvas : .transparency,
      color: bgColor,
      child: SizedBox(
        width: isTop ? null : 64,
        height: isTop ? 76 : null,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 300) {
              _dynamicsController.onLoadMore();
            }
            return false;
          },
          child: Obx(
            () => _buildUpPanel(_dynamicsController.loadingState.value),
          ),
        ),
      ),
    );
  }

  Widget _buildUpPanel(LoadingState<FollowUpModel> upState) {
    return switch (upState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => UpPanel(
        upData: response,
        dynamicsController: _dynamicsController,
      ),
      Error() => Center(
        child: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _dynamicsController.onReload,
        ),
      ),
    };
  }

  bool get checkPage =>
      _mainController.navigationBars[0] != .dynamics &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    final isIOS = Adaptive.isIOS(context);

    Widget? drawer;
    Widget? endDrawer;

    Widget? leading;
    Widget actions;

    Widget child = tabBarView(
      controller: _dynamicsController.tabController,
      children: DynamicsTabType.values
          .map((e) => DynamicsTabPage(dynamicsType: e))
          .toList(),
    );

    switch (upPanelPosition) {
      case .top:
        child = Column(
          children: [
            upPanelPart(colorScheme),
            Expanded(child: child),
          ],
        );
        actions = _createDynamicBtn(colorScheme);
      case .leftFixed:
        child = Row(
          children: [
            upPanelPart(colorScheme),
            Expanded(child: child),
          ],
        );
        actions = _createDynamicBtn(colorScheme);
      case .rightFixed:
        child = Row(
          children: [
            Expanded(child: child),
            upPanelPart(colorScheme),
          ],
        );
        actions = _createDynamicBtn(colorScheme);
      case .leftDrawer:
        drawer = upPanelPart(colorScheme);
        actions = _createDynamicBtn(colorScheme);
        leading = const DrawerButton();
      case .rightDrawer:
        endDrawer = upPanelPart(colorScheme);
        leading = _createDynamicBtn(colorScheme, isRight: false);
        actions = const EndDrawerButton();
    }

    return Scaffold(
      primary: false,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const .fromHeight(52),
        child: isIOS
            ? _iosTopBar(leading: leading, actions: actions)
            : Row(
                children: [
                  ?leading,
                  Expanded(
                    child: TabBar(
                      dividerHeight: 0,
                      isScrollable: true,
                      tabAlignment: .start,
                      dividerColor: Colors.transparent,
                      labelColor: colorScheme.primary,
                      indicatorColor: colorScheme.primary,
                      controller: _dynamicsController.tabController,
                      unselectedLabelColor: colorScheme.onSurface,
                      labelStyle:
                          TabBarTheme.of(context).labelStyle?.copyWith(
                            fontSize: 13,
                          ) ??
                          const TextStyle(fontSize: 13),
                      tabs: DynamicsTabType.values
                          .map((e) => Tab(text: e.label))
                          .toList(),
                      onTap: (index) {
                        if (!_dynamicsController
                            .tabController
                            .indexIsChanging) {
                          _dynamicsController.animateToTop();
                        }
                      },
                    ),
                  ),
                  actions,
                ],
              ),
      ),
      drawer: drawer,
      endDrawer: endDrawer,
      body: onBuild(child),
    );
  }
}
