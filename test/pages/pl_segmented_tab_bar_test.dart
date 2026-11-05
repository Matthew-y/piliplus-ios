import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_segmented_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// `/fav` 的 7 个分类，用来验证「可滚动、不被压扁、右缘不切字」。
const _labels = ['视频', '追番', '追剧', '专栏', '笔记', '话题', '课堂'];

void main() {
  late TabController controller;

  setUp(() {
    controller = TabController(length: _labels.length, vsync: const TestVSync());
  });

  tearDown(() => controller.dispose());

  /// 复刻四个列表页的分支写法：iOS 走 [PLSegmentedTabBar]，其余走原 `TabBar`。
  Widget harness({
    required TargetPlatform platform,
    void Function(int index)? onTap,
  }) => MaterialApp(
    theme: ThemeData(platform: platform),
    home: Scaffold(
      body: Builder(
        builder: (context) => Adaptive.isIOS(context)
            ? PLSegmentedTabBar(
                controller: controller,
                labels: _labels,
                onTap: onTap,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              )
            : TabBar(
                controller: controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _labels.map((title) => Tab(text: title)).toList(),
                onTap: onTap,
              ),
      ),
    ),
  );

  TextStyle styleOf(WidgetTester tester, String label) => tester
      .widget<Text>(
        find.descendant(
          of: find.byType(PLSegmentedTabBar),
          matching: find.text(label),
        ),
      )
      .style!;

  testWidgets('点击第 3 项：controller.index == 2 且 onTap 收到 2', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tapped = <int>[];
    await tester.pumpWidget(
      harness(platform: TargetPlatform.iOS, onTap: tapped.add),
    );

    await tester.tap(find.text('追剧'));
    await tester.pumpAndSettle();

    expect(controller.index, 2);
    expect(tapped, [2]);
    expect(styleOf(tester, '追剧').fontWeight, FontWeight.w600);
    expect(styleOf(tester, '视频').fontWeight, FontWeight.w400);
  });

  testWidgets('animateTo(1) 后选中态跟随到第 2 项', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(platform: TargetPlatform.iOS));

    expect(styleOf(tester, '视频').fontWeight, FontWeight.w600);

    controller.animateTo(1);
    await tester.pumpAndSettle();

    expect(styleOf(tester, '追番').fontWeight, FontWeight.w600);
    expect(styleOf(tester, '视频').fontWeight, FontWeight.w400);
  });

  testWidgets('滑动手势驱动的 index 变化同样跟随（TabBarView 同源）', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: PLSegmentedTabBar(controller: controller, labels: _labels),
          ),
          body: TabBarView(
            controller: controller,
            children: _labels.map((title) => Center(child: Text(title))).toList(),
          ),
        ),
      ),
    );

    // 向左滑一页：TabBarView 结算时把 index 置为 1。
    await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(controller.index, 1);
    expect(styleOf(tester, '追番').fontWeight, FontWeight.w600);
  });

  testWidgets('402pt 宽度下 7 个 tab 全部落在视口内，「课堂」不被右缘裁切', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(platform: TargetPlatform.iOS));

    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$label 左侧越界');
      expect(rect.right, lessThanOrEqualTo(402), reason: '$label 被右缘裁切');
    }
  });

  testWidgets('Material 分支仍渲染原 TabBar（不含 PLSegmentedTabBar）', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(platform: TargetPlatform.android));

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(PLSegmentedTabBar), findsNothing);
  });
}
