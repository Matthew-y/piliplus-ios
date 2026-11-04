import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_search_bar.dart';
import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_insets_safe_area.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/pages/common/search/common_search_controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

abstract class CommonSearchPageState<S extends StatefulWidget, R, T>
    extends State<S> {
  CommonSearchController<R, T> get controller;

  List<Widget>? get extraActions => null;

  List<Widget>? get multiSelectActions => null;

  @override
  Widget build(BuildContext context) {
    if (controller case final MultiSelectBase multiCtr) {
      return Obx(() {
        final enableMultiSelect = multiCtr.enableMultiSelect.value;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              multiCtr.handleSelect();
            }
          },
          child: _build(true),
        );
      });
    }
    return _build(false);
  }

  Widget _build(bool multiSelect) {
    return SimpleScaffold(
      appBar: _buildBar(multiSelect),
      body: ViewInsetsSafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller.scrollController,
          slivers: [
            ViewSliverSafeArea(
              sliver: Obx(() => _buildBody(controller.loadingState.value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(bool multiSelect) {
    if (multiSelect) {
      final multiCtr = controller as MultiSelectBase;
      // 多选态沿用 Material 多选 AppBar；非多选态按当前外观选择搜索栏。
      if (multiCtr.enableMultiSelect.value) {
        return MultiSelectAppBarWidget(
          ctr: multiCtr,
          actions: multiSelectActions,
          child: _buildMaterialBar(),
        );
      }
    }
    return Adaptive.isIOS(context) ? _buildIosBar() : _buildMaterialBar();
  }

  /// iOS：与设置搜索页 / 搜索页同一套顶栏（圆角灰底输入框 + 取消，无返回箭头）。
  Widget _buildIosBar() {
    final actions = extraActions;
    return PLSearchBar(
      controller: controller.editController,
      focusNode: controller.focusNode,
      onChanged: (value) {
        if (value.isEmpty) {
          controller.loadingState.value = LoadingState.loading();
          controller.focusNode.requestFocus();
        }
      },
      onSubmitted: (_) => controller.onRefresh(),
      trailing: actions == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            ),
    );
  }

  AppBar _buildMaterialBar() {
    return AppBar(
      actions: [
        IconButton(
          tooltip: '搜索',
          onPressed: controller.onRefresh,
          icon: const Icon(Icons.search_outlined, size: 22),
        ),
        ...?extraActions,
        const SizedBox(width: 10),
      ],
      title: TextField(
        autofocus: true,
        focusNode: controller.focusNode,
        controller: controller.editController,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: '搜索',
          visualDensity: .standard,
          border: InputBorder.none,
          suffixIcon: IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.clear, size: 22),
            onPressed: () => controller
              ..loadingState.value = LoadingState.loading()
              ..onClear()
              ..focusNode.requestFocus(),
          ),
        ),
        onSubmitted: (value) => controller.onRefresh(),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<T>?> loadingState) {
    return switch (loadingState) {
      Loading() => const HttpError(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? buildList(response)
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget buildList(List<T> list);
}
