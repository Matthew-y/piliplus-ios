import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/loading_widget/empty_state.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_style.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 回复 / @我 / 系统通知共用的 sliver 列表。
///
/// 负责 Loading 骨架、成功列表、空态与错误重试；行内容由 [itemBuilder] 提供。
/// 滚动到末项时自动触发 [CommonListController.onLoadMore]。
Widget buildMsgFeedSliver<T>({
  required BuildContext context,
  required CommonListController<dynamic, T> controller,
  required String emptyMessage,
  required Widget Function(
    BuildContext context,
    T item,
    int index, {
    required bool isFirst,
    required bool isLast,
  })
  itemBuilder,
  Widget? loading,
  double indent = 72,
  double? iosIndent,
}) {
  return Obx(() {
    switch (controller.loadingState.value) {
      case Loading():
        return loading ??
            const SliverPrototypeExtentList(
              prototypeItem: MsgFeedTopSkeleton(),
              delegate: SliverSingleChildDelegate(
                count: 12,
                child: MsgFeedTopSkeleton(),
              ),
            );
      case Success(:final response):
        if (response != null && response.isNotEmpty) {
          final divider = MsgFeedStyle.divider(
            context,
            indent: indent,
            iosIndent: iosIndent,
          );
          return SliverList.separated(
            itemCount: response.length,
            itemBuilder: (context, int index) {
              final isLast = index == response.length - 1;
              if (isLast) {
                controller.onLoadMore();
              }
              return itemBuilder(
                context,
                response[index],
                index,
                isFirst: index == 0,
                isLast: isLast,
              );
            },
            separatorBuilder: (context, index) => divider,
          );
        }
        return EmptyState(message: emptyMessage);
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: controller.onReload,
        );
    }
  });
}
