import 'package:PiliPlus/common/widgets/adaptive/pl_dialog.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoActionSheet, CupertinoAlertDialog;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// GlobalMaterialLocalizations 只在 material_ui 里，SDK 的 flutter/material 没有。
// 用它的复数形式 delegates 才会带上 GlobalCupertinoLocalizations.delegate，
// 否则 Cupertino 组件会断言失败。
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;
// 注意：项目的对话框用的是 material_ui 版本的 AlertDialog，与 SDK 版本是两个不同的类，
// 所以断言 Material 对话框时要按名称匹配；Cupertino 组件两边是同一份。

void main() {
  Widget wrap(Widget child, {required TargetPlatform platform}) => MaterialApp(
    theme: ThemeData(platform: platform),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    home: Scaffold(body: child),
  );

  group('showConfirmDialog', () {
    testWidgets('shows an AlertDialog on Android', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showConfirmDialog(
                context: context,
                title: const Text('确定？'),
              ),
              child: const Text('open'),
            ),
          ),
          platform: TargetPlatform.android,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'AlertDialog',
        ),
        findsOneWidget,
      );
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('shows a CupertinoAlertDialog on iOS', (tester) async {
      bool? result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmDialog(
                  context: context,
                  title: const Text('确定？'),
                );
              },
              child: const Text('open'),
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmDialog(
                  context: context,
                  title: const Text('确定？'),
                );
              },
              child: const Text('open'),
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('onConfirm is invoked after confirming', (tester) async {
      var called = false;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showConfirmDialog(
                  context: context,
                  title: const Text('确定？'),
                  onConfirm: () => called = true,
                );
              },
              child: const Text('open'),
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  group('showPLActionSheet', () {
    testWidgets('renders a CupertinoActionSheet with a cancel button', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPLActionSheet(
                context: context,
                title: '选择',
                items: [
                  PLActionSheetItem(title: '选项一', onTap: () => tapped = true),
                ],
              ),
              child: const Text('open'),
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('选择'), findsOneWidget);
      expect(find.text('选项一'), findsOneWidget);

      await tester.tap(find.text('选项一'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
