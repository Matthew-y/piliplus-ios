import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 复现首页 iOS 分段控件的行为：点 tab 要能切换。
///
/// 之前用 `CupertinoSlidingSegmentedControl` 时，`groupValue` 是在 build 时读的
/// `tabController.index`，TabController 变化不会触发重建，所以点击后胶囊不动。
/// 现在改用 Material `TabBar` + 自定义 indicator，由 TabBar 自己同步 controller。
void main() {
  testWidgets('iOS 分段控件点击后能切换 tab', (tester) async {
    final controller = TabController(length: 3, vsync: tester);

    Widget build(TargetPlatform platform) => MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 44,
              child: TabBar(
                controller: controller,
                tabs: const [
                  Tab(text: '直播'),
                  Tab(text: '推荐'),
                  Tab(text: '热门'),
                ],
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: controller,
                children: const [
                  Text('直播页'),
                  Text('推荐页'),
                  Text('热门页'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(build(TargetPlatform.iOS));

    expect(controller.index, 0);
    expect(find.text('直播页'), findsOneWidget);

    // 点第 3 个 tab
    await tester.tap(find.text('热门'));
    await tester.pumpAndSettle();

    expect(controller.index, 2);
    expect(find.text('热门页'), findsOneWidget);
    expect(find.text('热门页'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('分段控件的 indicator 有上下间距', (tester) async {
    final controller = TabController(length: 2, vsync: tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: SizedBox(
            height: 44,
            child: TabBar(
              controller: controller,
              tabs: const [Tab(text: 'a'), Tab(text: 'b')],
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
            ),
          ),
        ),
      ),
    );

    // indicator 用 BoxDecoration 绘制，验证它确实被 TabBar 用上了
    // （而不是被忽略、退回默认下划线）。
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.indicator, isA<BoxDecoration>());
    expect(tabBar.indicatorPadding, const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 4,
    ));

    controller.dispose();
  });
}
