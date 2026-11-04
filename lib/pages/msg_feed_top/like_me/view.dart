import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/dialog/simple_dialog_option.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/empty_state.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/pair.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pbenum.dart'
    show IMSettingType;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models_new/msg/msg_like/item.dart';
import 'package:PiliPlus/pages/msg_feed_top/like_me/controller.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_strings.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_style.dart';
import 'package:PiliPlus/pages/whisper_settings/view.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class LikeMePage extends StatefulWidget {
  const LikeMePage({super.key});

  @override
  State<LikeMePage> createState() => _LikeMePageState();
}

class _LikeMePageState extends State<LikeMePage> {
  final LikeMeController _likeMeController = Get.put(LikeMeController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(
        title: const Text(MsgStrings.receiveLike),
        actions: [
          IconButton(
            onPressed: () => Get.to(
              const WhisperSettingsPage(
                imSettingType: IMSettingType.SETTING_TYPE_OLD_RECEIVE_LIKE,
              ),
            ),
            icon: Icon(
              size: 20,
              Icons.settings,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: refreshIndicator(
        onRefresh: _likeMeController.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: MsgFeedStyle.sliverPadding(context).add(
                EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
              ),
              sliver: Obx(
                () => _buildBody(theme, _likeMeController.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, LoadingState loadingState) {
    switch (loadingState) {
      case Loading():
        return const SliverPrototypeExtentList(
          prototypeItem: MsgFeedTopSkeleton(),
          delegate: SliverSingleChildDelegate(
            count: 12,
            child: MsgFeedTopSkeleton(),
          ),
        );
      case Success(:final response):
        final divider = MsgFeedStyle.divider(context);
        return Builder(
          builder: (context) {
            Pair<List<MsgLikeItem>, List<MsgLikeItem>> pair = response;
            List<MsgLikeItem> latest = pair.first;
            List<MsgLikeItem> total = pair.second;
            if (latest.isNotEmpty || total.isNotEmpty) {
              return SliverMainAxisGroup(
                slivers: [
                  if (latest.isNotEmpty) ...[
                    _buildHeader(context, theme, '最新'),
                    SliverList.separated(
                      itemBuilder: (context, index) {
                        final isLast = index == latest.length - 1;
                        if (total.isEmpty && isLast) {
                          _likeMeController.onLoadMore();
                        }
                        return _buildItem(
                          theme,
                          latest[index],
                          (id) {
                            _likeMeController.onRemove(id, index, true);
                          },
                          isFirst: index == 0,
                          isLast: isLast,
                        );
                      },
                      itemCount: latest.length,
                      separatorBuilder: (context, index) => divider,
                    ),
                  ],
                  if (total.isNotEmpty) ...[
                    _buildHeader(context, theme, '累计'),
                    SliverList.separated(
                      itemBuilder: (context, index) {
                        final isLast = index == total.length - 1;
                        if (isLast) {
                          _likeMeController.onLoadMore();
                        }
                        return _buildItem(
                          theme,
                          total[index],
                          (id) {
                            _likeMeController.onRemove(id, index, false);
                          },
                          isFirst: index == 0,
                          isLast: isLast,
                        );
                      },
                      itemCount: total.length,
                      separatorBuilder: (context, index) => divider,
                    ),
                  ],
                ],
              );
            }
            return const EmptyState(message: MsgStrings.emptyLike);
          },
        );
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: _likeMeController.onReload,
        );
    }
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    String title,
  ) {
    return SliverSafeArea(
      top: false,
      bottom: false,
      sliver: SliverToBoxAdapter(
        child: Padding(
          // iOS 下分组列表已有 16 的左右留白，标题跟着卡片对齐即可。
          padding: EdgeInsets.only(
            left: Adaptive.isIOS(context) ? 0 : 16,
            top: 4,
            bottom: 4,
          ),
          child: Text(
            title,
            style: theme.textTheme.labelLarge!.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    ThemeData theme,
    MsgLikeItem item,
    ValueChanged<int?> onRemove, {
    required bool isFirst,
    required bool isLast,
  }) {
    final users = item.users;
    // 接口偶尔只返回计数而不带用户信息，直接跳过该条，避免 users.first 崩溃。
    if (users == null || users.isEmpty) {
      return const SizedBox.shrink();
    }
    final firstUser = users.first;
    final counts = item.counts ?? 0;
    final id = item.id;

    Widget avatar;
    if (users.length == 1) {
      avatar = GestureDetector(
        onTap: () => Get.toNamed('/member?mid=${firstUser.mid}'),
        child: NetworkImgLayer(
          width: 45,
          height: 45,
          type: ImageType.avatar,
          src: firstUser.avatar,
        ),
      );
    } else {
      avatar = SizedBox(
        width: 45,
        height: 45,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var j = 0; j < users.length && j < 4; j++) ...[
              Positioned(
                left: 15.0 * (j % 2),
                top: 15.0 * (j ~/ 2),
                child: NetworkImgLayer(
                  width: 30,
                  height: 30,
                  type: ImageType.avatar,
                  src: users[j].avatar,
                ),
              ),
            ],
          ],
        ),
      );
    }
    void onLongPress() => showDialog(
      context: context,
      builder: (context) {
        final isNotice = item.noticeState == 0;
        return SimpleDialog(
          clipBehavior: Clip.hardEdge,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            DialogOption(
              onPressed: () {
                Get.back();
                showConfirmDialog(
                  context: context,
                  title: const Text('删除'),
                  content: const Text('该条通知删除后，当有新点赞时会重新出现在列表，是否继续？'),
                  destructive: true,
                  onConfirm: () {
                    if (id != null) onRemove(id);
                  },
                );
              },
              child: const Text('删除', style: TextStyle(fontSize: 14)),
            ),
            DialogOption(
              onPressed: () {
                Get.back();
                if (isNotice) {
                  showConfirmDialog(
                    context: context,
                    title: const Text('不再通知'),
                    content: const Text('这条内容的点赞将不再通知，但仍可在列表内查看，是否继续？'),
                    destructive: true,
                    onConfirm: () =>
                        _likeMeController.onSetNotice(item, isNotice),
                  );
                } else {
                  _likeMeController.onSetNotice(item, isNotice);
                }
              },
              child: Text(
                isNotice ? '不再通知' : '接收通知',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
    return MsgFeedStyle.card(
      context,
      ListTile(
        safeArea: true,
        tileColor: MsgFeedStyle.tileColor(context),
        onTap: () {
          final nativeUri = item.item?.nativeUri;
          final isInvalid =
              nativeUri == null ||
              nativeUri.isEmpty ||
              nativeUri.startsWith('?');
          if (counts > 1) {
            if (id == null) return;
            Get.toNamed(
              'msgLikeDetail',
              arguments: {
                'id': id.toString(),
                if (!isInvalid) 'uri': nativeUri,
                'counts': counts,
              },
            );
            return;
          }
          if (isInvalid) {
            return;
          }
          PiliScheme.routePushFromUrl(nativeUri);
        },
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        leading: avatar,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: firstUser.nickname,
                style: theme.textTheme.titleSmall!.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (counts > 1)
                TextSpan(
                  text: ' 等$counts人',
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              TextSpan(
                text: ' 赞了我的${item.item?.business}',
                style: theme.textTheme.titleSmall!.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.item?.title?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                item.item!.title!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.outline,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormatUtils.dateFormat(item.likeTime),
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 13,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.item?.image?.isNotEmpty == true)
              NetworkImgLayer(
                width: 45,
                height: 45,
                src: item.item!.image,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            if (item.noticeState == 1) ...[
              if (item.item?.image?.isNotEmpty == true)
                const SizedBox(width: 4),
              Icon(
                size: 18,
                Icons.notifications_off,
                color: theme.colorScheme.outline,
              ),
            ],
          ],
        ),
      ),
      isFirst: isFirst,
      isLast: isLast,
    );
  }
}
