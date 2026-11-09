import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_segmented_tabs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _labels = <String>['推荐', '热门', '直播'];

/// 复刻首页 / 动态页的 iOS 顶栏 + TabBarView 组合。
Widget _harness(TabController controller, {ValueChanged<int>? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          PLTabSegmentedTabs<int>(
            controller: controller,
            values: const [0, 1, 2],
            labelOf: (i) => _labels[i],
            onTap: onTap,
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: [
                for (final label in _labels) Center(child: Text(label)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Finder _tabLabel(String label) => find.descendant(
  of: find.byType(TabBar),
  matching: find.text(label),
);

void main() {
  late TabController controller;

  setUp(() {
    controller = TabController(
      length: _labels.length,
      vsync: const TestVSync(),
    );
  });

  tearDown(() => controller.dispose());

  /// 向左拖 250/400 = 0.625 页，手指保持按下（不触发 ScrollEnd）。
  Future<TestGesture> dragPastHalf(WidgetTester tester) async {
    final gesture = await tester.startGesture(const Offset(200, 500));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
    }
    return gesture;
  }

  testWidgets('官方联动契约：TabBar 与 TabBarView 共用 controller，滑块为白胶囊', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(controller));

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller, same(controller));
    expect(tabBar.indicator, isA<BoxDecoration>());
    expect(tabBar.isScrollable, isFalse, reason: '等宽分段控件');
    expect(tester.getSize(find.byType(PLTabSegmentedTabs<int>)).height, 32);
  });

  testWidgets('拖过半页、手指未松开时，选中态已开始跟随', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(controller));

    final gesture = await dragPastHalf(tester);
    expect(controller.animation!.value, greaterThan(0.5));
    expect(controller.index, 0, reason: 'TabBarView 尚未结算 index');

    // TabBar 的 _TabStyle 按 animation.value 连续插值文字颜色：此时下一项
    // 已经不是纯「未选中色」，说明滑块与文字都在跟手，无需等滚动结束。
    final style = DefaultTextStyle.of(tester.element(_tabLabel('热门'))).style;
    expect(style.color, isNot(IosColors.secondaryLabel(Brightness.light)));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.index, 1);
  });

  testWidgets('点击切换：一帧内 index 更新且 onTap 收到点击', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tapped = <int>[];
    await tester.pumpWidget(_harness(controller, onTap: tapped.add));

    await tester.tap(_tabLabel('热门'));
    await tester.pump();

    expect(controller.index, 1);
    expect(tapped, [1]);
    await tester.pumpAndSettle();
  });

  testWidgets('点击当前 tab：onTap 仍回调，indexIsChanging 为 false（可回顶部）', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final states = <bool>[];
    await tester.pumpWidget(
      _harness(
        controller,
        onTap: (_) => states.add(controller.indexIsChanging),
      ),
    );

    await tester.tap(_tabLabel('推荐'));
    await tester.pump();

    expect(states, [false], reason: '官方 onTap 语义：点击当前项不启动切页动画');
  });

  testWidgets('滑动期间 TabBar 完全不重建（滑块由 CustomPainter 连续重绘）', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(controller));

    final instances = <int>{};
    final gesture = await tester.startGesture(const Offset(200, 500));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      instances.add(
        identityHashCode(tester.widget<TabBar>(find.byType(TabBar))),
      );
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(instances.length, 1);
  });
}
