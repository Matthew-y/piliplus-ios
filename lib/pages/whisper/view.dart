import 'package:PiliPlus/common/skeleton/whisper_item.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_popover.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/empty_state.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/route_aware_mixin.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_strings.dart';
import 'package:PiliPlus/pages/whisper/controller.dart';
import 'package:PiliPlus/pages/whisper/widgets/item.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/extension/three_dot_ext.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoColors;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class WhisperPage extends StatefulWidget {
  const WhisperPage({super.key});

  @override
  State<WhisperPage> createState() => _WhisperPageState();
}

class _WhisperPageState extends State<WhisperPage>
    with RouteAware, RouteAwareMixin {
  final _controller = Get.put(WhisperController());

  @override
  void didPopNext() {
    // 从通知子页 / 消息设置返回：重新拉未读并重建入口，
    // 让 disableLikeMsg 等设置的修改立即生效（P3-15）。
    _controller.queryMsgFeedUnread();
    setState(() {});
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isIOS = Adaptive.isIOS(context);

    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isIOS)
          _buildIosTopItems(context, theme, padding)
        else
          _buildTopItems(theme, padding),
        SliverPadding(
          padding: EdgeInsets.only(
            top: isIOS ? 8 : 0,
            bottom: padding.bottom + 100,
          ),
          sliver: Obx(() => _buildBody(_controller.loadingState.value, isIOS)),
        ),
      ],
    );

    return SimpleScaffold(
      appBar: AppBar(
        title: const Text(MsgStrings.messages),
        actions: [
          IconButton(
            tooltip: '新增粉丝',
            constraints: isIOS
                ? const BoxConstraints(minWidth: 44, minHeight: 44)
                : null,
            onPressed: () => Get.toNamed(
              '/webview',
              parameters: {
                'url':
                    'https://www.bilibili.com/h5/follow/newFans?navhide=1&${ThemeUtils.themeUrl(theme.isDark)}',
              },
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          Obx(() {
            final outsideItem = _controller.outsideItem.value;
            if (outsideItem != null && outsideItem.isNotEmpty) {
              return Row(
                mainAxisSize: .min,
                children: outsideItem.map((e) {
                  return IconButton(
                    tooltip: e.hasTitle() ? e.title : null,
                    constraints: isIOS
                        ? const BoxConstraints(minWidth: 44, minHeight: 44)
                        : null,
                    onPressed: () => e.type.action(
                      context: context,
                      controller: _controller,
                      item: e,
                    ),
                    icon: e.type.icon,
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            final threeDotItems = _controller.threeDotItems.value;
            if (threeDotItems != null && threeDotItems.isNotEmpty) {
              return PLPopupMenuButton(
                tooltip: '更多',
                itemBuilder: (context) {
                  return threeDotItems
                      .map(
                        (e) => PopupMenuItem(
                          onTap: () => e.type.action(
                            context: context,
                            controller: _controller,
                            item: e,
                          ),
                          child: Row(
                            children: [
                              e.type.icon,
                              Text('  ${e.title}'),
                            ],
                          ),
                        ),
                      )
                      .toList();
                },
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 5),
        ],
      ),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: isIOS
            ? SlidableAutoCloseBehavior(child: scrollView)
            : scrollView,
      ),
    );
  }

  Widget _buildBody(
    LoadingState<List<Session>?> loadingState,
    bool isIOS,
  ) {
    switch (loadingState) {
      case Loading():
        return const SliverPrototypeExtentList(
          prototypeItem: WhisperItemSkeleton(),
          delegate: SliverSingleChildDelegate(
            count: 12,
            child: WhisperItemSkeleton(),
          ),
        );
      case Success(:final response):
        if (response != null && response.isNotEmpty) {
          if (isIOS) {
            return SliverList.builder(
              itemCount: response.length,
              itemBuilder: (context, index) {
                if (index == response.length - 1) {
                  _controller.onLoadMore();
                }
                final item = response[index];
                return WhisperSessionItem(
                  item: item,
                  isFirst: index == 0,
                  isLast: index == response.length - 1,
                  onSetTop: (isTop, id) =>
                      _controller.onSetTop(item, index, isTop, id),
                  onSetMute: (isMuted, talkerUid) =>
                      _controller.onSetMute(item, isMuted, talkerUid),
                  onRemove: (talkerId) => _controller.onRemove(index, talkerId),
                );
              },
            );
          }
          final divider = Divider(
            indent: 72,
            endIndent: 20,
            height: 0,
            color: Colors.grey.withValues(alpha: 0.1),
          );
          return SliverList.separated(
            itemCount: response.length,
            itemBuilder: (context, index) {
              if (index == response.length - 1) {
                _controller.onLoadMore();
              }
              final item = response[index];
              return WhisperSessionItem(
                item: item,
                onSetTop: (isTop, id) =>
                    _controller.onSetTop(item, index, isTop, id),
                onSetMute: (isMuted, talkerUid) =>
                    _controller.onSetMute(item, isMuted, talkerUid),
                onRemove: (talkerId) => _controller.onRemove(index, talkerId),
              );
            },
            separatorBuilder: (context, index) => divider,
          );
        }
        return const EmptyState(message: MsgStrings.emptySession);
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: _controller.onReload,
        );
    }
  }

  /// iOS 顶部入口：白色圆角卡片内的纯文字 Tab，去掉 Material 的圆形图标底。
  Widget _buildIosTopItems(
    BuildContext context,
    ThemeData theme,
    EdgeInsets padding,
  ) {
    final brightness = theme.brightness;
    final cardBg = IosColors.secondaryGroupedBackground(brightness);
    final separator = IosColors.separator(brightness);
    final label = CupertinoColors.label.resolveFrom(context);
    final activeBlue = CupertinoColors.activeBlue.resolveFrom(context);

    return SliverPadding(
      padding: EdgeInsets.only(
        left: 16 + padding.left,
        right: 16 + padding.right,
        top: 8,
      ),
      sliver: SliverToBoxAdapter(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
            color: cardBg,
            child: Row(
              children: List.generate(
                _controller.msgFeedTopItems.length,
                (index) {
                  final item = _controller.msgFeedTopItems[index];
                  return Expanded(
                    child: Row(
                      children: [
                        if (index > 0)
                          Container(
                            width: 0.5,
                            height: 20,
                            color: separator,
                          ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (!item.enabled) {
                                SmartDialog.showToast(MsgStrings.disabled);
                                return;
                              }
                              // 不在点击瞬间清零：等子页返回后以服务端计数为准，
                              // 避免「点开即已读」的假象（见 controller 顶部说明）。
                              await Get.toNamed(item.route);
                              if (!mounted) return;
                              _controller.queryMsgFeedUnread();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 6,
                              ),
                              child: Obx(() {
                                final count = _controller.unreadCounts[index];
                                final enabled = item.enabled;
                                return Semantics(
                                  button: true,
                                  enabled: enabled,
                                  label:
                                      '${item.name}'
                                      '${MsgStrings.unreadSemantics(count)}'
                                      '${enabled ? '' : '，已禁用'}',
                                  excludeSemantics: true,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: count > 0
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: enabled
                                                ? (count > 0
                                                      ? activeBlue
                                                      : label)
                                                : label.withValues(alpha: 0.35),
                                          ),
                                        ),
                                      ),
                                      if (count > 0) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                          ),
                                          height: 18,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: activeBlue,
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: Text(
                                            count > 99 ? '99+' : '$count',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              height: 1,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopItems(ThemeData theme, EdgeInsets padding) {
    return SliverPadding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_controller.msgFeedTopItems.length, (index) {
            final item = _controller.msgFeedTopItems[index];
            return Semantics(
              button: true,
              enabled: item.enabled,
              label:
                  '${item.name}'
                  '${MsgStrings.unreadSemantics(_controller.unreadCounts[index])}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  if (!item.enabled) {
                    SmartDialog.showToast(MsgStrings.disabled);
                    return;
                  }
                  await Get.toNamed(item.route);
                  if (!mounted) return;
                  _controller.queryMsgFeedUnread();
                },
                child: Opacity(
                  opacity: item.enabled ? 1 : 0.35,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () {
                            final count = _controller.unreadCounts[index];
                            return Badge(
                              isLabelVisible: count > 0,
                              label: Text(count > 99 ? ' 99+ ' : ' $count '),
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: .circle,
                                  color: theme.colorScheme.onInverseSurface,
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
