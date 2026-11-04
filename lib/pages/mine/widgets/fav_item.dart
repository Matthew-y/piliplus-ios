import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavFolderItem extends StatelessWidget {
  const FavFolderItem({
    super.key,
    required this.item,
    required this.onPop,
  });

  final FavFolderInfo item;
  final VoidCallback onPop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTag = Utils.makeHeroTag(item.id);
    final isIOS = Adaptive.isIOS(context);
    return GestureDetector(
      onTap: () => Get.toNamed(
        '/favDetail',
        arguments: item,
        parameters: {
          'mediaId': item.id.toString(),
          'heroTag': heroTag,
        },
      )?.whenComplete(onPop),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              // iOS：圆角 8，保持简洁封面。
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              boxShadow: isIOS
                  ? null
                  : [
                      BoxShadow(
                        color: theme.colorScheme.onInverseSurface.withValues(
                          alpha: 0.4,
                        ),
                        offset: const Offset(6, -8),
                        blurRadius: 0.0,
                        spreadRadius: 0.0,
                      ),
                    ],
            ),
            child: Hero(
              tag: heroTag,
              child: NetworkImgLayer(
                src: item.cover,
                width: 180,
                // 16:9，与 iOS 卡片一致。
                height: isIOS ? 101.25 : 110,
                borderRadius: isIOS
                    ? const BorderRadius.all(Radius.circular(8))
                    : Style.mdRadius,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ' ${item.title}',
            maxLines: 1,
            overflow: .ellipsis,
            style: const TextStyle(height: 1.42, letterSpacing: 0.3),
          ),
          Text(
            ' 共${item.mediaCount}条视频 · ${BiliUtils.isPublicFavText(item.attr)}',
            style: theme.textTheme.labelSmall!.copyWith(
              color: isIOS
                  ? IosColors.secondaryLabel(theme.brightness)
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
