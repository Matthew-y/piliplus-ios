import 'dart:io';

import 'package:PiliPlus/common/widgets/adaptive/pl_grouped_card.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_popover.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/models_new/history/history.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/models_new/later/stat.dart';
import 'package:PiliPlus/models_new/space/space_cheese/item.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/pages/follow/widgets/follow_item.dart';
import 'package:PiliPlus/pages/history/widgets/item.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/pages/later/widgets/video_card_h_later.dart';
import 'package:PiliPlus/pages/member_cheese/widgets/item.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

/// 这批列表项的 44pt 点击区断言。
///
/// 用真实 widget（`HistoryItem` / `MemberCheeseItem` / `FollowItem`），不用复刻结构：
/// 上一轮的问题正是「按几何中心推算」而不是测量，这里全部走
/// `getRect` + `hitTestOnBinding`。
void main() {
  late Directory tempDir;

  // PendantAvatar 会读 Pref.showDecorate（关注行），需要真实的 setting box。
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('piliplus-hit-target-');
    Hive.init(tempDir.path);
    GStorage.setting = await Hive.openBox('setting');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Widget wrap(Widget child, {required TargetPlatform platform}) => MaterialApp(
    theme: ThemeData(platform: platform),
    home: Scaffold(body: child),
  );

  /// [globalPoint] 是否命中 [finder] 对应的 render object。
  bool hits(WidgetTester tester, Finder finder, Offset globalPoint) {
    final target = tester.renderObject(finder);
    final result = tester.hitTestOnBinding(globalPoint);
    return result.path.any((entry) => entry.target == target);
  }

  group('历史行 · 菜单热区', () {
    Widget buildList() => Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: PLGrouped.sliverGridOrList(
              context: context,
              materialGridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisExtent: 110,
                    maxCrossAxisExtent: 480,
                  ),
              itemCount: 3,
              itemBuilder: (context, index) => HistoryItem(
                item: _historyModel(index),
                ctr: _FakeMultiSelect(),
                onDelete: (kid, business) {},
              ),
            ),
          ),
        ],
      ),
    );

    testWidgets('iOS：行高 115，菜单 44×44 完整落在行内且可点', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(buildList(), platform: TargetPlatform.iOS));

      final row = tester.getRect(find.byType(HistoryItem).first);
      expect(row.height, 115, reason: 'iOS 行高比 Material 网格多 5pt');

      final menu = tester.getRect(find.byType(PLPopupMenuButton).first);
      expect(menu.size, const Size(44, 44));
      // 热区底边与行下沿齐平：不能有像素落在 Stack 之外（否则参与不了 hitTest）。
      expect(menu.bottom, closeTo(row.bottom, 0.01));
      expect(menu.top, greaterThanOrEqualTo(row.top));

      // 贴着下沿 1pt 处必须命中菜单本身。
      expect(
        hits(
          tester,
          find.byType(PLPopupMenuButton).first,
          menu.bottomCenter.translate(0, -1),
        ),
        isTrue,
      );

      await tester.tapAt(menu.bottomCenter.translate(0, -1));
      await tester.pumpAndSettle();
      expect(find.text('删除记录'), findsWidgets);
    });

    testWidgets('Material：行高 110、菜单 29×29，未套分组行', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(buildList(), platform: TargetPlatform.android),
      );

      expect(find.byType(PLGroupedRow), findsNothing);
      expect(tester.getRect(find.byType(HistoryItem).first).height, 110);
      expect(
        tester.getRect(find.byType(PLPopupMenuButton).first).size,
        const Size(29, 29),
      );
    });

    testWidgets('iOS 多列：卡片高度同样是 115（行高变化对两种形态一致）', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(992, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(buildList(), platform: TargetPlatform.iOS));

      expect(find.byType(PLGroupedCard), findsWidgets);
      expect(find.byType(PLGroupedRow), findsNothing);
      expect(tester.getRect(find.byType(HistoryItem).first).height, 115);
    });
  });

  group('课堂行 · 移除热区', () {
    testWidgets('iOS：44×44 贴在内容区底边，点下沿命中且触发回调', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var removed = false;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 115,
            child: MemberCheeseItem(
              item: SpaceCheeseItem(
                title: '课堂标题',
                status: '已完结',
                ctime: '1700000000',
                seasonId: 1,
              ),
              onRemove: () => removed = true,
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      final btn = tester.getRect(find.byType(IconButton));
      expect(btn.size, const Size(44, 44));
      // 行高 115 - Padding(vertical: 5) → 内容区 5..110，按钮底边贴内容区底边。
      expect(btn.bottom, closeTo(110, 0.01));
      expect(
        hits(tester, find.byType(IconButton), btn.bottomCenter.translate(0, -1)),
        isTrue,
      );

      await tester.tapAt(btn.bottomCenter.translate(0, -1));
      await tester.pumpAndSettle();
      expect(removed, isTrue);
    });
  });

  group('稍后再看行 · 移除热区', () {
    testWidgets('iOS：44×44 贴在内容区底边，点下沿命中并弹确认框', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ctr = LaterController(LaterViewType.all);
      addTearDown(ctr.onClose);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 115,
            child: VideoCardHLater(
              index: 0,
              ctr: ctr,
              videoItem: LaterItemModel(
                aid: 1,
                title: '稍后再看的视频',
                pic: '',
                cid: 1,
                duration: 300,
                progress: 60,
                owner: Owner(name: 'UP 主'),
                stat: Stat(view: 100, danmaku: 1),
              ),
              onViewLater: (_) {},
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      final btn = tester.getRect(find.byType(IconButton));
      expect(btn.size, const Size(44, 44));
      expect(btn.bottom, closeTo(110, 0.01));
      expect(
        hits(tester, find.byType(IconButton), btn.bottomCenter.translate(0, -1)),
        isTrue,
      );

      await tester.tapAt(btn.bottomCenter.translate(0, -1));
      await tester.pumpAndSettle();
      expect(find.text('即将移除该视频，确定是否移除'), findsOneWidget);
    });
  });

  group('关注行 · 关注按钮热区', () {
    testWidgets('iOS：只留 padded，命中区 48、行高由它撑到 68', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          // 真实列表里行高由内容决定（纵向无界），这里用可滚动容器复现。
          SingleChildScrollView(
            child: FollowItem(
              item: FollowItemModel(
                mid: 1,
                uname: 'up',
                face: null,
                sign: '签名',
              ),
              isOwner: true,
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );

      // 行高 68 = padded 的 48pt 命中区 + 上下各 10pt 内边距；去掉 minimumSize
      // 并不会把它压回 65，变小的只是胶囊本身的视觉高度。
      expect(tester.getSize(find.byType(FollowItem)).height, 68);

      final btn = tester.getRect(find.byType(FilledButton));
      expect(btn.height, 48, reason: 'padded 给到 48×48 命中区');
      expect(btn.height, greaterThanOrEqualTo(44));

      // 胶囊（按钮内部那层 Material）比命中区小，这就是 N2 要的「只扩热区」。
      final pill = tester.getRect(
        find
            .descendant(
              of: find.byType(FilledButton),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pill.height, lessThan(btn.height));
      debugPrint('follow pill=$pill hitBox=$btn');

      expect(
        hits(tester, find.byType(FilledButton), btn.bottomCenter.translate(0, -1)),
        isTrue,
      );
    });

    testWidgets('Material：行高 65、命中区等于胶囊（未加 padded）', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: FollowItem(
              item: FollowItemModel(
                mid: 1,
                uname: 'up',
                face: null,
                sign: '签名',
              ),
              isOwner: true,
            ),
          ),
          platform: TargetPlatform.android,
        ),
      );

      expect(tester.getSize(find.byType(FollowItem)).height, 65);
      expect(tester.getRect(find.byType(FilledButton)).height, lessThan(44));
    });
  });
}

HistoryItemModel _historyModel(int index) => HistoryItemModel(
  history: History(business: 'archive', oid: 1, bvid: 'BV1xx411c7mD'),
  title: '历史视频 $index',
  cover: '',
  videos: 1,
  authorName: 'UP 主',
  viewAt: 1700000000,
  kid: index + 1,
);

class _FakeMultiSelect implements MultiSelectBase<HistoryItemModel> {
  @override
  final RxBool enableMultiSelect = false.obs;

  @override
  int get checkedCount => 0;

  @override
  void onSelect(HistoryItemModel item) {}

  @override
  void handleSelect({bool checked = false, bool disableSelect = true}) {}

  @override
  void onRemove() {}
}
