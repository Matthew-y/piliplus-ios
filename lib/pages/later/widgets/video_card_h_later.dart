import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 水平布局
class VideoCardHLater extends StatelessWidget {
  const VideoCardHLater({
    super.key,
    required this.ctr,
    required this.index,
    required this.videoItem,
    required this.onViewLater,
  });
  final int index;
  final BaseLaterController ctr;
  final LaterItemModel videoItem;
  final ValueChanged<int> onViewLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enableMultiSelect = ctr.enableMultiSelect.value;

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(videoItem);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        onTap: enableMultiSelect
            ? () => ctr.onSelect(videoItem)
            : () => onPushLater(videoItem, onViewLater: onViewLater),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: Style.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    final double maxWidth = boxConstraints.maxWidth;
                    final double maxHeight = boxConstraints.maxHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NetworkImgLayer(
                          src: videoItem.pic,
                          width: maxWidth,
                          height: maxHeight,
                          cacheWidth: videoItem.dimension?.cacheWidth,
                        ),
                        ?videoItem.label,
                        ...videoItem.progressIndicator(theme.colorScheme),
                        Positioned.fill(
                          child: selectMask(
                            theme.colorScheme,
                            videoItem.checked,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              content(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget content(BuildContext context, ThemeData theme) {
    final isPgc = videoItem.isPgc == true && videoItem.bangumi != null;
    final isIOS = Adaptive.isIOS(context);
    // iOS 次要文字统一走系统 secondaryLabel。
    final secondaryColor = isIOS
        ? IosColors.secondaryLabel(theme.brightness)
        : theme.colorScheme.outline;
    // iOS 热区 44×44，图标 18 不变。热区底边对齐内容区底边，不往外探：
    // Stack 的 hitTest 只认自身 size 内的点，`bottom: -8` 探出去的那几 pt
    // 点不到。行高由 `PLGrouped.sliverGridOrList` 给到 115（Material 网格是
    // 110），多出的 5pt 正好抵掉按钮下移的距离，图标视觉位置不变。
    final btnSize = isIOS ? 44.0 : 36.0;
    final btnBottom = isIOS ? 0.0 : -8.0;
    Widget stat = StatWidget(
      type: StatType.play,
      value: videoItem.stat?.view,
    );
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isPgc
                ? [
                    Text(
                      videoItem.bangumi!.season!.title!,
                      style: TextStyle(
                        fontSize: theme.textTheme.bodyMedium!.fontSize,
                        height: 1.42,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      videoItem.subtitle!,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    stat,
                  ]
                : [
                    Expanded(
                      child: Text(
                        videoItem.title!,
                        style: TextStyle(
                          fontSize: theme.textTheme.bodyMedium!.fontSize,
                          height: 1.42,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      videoItem.owner!.name!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
                        color: secondaryColor,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      spacing: 8,
                      children: [
                        stat,
                        StatWidget(
                          type: StatType.danmaku,
                          value: videoItem.stat?.danmaku,
                        ),
                      ],
                    ),
                  ],
          ),
          Positioned(
            right: 0,
            bottom: btnBottom,
            child: iconButton(
              tooltip: '移除',
              onPressed: () => ctr.toViewDel(context, index, videoItem.aid!),
              icon: const Icon(Icons.clear),
              size: btnSize,
              iconSize: 18,
              iconColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> onPushLater(
  LaterItemModel item, {
  ValueChanged<int>? onViewLater,
}) async {
  if (item.isPugv ?? false) {
    PageUtils.viewPugv(seasonId: item.aid);
    return;
  }
  if (item.isPgc ?? false) {
    if (item.bangumi?.epId != null) {
      PageUtils.viewPgc(epId: item.bangumi!.epId, viewLater: true);
    } else if (item.redirectUrl?.isNotEmpty == true) {
      PageUtils.viewPgcFromUri(item.redirectUrl!, viewLater: true);
    }
    return;
  }
  try {
    final cid =
        item.cid ??
        await SearchHttp.ab2c(
          aid: item.aid,
          bvid: item.bvid,
        );
    if (cid != null) {
      if (onViewLater != null) {
        onViewLater(cid);
      } else {
        await PageUtils.toVideoPage(
          bvid: item.bvid,
          cid: cid,
          cover: item.pic,
          title: item.title,
          dimension: item.dimension,
          extraArguments: const {'viewLater': true},
        );
      }
    }
  } catch (err) {
    SmartDialog.showToast(err.toString());
  }
}
