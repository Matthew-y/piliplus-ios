import 'dart:convert';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_search_bar.dart';
import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/common/widgets/disabled_icon.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/sliver_wrap.dart';
import 'package:PiliPlus/common/widgets/view_insets_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/search/search_rcmd/data.dart';
import 'package:PiliPlus/models_new/search/search_trending/list.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search/widgets/hot_keyword.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/utils/em.dart' show Em;
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _tag = Utils.generateRandomString(6);
  late final SSearchController _searchController;
  late ThemeData theme;
  late bool isPortrait;
  late EdgeInsets padding;

  @override
  void initState() {
    super.initState();
    _searchController = Get.put(SSearchController(_tag), tag: _tag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    padding = MediaQuery.viewPaddingOf(context);
    isPortrait = MediaQuery.sizeOf(context).isPortrait;
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Adaptive.isIOS(context);
    final trending = _searchController.enableTrending
        ? _buildHotSearch()
        : null;
    final rcmd = _searchController.enableSearchRcmd
        ? _buildHotSearch(isTrending: false)
        : null;

    return SimpleScaffold(
      appBar: _buildAppBar,
      body: Padding(
        padding: .only(left: padding.left, right: padding.right),
        child: ViewInsetsSafeArea(
          child: isIOS
              ? _buildIosBody()
              : CustomScrollView(
                  slivers: [
                    if (_searchController.searchSuggestion)
                      _buildSearchSuggest(),
                    if (isPortrait) ...[
                      ?trending,
                      _buildHistory,
                      ?rcmd,
                    ] else if (trending != null || rcmd != null)
                      SliverCrossAxisGroup(
                        slivers: [
                          SliverMainAxisGroup(slivers: [?trending, ?rcmd]),
                          _buildHistory,
                        ],
                      )
                    else
                      _buildHistory,
                    SliverPadding(padding: .only(bottom: padding.bottom)),
                  ],
                ),
        ),
      ),
    );
  }

  /// iOS：灰色页面底色 + 白色分组卡片（对齐 App Store 搜索页）。
  Widget _buildIosBody() {
    final controller = _searchController;
    return CustomScrollView(
      slivers: [
        if (controller.searchSuggestion) _buildIosSearchSuggest(),
        SliverPadding(
          padding: .only(top: 8, bottom: padding.bottom + 24),
          sliver: SliverList.list(
            children: [
              if (controller.enableTrending) _iosTrendingModule,
              _iosHistoryModule,
              if (controller.enableSearchRcmd) _iosRcmdModule,
            ],
          ),
        ),
      ],
    );
  }

  Widget get _iosTrendingModule => Obx(() {
    final state = _searchController.trendingState.value;
    final list = switch (state) {
      Success(:final response) => response.list,
      _ => null,
    };
    // 没有数据时不要留一张空卡片（加载中 / 空列表）。
    if ((list?.isEmpty ?? true) && state is! Error) {
      return const SizedBox.shrink();
    }
    return _iosCard(
      _iosSection(
        title: '大家都在搜',
        isTrending: true,
        onRefresh: _searchController.queryTrendingList,
        keywords: list,
        keywordState: state,
      ),
    );
  });

  Widget get _iosRcmdModule => Obx(() {
    final state = _searchController.recommendData.value;
    final list = switch (state) {
      Success(:final response) => response.list,
      _ => null,
    };
    if ((list?.isEmpty ?? true) && state is! Error) {
      return const SizedBox.shrink();
    }
    return _iosCard(
      _iosSection(
        title: '搜索发现',
        isTrending: false,
        onRefresh: _searchController.queryRecommendList,
        keywords: list,
        keywordState: state,
      ),
    );
  });

  Widget get _iosHistoryModule => Obx(() {
    final list = _searchController.historyList;
    if (list.isEmpty) return const SizedBox.shrink();
    return _iosCard(
      Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              const _IosSectionTitle('搜索历史'),
              const SizedBox(width: 4),
              _recordBtn,
              _exportBtn,
              const Spacer(),
              _iosTextBtn(
                '清空',
                icon: Icons.delete_outline,
                onTap: _searchController.onClearHistory,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final text in list)
                SearchText(
                  text: text,
                  onTap: _searchController.onClickKeyword,
                  onLongPress: _searchController.onLongSelect,
                  fontSize: 14,
                  height: 1,
                  maxLines: 1,
                  overflow: .ellipsis,
                  borderRadius: const .all(.circular(8)),
                  padding: const .symmetric(horizontal: 10, vertical: 7),
                ),
            ],
          ),
        ],
      ),
    );
  });

  /// 白色圆角卡片：16 边距 + 浅灰底板上形成层级。
  Widget _iosCard(Widget child, {double top = 24}) => Container(
    margin: .fromLTRB(16, top, 16, 0),
    padding: const .fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: IosColors.secondaryGroupedBackground(theme.brightness),
      borderRadius: const .all(.circular(12)),
    ),
    child: child,
  );

  Widget _iosSection({
    required String title,
    required bool isTrending,
    required VoidCallback onRefresh,
    required List<SearchTrendingItemModel>? keywords,
    required LoadingState<SearchRcmdData> keywordState,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            _IosSectionTitle(title),
            if (isTrending) ...[
              const SizedBox(width: 8),
              _iosTextBtn(
                '完整榜单',
                chevron: true,
                onTap: () => Get.toNamed('/searchTrending'),
              ),
            ],
            const Spacer(),
            _iosTextBtn('刷新', icon: Icons.refresh, onTap: onRefresh),
          ],
        ),
        const SizedBox(height: 12),
        if (keywords != null && keywords.isNotEmpty)
          _iosKeywordRows(keywords)
        else if (keywordState is Error)
          Padding(
            padding: const .symmetric(vertical: 12),
            child: Text(
              keywordState.errMsg ?? '',
              style: TextStyle(
                fontSize: 13,
                color: IosColors.secondaryLabel(theme.brightness),
              ),
            ),
          ),
      ],
    );
  }

  /// 两列热词：行距 12，长文本省略号。
  Widget _iosKeywordRows(List<SearchTrendingItemModel> list) {
    return Column(
      children: [
        for (var i = 0; i < list.length; i += 2)
          Padding(
            padding: .only(top: i == 0 ? 0 : 12),
            child: Row(
              children: [
                Expanded(child: _iosKeywordItem(list[i])),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < list.length
                      ? _iosKeywordItem(list[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _iosKeywordItem(SearchTrendingItemModel item) {
    final secondary = IosColors.secondaryLabel(theme.brightness);
    final cacheHeight = (MediaQuery.devicePixelRatioOf(context) * 12.0).round();
    Widget? tag;
    if (item.icon?.isNotEmpty == true) {
      // 服务端下发的「新 / 热」图标，裁成小胶囊。
      tag = ClipRRect(
        borderRadius: const .all(.circular(6)),
        child: CachedNetworkImage(
          height: 12,
          memCacheHeight: cacheHeight,
          imageUrl: ImageUtils.thumbnailUrl(item.icon!),
          placeholder: (_, _) => const SizedBox.shrink(),
        ),
      );
    } else if (item.showLiveIcon == true) {
      tag = ClipRRect(
        borderRadius: const .all(.circular(6)),
        child: Image.asset(
          Assets.livingRect,
          width: 38,
          height: 12,
          cacheHeight: cacheHeight,
        ),
      );
    }
    return InkWell(
      onTap: () => _searchController.onClickKeyword(item.keyword),
      borderRadius: const .all(.circular(6)),
      child: Tooltip(
        message: item.showName,
        child: Row(
          children: [
            Flexible(
              child: Text(
                item.showName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (tag != null)
              Padding(padding: const .only(left: 5), child: tag)
            else if (item.recommendReason?.isNotEmpty == true)
              Flexible(
                child: Padding(
                  padding: const .only(left: 5),
                  child: Text(
                    item.recommendReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 右侧次要操作按钮（完整榜单 / 刷新 / 清空），统一次要色。
  Widget _iosTextBtn(
    String label, {
    IconData? icon,
    bool chevron = false,
    required VoidCallback onTap,
  }) {
    final color = IosColors.secondaryLabel(theme.brightness);
    return InkWell(
      onTap: onTap,
      borderRadius: const .all(.circular(6)),
      child: Padding(
        padding: const .symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: .min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 3),
            ],
            Text(label, style: TextStyle(fontSize: 13, color: color)),
            if (chevron) Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  /// iOS 搜索联想：白色卡片内的行列表。
  Widget _buildIosSearchSuggest() {
    return Obx(() {
      final list = _searchController.searchSuggestList;
      if (list.isEmpty ||
          list.first.term == null ||
          _searchController.controller.text == '') {
        return const SliverToBoxAdapter();
      }
      return SliverToBoxAdapter(
        child: _iosCard(
          Column(
            children: [
              for (final item in list)
                InkWell(
                  onTap: () => _searchController.onClickKeyword(
                    item.term!,
                    clearSuggest: false,
                  ),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const .symmetric(vertical: 10),
                    child: Text.rich(
                      TextSpan(
                        children: Em.regTitle(item.textRich)
                            .map(
                              (e) => TextSpan(
                                text: e.text,
                                style: e.isEm
                                    ? const TextStyle(
                                        fontWeight: .bold,
                                        color: IosColors.brandPink,
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget get _buildAppBar {
    if (Adaptive.isIOS(context)) {
      return PLSearchBar(
        controller: _searchController.controller,
        focusNode: _searchController.searchFocusNode,
        hintText: _searchController.hintText ?? '搜索',
        onChanged: _searchController.onChange,
        onSubmitted: (_) => _searchController.submit(),
        trailing: Obx(
          () => _searchController.showUidBtn.value
              ? IconButton(
                  tooltip: 'UID搜索用户',
                  iconSize: 22,
                  style: const ButtonStyle(tapTargetSize: .shrinkWrap),
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Get.toNamed(
                    '/member?mid=${_searchController.controller.text}',
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }
    return AppBar(
      shape: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      actions: [
        Obx(
          () => _searchController.showUidBtn.value
              ? IconButton(
                  tooltip: 'UID搜索用户',
                  icon: const Icon(Icons.person_outline, size: 22),
                  onPressed: () => Get.toNamed(
                    '/member?mid=${_searchController.controller.text}',
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          tooltip: '清空',
          icon: const Icon(Icons.clear, size: 22),
          onPressed: _searchController.onClear,
        ),
        IconButton(
          tooltip: '搜索',
          onPressed: _searchController.submit,
          icon: const Icon(Icons.search, size: 22),
        ),
        const SizedBox(width: 10),
      ],
      title: TextField(
        autofocus: true,
        focusNode: _searchController.searchFocusNode,
        controller: _searchController.controller,
        textInputAction: TextInputAction.search,
        onChanged: _searchController.onChange,
        decoration: InputDecoration(
          visualDensity: .standard,
          hintText: _searchController.hintText ?? '搜索',
          border: InputBorder.none,
        ),
        onSubmitted: (value) => _searchController.submit(),
      ),
    );
  }

  Widget _buildSearchSuggest() {
    return Obx(() {
      final list = _searchController.searchSuggestList;
      return list.isNotEmpty &&
              list.first.term != null &&
              _searchController.controller.text != ''
          ? SliverList.list(
              children: list
                  .map(
                    (item) => InkWell(
                      borderRadius: const .all(.circular(4)),
                      onTap: () => _searchController.onClickKeyword(
                        item.term!,
                        clearSuggest: false,
                      ),
                      child: Padding(
                        padding: const .only(left: 20, top: 9, bottom: 9),
                        child: Text.rich(
                          TextSpan(
                            children: Em.regTitle(item.textRich)
                                .map(
                                  (e) => TextSpan(
                                    text: e.text,
                                    style: e.isEm
                                        ? TextStyle(
                                            fontWeight: .bold,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          : const SliverToBoxAdapter();
    });
  }

  Widget _buildHotSearch({
    bool isTrending = true,
  }) {
    final text = Text(
      isTrending ? '大家都在搜' : '搜索发现',
      strutStyle: const StrutStyle(leading: 0, height: 1),
      style: theme.textTheme.titleMedium!.copyWith(
        height: 1,
        fontWeight: .bold,
      ),
    );
    final outline = theme.colorScheme.outline;
    final secondary = theme.colorScheme.secondary;
    final style = TextStyle(
      height: 1,
      fontSize: 13,
      color: outline,
    );
    return SliverPadding(
      padding: .fromLTRB(
        10,
        !isTrending && (isPortrait || _searchController.enableTrending)
            ? 4
            : 25,
        4,
        25,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const .fromLTRB(6, 0, 6, 6),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  isTrending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            text,
                            const SizedBox(width: 14),
                            TextButton(
                              style: const ButtonStyle(
                                visualDensity: .compact,
                                tapTargetSize: .shrinkWrap,
                                padding: WidgetStatePropertyAll(
                                  .symmetric(horizontal: 10),
                                ),
                              ),
                              onPressed: () => Get.toNamed('/searchTrending'),
                              child: Row(
                                children: [
                                  Text(
                                    '完整榜单',
                                    strutStyle: const StrutStyle(
                                      leading: 0,
                                      height: 1,
                                    ),
                                    style: style,
                                  ),
                                  Icon(
                                    size: 18,
                                    Icons.keyboard_arrow_right,
                                    color: outline,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : text,
                  TextButton.icon(
                    style: const ButtonStyle(
                      visualDensity: .compact,
                      tapTargetSize: .shrinkWrap,
                      padding: WidgetStatePropertyAll(
                        .symmetric(horizontal: 10),
                      ),
                    ),
                    onPressed: isTrending
                        ? _searchController.queryTrendingList
                        : _searchController.queryRecommendList,
                    icon: Icon(
                      Icons.refresh_outlined,
                      size: 18,
                      color: secondary,
                    ),
                    label: Text(
                      '刷新',
                      strutStyle: const StrutStyle(leading: 0, height: 1),
                      style: TextStyle(height: 1, color: secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => _buildHotKey(
              isTrending
                  ? _searchController.trendingState.value
                  : _searchController.recommendData.value,
              isTrending,
            ),
          ),
        ],
      ),
    );
  }

  late final mainAxisExtent = 16 + MediaQuery.textScalerOf(context).scale(14);
  Widget get _buildHistory {
    return Obx(
      () {
        final list = _searchController.historyList;
        if (list.isEmpty) {
          return const SliverToBoxAdapter();
        }
        final secondary = theme.colorScheme.secondary;
        return SliverPadding(
          padding: .fromLTRB(
            10,
            !isPortrait
                ? 25
                : _searchController.enableTrending
                ? 0
                : 6,
            6,
            25,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const .fromLTRB(6, 0, 6, 6),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        '搜索历史',
                        strutStyle: const StrutStyle(leading: 0, height: 1),
                        style: theme.textTheme.titleMedium!.copyWith(
                          height: 1,
                          fontWeight: .bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _recordBtn,
                      _exportBtn,
                      const Spacer(),
                      TextButton.icon(
                        style: const ButtonStyle(
                          visualDensity: .compact,
                          tapTargetSize: .shrinkWrap,
                          padding: WidgetStatePropertyAll(
                            .symmetric(horizontal: 10),
                          ),
                        ),
                        onPressed: _searchController.onClearHistory,
                        icon: Icon(
                          Icons.clear_all_outlined,
                          size: 18,
                          color: secondary,
                        ),
                        label: Text(
                          '清空',
                          style: TextStyle(height: 1, color: secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFixedWrap(
                mainAxisExtent: mainAxisExtent,
                spacing: 8,
                runSpacing: 8,
                delegate: SliverChildBuilderDelegate(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  childCount: list.length,
                  (context, index) => SearchText(
                    text: list[index],
                    onTap: _searchController.onClickKeyword,
                    onLongPress: _searchController.onLongSelect,
                    height: 1,
                    maxLines: 1,
                    fontSize: 14,
                    overflow: .ellipsis,
                    padding: const .fromLTRB(11, 8, 11, 0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget get _recordBtn => Obx(
    () {
      bool enable = _searchController.recordSearchHistory.value;
      return IconButton(
        iconSize: 22,
        tooltip: enable ? '记录搜索' : '无痕搜索',
        icon: DisabledIcon(
          disable: !enable,
          child: Icon(
            Icons.history,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        style: const ButtonStyle(
          visualDensity: .comfortable,
          tapTargetSize: .shrinkWrap,
          padding: WidgetStatePropertyAll(.zero),
        ),
        onPressed: () {
          enable = !enable;
          _searchController.recordSearchHistory.value = enable;
          GStorage.setting.put(
            SettingBoxKey.recordSearchHistory,
            enable,
          );
        },
      );
    },
  );

  Widget get _exportBtn => IconButton(
    iconSize: 22,
    tooltip: '导入/导出历史记录',
    icon: Icon(
      Icons.import_export_outlined,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
    ),
    style: const ButtonStyle(
      visualDensity: .comfortable,
      tapTargetSize: .shrinkWrap,
      padding: WidgetStatePropertyAll(.zero),
    ),
    onPressed: () => showImportExportDialog<List>(
      context,
      title: '历史记录',
      localFileName: () => 'search',
      onExport: () => jsonEncode(_searchController.historyList),
      onImport: (json) {
        final list = List<String>.from(json);
        _searchController.historyList.value = list;
        GStorage.historyWord.put('cacheList', list);
      },
    ),
  );

  Widget _buildHotKey(
    LoadingState<SearchRcmdData> loadingState,
    bool isTrending,
  ) {
    return switch (loadingState) {
      Success(:final response) when (response.list?.isNotEmpty ?? false) =>
        SliverHotKeyword(
          hotSearchList: response.list!,
          onClick: _searchController.onClickKeyword,
        ),
      Error(:final errMsg) => HttpError(
        safeArea: false,
        errMsg: errMsg,
        onReload: isTrending
            ? _searchController.queryTrendingList
            : _searchController.queryRecommendList,
      ),
      _ => const SliverToBoxAdapter(),
    };
  }
}

/// iOS 卡片里的模块标题。
class _IosSectionTitle extends StatelessWidget {
  const _IosSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
