import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/empty_state.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models_new/msg/msg_like_detail/card.dart';
import 'package:PiliPlus/models_new/msg/msg_like_detail/item.dart';
import 'package:PiliPlus/pages/msg_feed_top/like_detail/controller.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_strings.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_style.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LikeDetailPage extends StatefulWidget {
  const LikeDetailPage({super.key});

  @override
  State<LikeDetailPage> createState() => _LikeDetailPageState();
}

class _LikeDetailPageState extends State<LikeDetailPage> {
  final LikeDetailController _controller = Get.put(
    LikeDetailController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text(MsgStrings.likeDetail)),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
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
                () => _buildBody(theme, _controller.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<MsgLikeDetailItem>?> loadingState,
  ) {
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
        // 接口可能只返回 card 不返回 items，兜底成空列表而不是强解包。
        final items = response ?? const <MsgLikeDetailItem>[];
        final card = _controller.card;
        return SliverMainAxisGroup(
          slivers: [
            if (card != null) ...[
              _buildCard(card, isLast: items.isEmpty),
              SliverToBoxAdapter(
                child: Adaptive.isIOS(context)
                    ? const SizedBox(height: 12)
                    : Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
              ),
            ],
            if (items.isNotEmpty)
              SliverList.separated(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  if (index == items.length - 1) {
                    _controller.onLoadMore();
                  }
                  return _buildItem(
                    theme,
                    items[index],
                    isFirst: card == null && index == 0,
                    isLast: index == items.length - 1,
                  );
                },
                separatorBuilder: (context, index) =>
                    MsgFeedStyle.divider(context),
              )
            else if (card == null)
              const EmptyState(message: MsgStrings.emptyLikeDetail),
          ],
        );
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: _controller.onReload,
        );
    }
  }

  Widget _buildCard(MsgLikeDetailCard card, {required bool isLast}) {
    return SliverToBoxAdapter(
      child: MsgFeedStyle.card(
        context,
        ListTile(
          tileColor: MsgFeedStyle.tileColor(context),
          onTap: () {
            if (_controller.uri != null) {
              PiliScheme.routePushFromUrl(_controller.uri!);
            }
          },
          title: Text('${card.business}: ${card.title}'),
        ),
        isFirst: true,
        isLast: isLast,
      ),
    );
  }

  Widget _buildItem(
    ThemeData theme,
    MsgLikeDetailItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final user = item.user;
    // 脏数据兜底：没有用户信息时跳过该条，避免 user!.mid 崩溃。
    if (user == null) return const SizedBox.shrink();
    return MsgFeedStyle.card(
      context,
      ListTile(
        tileColor: MsgFeedStyle.tileColor(context),
        onTap: () => Get.toNamed('/member?mid=${user.mid}'),
        leading: NetworkImgLayer(
          width: 45,
          height: 45,
          type: ImageType.avatar,
          src: user.avatar,
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "${user.nickname}",
                style: theme.textTheme.titleSmall!.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              TextSpan(
                text: " 赞了我",
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormatUtils.dateFormat(item.likeTime),
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            color: theme.colorScheme.outline,
          ),
        ),
      ),
      isFirst: isFirst,
      isLast: isLast,
    );
  }
}
