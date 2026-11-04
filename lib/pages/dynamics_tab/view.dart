import 'dart:async';

import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPlus/pages/dynamics_tab/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/waterfall.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class DynamicsTabPage extends StatefulWidget {
  const DynamicsTabPage({super.key, required this.dynamicsType});

  final DynamicsTabType dynamicsType;

  @override
  State<DynamicsTabPage> createState() => _DynamicsTabPageState();
}

class _DynamicsTabPageState extends State<DynamicsTabPage>
    with AutomaticKeepAliveClientMixin, DynMixin {
  final dynamicsController = Get.putOrFind(DynamicsController.new);
  late final DynamicsTabController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = Get.putOrFind(
      () => DynamicsTabController(dynamicsType: widget.dynamicsType),
      tag: widget.dynamicsType.name,
    );
    super.initState();
  }

  Future<void> onRefresh() {
    dynamicsController.singleRefresh();
    return controller.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isCard =
        Adaptive.isIOS(context) && !GlobalData().dynamicsWaterfallFlow;
    return refreshIndicator(
      onRefresh: onRefresh,
      child: ColoredBox(
        // iOS：列表卡片需要灰色分组背景衬托，圆角才可见。
        color: isCard
            ? IosColors.groupedBackground(Theme.of(context).brightness)
            : Colors.transparent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller.scrollController,
          slivers: [
            SliverPadding(
              // 第一项距离顶部的间距与卡片间距一致。
              padding: EdgeInsets.only(
                top: isCard ? DynamicPanel.cardGap : 0,
                bottom: 100,
              ),
              sliver: buildPage(
                Obx(() => _buildBody(controller.loadingState.value, isCard)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    LoadingState<List<DynamicItemModel>?> loadingState,
    bool isCard,
  ) {
    return switch (loadingState) {
      Loading() => dynSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? GlobalData().dynamicsWaterfallFlow
                  ? SliverMasonryGrid(
                      crossAxisSpacing: 4,
                      gridDelegate: dynGridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _itemBuilder(response, index),
                        childCount: response.length,
                      ),
                    )
                  : SliverList.builder(
                      itemBuilder: (context, index) => _itemBuilder(
                        response,
                        index,
                        isCard: isCard,
                      ),
                      itemCount: response.length,
                    )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _itemBuilder(
    List<DynamicItemModel> list,
    int index, {
    bool isCard = false,
  }) {
    if (index == list.length - 1) {
      controller.onLoadMore();
    }
    final item = list[index];
    return DynamicPanel(
      item: item,
      isCard: isCard,
      onRemove: (idStr) => controller.onRemove(index, idStr),
      onBlock: () => controller.onBlock(index),
      onUnfold: () => controller.onUnfold(item, index),
    );
  }
}
