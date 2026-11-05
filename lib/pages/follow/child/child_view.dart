import 'dart:math';

import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_grouped_card.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/follow/child/child_controller.dart';
import 'package:PiliPlus/pages/follow/controller.dart';
import 'package:PiliPlus/pages/follow/widgets/follow_item.dart';
import 'package:PiliPlus/pages/follow_type/follow_same/view.dart';
import 'package:PiliPlus/pages/share/view.dart' show UserModel;
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FollowChildPage extends StatefulWidget {
  const FollowChildPage({
    super.key,
    this.tag,
    this.controller,
    required this.mid,
    this.tagid,
    this.onSelect,
  });

  final String? tag;
  final FollowController? controller;
  final int mid;
  final int? tagid;
  final ValueChanged<UserModel>? onSelect;

  @override
  State<FollowChildPage> createState() => _FollowChildPageState();
}

class _FollowChildPageState extends State<FollowChildPage>
    with AutomaticKeepAliveClientMixin {
  late String _tag;
  late FollowChildController _followController;

  String get _newTag =>
      '${widget.tag ?? Utils.generateRandomString(8)}${widget.tagid}';

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _tag = _newTag;
    _followController = Get.put(
      FollowChildController(widget.controller, widget.mid, widget.tagid),
      tag: _tag,
    );
  }

  @override
  void didUpdateWidget(FollowChildPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tagid != widget.tagid) {
      final newTag = _newTag;
      if (Get.isRegistered<FollowChildController>(tag: newTag)) {
        _followController = Get.find<FollowChildController>(tag: newTag);
      } else {
        Get.delete<FollowChildController>(tag: _tag);
        _initController();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return Padding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      child: refreshIndicator(
        onRefresh: _followController.onRefresh,
        child: CustomScrollView(
          controller: _followController.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_followController.loadSameFollow)
              Obx(
                () => _buildSameFollowing(
                  colorScheme,
                  _followController.sameState.value,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: padding.bottom + 100),
              sliver: Obx(
                () => _buildBody(_followController.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FollowItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SliverPrototypeExtentList(
        prototypeItem: MsgFeedTopSkeleton(),
        delegate: SliverSingleChildDelegate(
          count: 12,
          child: MsgFeedTopSkeleton(),
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.builder(
                itemCount: response.length,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _followController.onLoadMore();
                  }
                  final item = response[index];
                  return _groupedItem(
                    index: index,
                    count: response.length,
                    child: FollowItem(
                      item: item,
                      isOwner: widget.controller?.isOwner,
                      onSelect: widget.onSelect,
                      afterMod: (attr) {
                        item.attribute = attr == 0 ? -1 : 0;
                        _followController.loadingState.refresh();
                      },
                    ),
                  );
                },
              )
            : HttpError(onReload: _followController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _followController.onReload,
      ),
    };
  }

  /// iOS：把关注行放进 16pt 留白的分组卡片里（首项上圆角、末项下圆角）。
  ///
  /// Material 皮肤下 [PLGroupedRow] 原样返回 [child]，行高与缩进不变。
  Widget _groupedItem({
    required int index,
    required int count,
    required Widget child,
  }) {
    return PLGroupedRow(
      isFirst: index == 0,
      isLast: index == count - 1,
      // 16 外边距 + 45 头像 + 10 间距，让 hairline 和昵称左边缘对齐。
      dividerIndent: 71,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  Widget _buildSameFollowing(
    ColorScheme colorScheme,
    LoadingState<List<FollowItemModel>?> state,
  ) {
    final isIOS = Adaptive.isIOS(context);
    final labelStyle = TextStyle(
      fontSize: isIOS ? 13 : null,
      color: isIOS
          ? IosColors.secondaryLabel(Theme.of(context).brightness)
          : colorScheme.onSurfaceVariant,
    );
    final moreColor = isIOS
        ? IosColors.secondaryLabel(Theme.of(context).brightness)
        : colorScheme.outline;
    return switch (state) {
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('我们的共同关注', style: labelStyle),
                          moreTextButton(
                            onTap: () => FollowSamePage.toFollowSamePage(
                              mid: _followController.mid,
                              name: widget.controller?.name.value,
                            ),
                            color: moreColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: min(3, response.length),
                    itemBuilder: (_, index) => _groupedItem(
                      index: index,
                      count: min(3, response.length),
                      child: FollowItem(item: response[index]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 16,
                        bottom: 6,
                      ),
                      child: Text('全部关注', style: labelStyle),
                    ),
                  ),
                ],
              )
            : const SliverToBoxAdapter(),
      _ => const SliverToBoxAdapter(),
    };
  }

  @override
  bool get wantKeepAlive =>
      widget.onSelect != null || widget.controller?.tabController != null;
}
