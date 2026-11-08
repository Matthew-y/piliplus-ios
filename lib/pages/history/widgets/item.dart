import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_popover.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HistoryItem extends StatelessWidget {
  final HistoryItemModel item;
  final MultiSelectBase ctr;
  final void Function(int kid, String business) onDelete;

  const HistoryItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Adaptive.isIOS(context);
    final secondaryColor = isIOS
        ? IosColors.secondaryLabel(theme.brightness)
        : theme.colorScheme.outline;
    final hasDuration = item.hasDuration;
    final business = item.history.business;
    final enableMultiSelect = ctr.enableMultiSelect.value;
    // iOS 热区 44×44，图标仍是 18。热区底边与卡片下沿齐平，不往下探：
    // Stack 的 hitTest 以自身 size 为界，超出的部分既不给子节点也不给父节点，
    // 所以 `bottom` 取负数只会让底部那段变成死区。行高由
    // `PLGrouped.sliverGridOrList` 给到 115（比 Material 网格的 110 多 5），
    // 44 的热区才完整落在行内，图标视觉中心也维持在原来的位置。
    final menuTapSize = isIOS ? 44.0 : 29.0;
    final menuRight = 12 - (menuTapSize - 29) / 2;

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(item);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enableMultiSelect
            ? () => ctr.onSelect(item)
            : () => onPushHistory(item),
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: Style.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        double maxWidth = boxConstraints.maxWidth;
                        double maxHeight = boxConstraints.maxHeight;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NetworkImgLayer(
                              src: item.cover?.isNotEmpty == true
                                  ? item.cover
                                  : item.covers?.firstOrNull ?? '',
                              width: maxWidth,
                              height: maxHeight,
                            ),
                            ?item.label,
                            if (hasDuration)
                              ...item.progressIndicator(theme.colorScheme),
                            Positioned.fill(
                              child: selectMask(
                                theme.colorScheme,
                                item.checked,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  content(theme, secondaryColor),
                ],
              ),
            ),
            Positioned(
              right: menuRight,
              bottom: 0,
              width: menuTapSize,
              height: menuTapSize,
              child: PLPopupMenuButton(
                padding: EdgeInsets.zero,
                tooltip: '功能菜单',
                icon: Icon(
                  Icons.more_vert_outlined,
                  color: secondaryColor,
                  size: 18,
                ),
                position: PopupMenuPosition.under,
                itemBuilder: (_) => [
                  if (item.authorMid != null &&
                      item.authorName?.isNotEmpty == true)
                    PopupMenuItem(
                      onTap: () => Get.toNamed('/member?mid=${item.authorMid}'),
                      height: 38,
                      child: Row(
                        children: [
                          const Icon(
                            MdiIcons.accountCircleOutline,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '访问：${item.authorName}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  if (business != 'pgc' &&
                      item.badge != '番剧' &&
                      item.tagName?.contains('动画') != true &&
                      business != 'live' &&
                      business?.contains('article') != true)
                    PopupMenuItem(
                      onTap: () =>
                          UserHttp.toViewLater(bvid: item.history.bvid),
                      height: 38,
                      child: const Row(
                        children: [
                          Icon(Icons.watch_later_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('稍后再看', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () => onDelete(item.kid!, business!),
                    height: 38,
                    child: const Row(
                      children: [
                        Icon(Icons.close_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('删除记录', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget content(ThemeData theme, Color secondaryColor) {
    return Expanded(
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title!,
            style: TextStyle(
              fontSize: theme.textTheme.bodyMedium!.fontSize,
              height: 1.42,
              letterSpacing: 0.3,
            ),
            maxLines: item.videos! > 1 ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.history.business == 'pgc' &&
              item.showTitle?.isNotEmpty == true)
            Text(
              item.showTitle!,
              style: TextStyle(
                fontSize: 13,
                color: secondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          if (item.authorName?.isNotEmpty == true)
            Text(
              item.authorName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: secondaryColor,
              ),
            ),
          Text(
            DateFormatUtils.chatFormat(item.viewAt!, isHistory: true),
            style: TextStyle(
              fontSize: theme.textTheme.labelMedium!.fontSize,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> onPushHistory(HistoryItemModel item) async {
  final business = item.history.business;
  if (business?.contains('article') == true) {
    ArticlePage.toArticlePage(
      id: (business == 'article-list' ? item.history.cid : item.history.oid)
          .toString(),
      type: .read,
    );
  } else if (business == 'live') {
    if (item.liveStatus == 1) {
      PageUtils.toLiveRoom(item.history.oid);
    } else {
      SmartDialog.showToast('直播未开播');
    }
  } else if (business == 'pgc') {
    PageUtils.viewPgc(
      epId: item.history.epid,
      progress: item.playbackProgress,
    );
  } else if (business == 'cheese') {
    if (item.uri?.isNotEmpty == true) {
      PageUtils.viewPgcFromUri(
        item.uri!,
        isPgc: false,
        aid: item.history.oid,
        progress: item.playbackProgress,
      );
    }
  } else {
    final aid = item.history.oid!;
    final bvid = item.history.bvid ?? IdUtils.av2bv(aid);
    int? cid = item.history.cid;
    Dimension? dimension;
    if (cid == null) {
      if (await SearchHttp.ab2cWithDimension(
            aid: aid,
            bvid: bvid,
            part: item.history.page,
          )
          case final res?) {
        cid = res.cid;
        dimension = res.dimension;
      }
    }
    if (cid != null) {
      // TODO: dimension
      PageUtils.toVideoPage(
        aid: aid,
        bvid: bvid,
        cid: cid,
        cover: item.cover,
        title: item.title,
        dimension: dimension,
        progress: item.playbackProgress,
      );
    }
  }
}
