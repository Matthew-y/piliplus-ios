import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_bottom_nav.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_switch.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoSwitch, CupertinoTabBar;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

void main() {
  // 用项目 main.dart 里真实的 delegate 配置：`GlobalMaterialLocalizations.delegates`
  // 才会带上 `GlobalCupertinoLocalizations.delegate`，否则 Cupertino 组件会断言失败。
  Widget wrap(Widget child, {required TargetPlatform platform}) => MaterialApp(
    theme: ThemeData(platform: platform),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    home: Scaffold(body: child),
  );

  group('Adaptive.isIOS', () {
    // 分成两个独立用例：MaterialApp 在同一 widget 树位置会复用 state，
    // 同一次 pumpWidget 里换 platform 不会触发 theme 更新。
    testWidgets('is true when the theme platform is iOS', (tester) async {
      late bool result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              result = Adaptive.isIOS(context);
              return const SizedBox.shrink();
            },
          ),
          platform: TargetPlatform.iOS,
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('is false when the theme platform is Android', (
      tester,
    ) async {
      late bool result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              result = Adaptive.isIOS(context);
              return const SizedBox.shrink();
            },
          ),
          platform: TargetPlatform.android,
        ),
      );
      expect(result, isFalse);
    });
  });

  group('PLSwitch', () {
    testWidgets('uses CupertinoSwitch on iOS', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PLSwitch(value: true, onChanged: null),
          platform: TargetPlatform.iOS,
        ),
      );
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('uses Material Switch elsewhere', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PLSwitch(value: true, onChanged: null),
          platform: TargetPlatform.android,
        ),
      );
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsNothing);
    });
  });

  group('PLBottomNav', () {
    const destinations = [
      PLNavDestination(label: '首页', icon: Icon(Icons.home)),
      PLNavDestination(label: '我的', icon: Icon(Icons.person)),
    ];

    testWidgets('uses CupertinoTabBar on iOS', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PLBottomNav(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: _noop,
          ),
          platform: TargetPlatform.iOS,
        ),
      );
      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('uses NavigationBar elsewhere', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PLBottomNav(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: _noop,
          ),
          platform: TargetPlatform.android,
        ),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(CupertinoTabBar), findsNothing);
    });
  });
}

void _noop(int index) {}
