import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/share/view.dart' show UserModel;
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FollowItem extends StatelessWidget {
  final FollowItemModel item;
  final bool isOwner;
  final ValueChanged? afterMod;
  final ValueChanged<UserModel>? onSelect;

  const FollowItem({
    super.key,
    required this.item,
    this.afterMod,
    bool? isOwner,
    this.onSelect,
  }) : isOwner = isOwner ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = ColorScheme.of(context);
    final isIOS = Adaptive.isIOS(context);
    // iOS 次要文字用系统 secondaryLabel，避免 M3 主题派生出的偏粉灰。
    final secondaryColor = isIOS
        ? IosColors.secondaryLabel(theme.brightness)
        : colorScheme.outline;
    Widget? followBtn;
    if (isOwner) {
      final isFollow = item.attribute != -1;
      followBtn = FilledButton.tonal(
        onPressed: () => RequestUtils.actionRelationMod(
          context: context,
          mid: item.mid,
          isFollow: isFollow,
          afterMod: afterMod,
        ),
        style: isIOS
            // iOS 命中区 48×48（≥44）：padded 由 ButtonStyleButton 的
            // _InputPadding 把可点范围补到 48，胶囊本身只有 40 高。
            // 行高因此是 68 而非 Material 的 65 —— 撑宽的是这 48 的命中区，
            // 不是 minimumSize（去掉它只把胶囊从 44 收回 40）。
            ? FilledButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const .symmetric(horizontal: 15),
                foregroundColor: isFollow ? colorScheme.outline : null,
                backgroundColor: isFollow ? colorScheme.onInverseSurface : null,
              )
            : FilledButton.styleFrom(
                visualDensity: .compact,
                tapTargetSize: .shrinkWrap,
                padding: const .symmetric(horizontal: 15),
                foregroundColor: isFollow ? colorScheme.outline : null,
                backgroundColor: isFollow ? colorScheme.onInverseSurface : null,
              ),
        child: Text(
          '${isFollow ? '已' : ''}关注',
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
    return Material(
      type: .transparency,
      child: InkWell(
        onTap: () {
          if (onSelect != null) {
            onSelect!.call(
              UserModel(
                mid: item.mid,
                name: item.uname!,
                avatar: item.face!,
                selected: true,
              ),
            );
          } else {
            feedBack();
            Get.toNamed('/member?mid=${item.mid}');
          }
        },
        child: Padding(
          padding: const .symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PendantAvatar(
                size: 45,
                badgeSize: 14,
                item.face,
                officialType: item.officialVerify?.type,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  spacing: 3,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      item.uname!,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (item.sign != null)
                      Text(
                        item.sign!,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              ?followBtn,
            ],
          ),
        ),
      ),
    );
  }
}
